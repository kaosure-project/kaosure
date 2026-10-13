-- R27c (1/3): company registration and the business Kao ID.
-- The applicant must hold an active personal Kao ID and declare they are a director named in the company
-- certificate (หนังสือรับรองนิติบุคคล, issued within 6 months). A VAT certificate (ภ.พ.20) is optional.
-- Kao ID staff confirm the applicant against the certificate before approving; approval issues the business
-- Kao ID and makes the applicant the organization's owner. The company bank is verified separately (2/3).
-- The legacy shortcuts create_business_shop and issue_business_kao_id are no longer callable by members.

alter table public.business_registrations
  add column legal_name_en text,
  add column certificate_issued_on date,
  add column vat_document_id uuid references public.identity_documents(id) on delete set null,
  add column director_declared_at timestamptz,
  add column director_confirmed_by uuid references public.profiles(id) on delete restrict,
  add column director_confirmed_at timestamptz;
alter table public.business_registrations
  add constraint business_registrations_legal_name_en_r27c
  check (legal_name_en is null or (length(legal_name_en) between 2 and 200
                                   and legal_name_en ~ '^[A-Za-z0-9][A-Za-z0-9 .,&()''/-]*$'));

alter table public.organization_legal_profiles add column legal_name_en text;

-- ---------------------------------------------------------------------------
-- Field rules shared by create, update and submit
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.business_fields_r27c(
  p_business_type text, p_business_name text, p_registration_number text, p_business_category text,
  p_business_description text, p_legal_name_en text, p_certificate_issued_on date)
returns void
language plpgsql
stable
set search_path to ''
as $$
begin
  if coalesce(p_business_type, '') not in ('registered_business', 'organization') then
    raise exception 'invalid_business_type' using errcode = '22023';
  end if;
  if p_business_name is null or length(btrim(p_business_name)) not between 2 and 200
     or p_business_name ~ '[[:cntrl:]]' then
    raise exception 'invalid_business_name' using errcode = '22023';
  end if;
  if not kaoid_private.valid_thai_pid_r16b(btrim(coalesce(p_registration_number, ''))) then
    raise exception 'invalid_registration_number' using errcode = '22023';
  end if;
  if p_business_category is null or length(btrim(p_business_category)) not between 1 and 100
     or p_business_category ~ '[[:cntrl:]]' then
    raise exception 'invalid_business_category' using errcode = '22023';
  end if;
  if length(coalesce(p_business_description, '')) > 1000 then
    raise exception 'invalid_business_description' using errcode = '22023';
  end if;
  if nullif(btrim(coalesce(p_legal_name_en, '')), '') is not null
     and (length(btrim(p_legal_name_en)) not between 2 and 200
          or btrim(p_legal_name_en) !~ '^[A-Za-z0-9][A-Za-z0-9 .,&()''/-]*$') then
    raise exception 'invalid_legal_name_en' using errcode = '22023';
  end if;
  if p_certificate_issued_on is not null then
    if p_certificate_issued_on > current_date then
      raise exception 'invalid_certificate_date' using errcode = '22023';
    end if;
    if p_certificate_issued_on < (current_date - interval '6 months')::date then
      raise exception 'certificate_too_old' using errcode = '22023';
    end if;
  end if;
end $$;

-- Applicants act with their own verified identity.
create or replace function kaoid_private.business_applicant_r27c()
returns uuid
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  u uuid := auth.uid();
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_restricted' using errcode = '42501';
  end if;
  if not exists (select 1 from public.kao_id_identities k
                  where k.profile_id = u and k.identity_type = 'personal' and k.organization_id is null
                    and k.status = 'active') then
    raise exception 'KAO_ID_REQUIRED' using errcode = '42501';
  end if;
  return u;
end $$;

create or replace function kaoid_private.business_number_taken_r27c(p_number text, p_registration uuid)
returns boolean
language sql
stable security definer
set search_path to ''
as $$
  select exists (select 1 from public.organization_legal_profiles lp
                  where lp.registration_country = 'TH' and lp.registration_number = btrim(p_number)
                    and lp.registration_status = 'active')
      or exists (select 1 from public.business_registrations r
                  where r.registration_number = btrim(p_number) and r.id is distinct from p_registration
                    and r.status in ('submitted', 'under_review', 'requires_action'));
$$;

-- ---------------------------------------------------------------------------
-- Applicant RPCs
-- ---------------------------------------------------------------------------
drop function public.create_business_registration(text, text, text, text, text);
create function public.create_business_registration(
  p_business_type text, p_business_name text, p_registration_number text, p_business_category text,
  p_business_description text default null, p_legal_name_en text default null,
  p_certificate_issued_on date default null)
returns public.business_registrations
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := kaoid_private.business_applicant_r27c();
  v_row public.business_registrations;
  v_type text := coalesce(nullif(btrim(p_business_type), ''), 'registered_business');
begin
  perform kaoid_private.business_fields_r27c(v_type, p_business_name, p_registration_number, p_business_category,
                                            p_business_description, p_legal_name_en, p_certificate_issued_on);
  perform pg_advisory_xact_lock(hashtextextended('business-registration:' || u, 271));
  if exists (select 1 from public.business_registrations
              where user_id = u and status in ('draft', 'submitted', 'under_review', 'requires_action')) then
    raise exception 'ACTIVE_BUSINESS_REGISTRATION_EXISTS';
  end if;
  if kaoid_private.business_number_taken_r27c(p_registration_number, null) then
    raise exception 'Organization registration number already exists';
  end if;
  insert into public.business_registrations(user_id, business_type, business_name, registration_number,
                                            business_category, business_description, legal_name_en,
                                            certificate_issued_on)
  values (u, v_type, btrim(p_business_name), btrim(p_registration_number), btrim(p_business_category),
          nullif(btrim(coalesce(p_business_description, '')), ''), nullif(btrim(coalesce(p_legal_name_en, '')), ''),
          p_certificate_issued_on)
  returning * into v_row;
  return v_row;
end $$;

drop function public.update_business_registration(uuid, text, text, text, text, text);
create function public.update_business_registration(
  p_registration_id uuid, p_business_type text, p_business_name text, p_registration_number text,
  p_business_category text, p_business_description text default null, p_legal_name_en text default null,
  p_certificate_issued_on date default null)
returns public.business_registrations
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := kaoid_private.business_applicant_r27c();
  v_row public.business_registrations;
  v_type text := coalesce(nullif(btrim(p_business_type), ''), 'registered_business');
begin
  perform kaoid_private.business_fields_r27c(v_type, p_business_name, p_registration_number, p_business_category,
                                            p_business_description, p_legal_name_en, p_certificate_issued_on);
  if kaoid_private.business_number_taken_r27c(p_registration_number, p_registration_id) then
    raise exception 'Organization registration number already exists';
  end if;
  update public.business_registrations
     set business_type = v_type, business_name = btrim(p_business_name),
         registration_number = btrim(p_registration_number), business_category = btrim(p_business_category),
         business_description = nullif(btrim(coalesce(p_business_description, '')), ''),
         legal_name_en = nullif(btrim(coalesce(p_legal_name_en, '')), ''),
         certificate_issued_on = p_certificate_issued_on
   where id = p_registration_id and user_id = u and status = 'draft'
  returning * into v_row;
  if v_row.id is null then raise exception 'DRAFT_NOT_FOUND_OR_NOT_EDITABLE'; end if;
  return v_row;
end $$;

-- p_kind: 'certificate' (หนังสือรับรอง, required) or 'vat' (ภ.พ.20, optional).
create or replace function kaoid_private.attach_business_document_r27c(
  p_registration_id uuid, p_kind text, p_document_id uuid, p_path text, p_file_name text)
returns public.business_registrations
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := kaoid_private.business_applicant_r27c();
  r public.business_registrations%rowtype;
  d public.identity_documents%rowtype;
  o storage.objects%rowtype;
  v_type text := case p_kind when 'certificate' then 'company_registration' when 'vat' then 'vat_registration' end;
  v_old uuid;
begin
  if v_type is null then raise exception 'invalid_document' using errcode = '22023'; end if;
  if p_registration_id is null or p_document_id is null or p_path is null
     or p_path !~ ('^' || u::text || '/business-registration/' || p_registration_id::text
                   || '/' || p_document_id::text || '\.(jpg|png|pdf)$') then
    raise exception 'invalid_document_paths' using errcode = '22023';
  end if;
  if p_file_name is null or length(btrim(p_file_name)) not between 1 and 200 or p_file_name ~ '[[:cntrl:]]' then
    raise exception 'invalid_document' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(u::text, 721));
  select * into r from public.business_registrations where id = p_registration_id and user_id = u for update;
  if not found or r.status <> 'draft' then
    raise exception 'DRAFT_NOT_FOUND_OR_NOT_EDITABLE' using errcode = '42501';
  end if;

  select * into d from public.identity_documents where id = p_document_id;
  if found then
    if d.owner_id <> u or d.document_type <> v_type or d.file_path is distinct from p_path
       or d.deleted_at is not null then
      raise exception 'document_conflict' using errcode = '42501';
    end if;
  else
    if not exists (select 1 from storage.buckets where id = 'identity-documents' and public = false) then
      raise exception 'private_storage_required' using errcode = '55000';
    end if;
    select * into o from storage.objects where bucket_id = 'identity-documents' and name = p_path for update;
    if not found or o.owner_id is distinct from u::text
       or coalesce((o.metadata->>'size')::bigint, 0) not between 1 and 10485760
       or coalesce(o.metadata->>'mimetype', '') not in ('image/jpeg', 'image/png', 'application/pdf') then
      raise exception 'invalid_uploaded_file' using errcode = '22023';
    end if;
    insert into public.identity_documents(id, owner_id, document_type, document_number, full_name, country_code,
                                          status, file_path, file_name, file_size, mime_type, uploaded_at,
                                          issued_date)
    values (p_document_id, u, v_type, r.registration_number, r.business_name, 'TH', 'draft', p_path,
            btrim(p_file_name), (o.metadata->>'size')::bigint, o.metadata->>'mimetype', now(),
            case when p_kind = 'certificate' then r.certificate_issued_on end);
    insert into public.document_files(document_id, file_path, file_name, mime_type, file_size)
    values (p_document_id, p_path, btrim(p_file_name), o.metadata->>'mimetype', (o.metadata->>'size')::bigint);
  end if;

  v_old := case when p_kind = 'certificate' then r.document_id else r.vat_document_id end;
  update public.identity_documents
     set deleted_at = now()
   where id = v_old and id <> p_document_id and owner_id = u and document_type = v_type
     and status = 'draft' and deleted_at is null;

  if p_kind = 'certificate' then
    update public.business_registrations set document_id = p_document_id, document_status = 'uploaded'
     where id = r.id returning * into r;
  else
    update public.business_registrations set vat_document_id = p_document_id where id = r.id returning * into r;
  end if;
  return r;
end $$;

create or replace function kaoid_private.remove_business_vat_document_r27c(p_registration_id uuid)
returns public.business_registrations
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := kaoid_private.business_applicant_r27c();
  r public.business_registrations%rowtype;
begin
  select * into r from public.business_registrations where id = p_registration_id and user_id = u for update;
  if not found or r.status <> 'draft' then
    raise exception 'DRAFT_NOT_FOUND_OR_NOT_EDITABLE' using errcode = '42501';
  end if;
  update public.identity_documents set deleted_at = now()
   where id = r.vat_document_id and owner_id = u and status = 'draft' and deleted_at is null;
  update public.business_registrations set vat_document_id = null where id = r.id returning * into r;
  return r;
end $$;

drop function public.submit_business_registration(uuid);
create function public.submit_business_registration(p_registration_id uuid, p_director_declared boolean default false)
returns public.business_registrations
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := kaoid_private.business_applicant_r27c();
  v_row public.business_registrations;
  v_org_id uuid;
  v_recipient uuid;
begin
  select * into v_row from public.business_registrations
   where id = p_registration_id and user_id = u
   for update;
  if v_row.id is null then raise exception 'REGISTRATION_NOT_FOUND'; end if;
  if v_row.status <> 'draft' then raise exception 'REGISTRATION_NOT_DRAFT'; end if;
  if p_director_declared is not true then raise exception 'DIRECTOR_DECLARATION_REQUIRED'; end if;
  perform kaoid_private.business_fields_r27c(v_row.business_type, v_row.business_name, v_row.registration_number,
                                            v_row.business_category, v_row.business_description,
                                            v_row.legal_name_en, v_row.certificate_issued_on);
  if v_row.certificate_issued_on is null then raise exception 'CERTIFICATE_DATE_REQUIRED'; end if;
  if v_row.document_id is null or not exists (
       select 1 from public.identity_documents d
        where d.id = v_row.document_id and d.owner_id = u
          and d.document_type = 'company_registration' and d.deleted_at is null) then
    raise exception 'BUSINESS_DOCUMENT_REQUIRED';
  end if;
  if v_row.vat_document_id is not null and not exists (
       select 1 from public.identity_documents d
        where d.id = v_row.vat_document_id and d.owner_id = u
          and d.document_type = 'vat_registration' and d.deleted_at is null) then
    raise exception 'BUSINESS_DOCUMENT_REQUIRED';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('business-number:' || v_row.registration_number, 272));
  if kaoid_private.business_number_taken_r27c(v_row.registration_number, v_row.id) then
    raise exception 'Organization registration number already exists';
  end if;

  begin
    insert into public.organizations(name, organization_type, status)
    values (v_row.business_name,
            case when v_row.business_type = 'registered_business' then 'company' else 'organization' end, 'active')
    returning id into v_org_id;
    insert into public.organization_legal_profiles(organization_id, registration_number, legal_name, legal_name_en,
                                                   organization_type, registration_country, registration_status,
                                                   verification_status)
    values (v_org_id, v_row.registration_number, v_row.business_name, v_row.legal_name_en,
            case when v_row.business_type = 'registered_business' then 'company' else 'organization' end,
            'TH', 'active', 'pending');
  exception when unique_violation then
    raise exception 'Organization registration number already exists';
  end;
  insert into public.organization_members(organization_id, profile_id, role, status, starts_at)
  values (v_org_id, u, 'owner', 'active', now());
  insert into public.organization_verifications(organization_id, status) values (v_org_id, 'pending');

  -- Freeze the evidence: draft documents can still be replaced or deleted by the owner.
  update public.identity_documents set status = 'pending_review'
   where id in (v_row.document_id, v_row.vat_document_id) and owner_id = u and status = 'draft';

  update public.business_registrations
     set organization_id = v_org_id, status = 'under_review', submitted_at = now(), director_declared_at = now()
   where id = v_row.id
  returning * into v_row;

  for v_recipient in select * from kaoid_private.review_recipients_r14b(u, null) loop
    perform kaoid_private.emit_notice_r10a(v_recipient, 'business-new:' || v_row.id || ':' || v_recipient,
      'business_review_new', v_row.id);
  end loop;
  return v_row;
end $$;

alter function public.get_business_registration(uuid) set search_path to '';
alter function public.get_current_business_registration() set search_path to '';
alter function public.cancel_business_registration(uuid) set search_path to '';
alter function public.refresh_business_registration_status(uuid) set search_path to '';

-- ---------------------------------------------------------------------------
-- Review
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.business_review_fingerprint_r15b(p_id uuid)
returns text
language sql
stable security definer
set search_path to ''
as $$
  select encode(sha256(convert_to(jsonb_build_object(
    'registration', (select to_jsonb(r) - 'updated_at' from public.business_registrations r where r.id = p_id),
    'documents', (select jsonb_agg(to_jsonb(d) order by d.id) from public.identity_documents d
                    join public.business_registrations r on d.id in (r.document_id, r.vat_document_id)
                   where r.id = p_id),
    'files', (select jsonb_agg(to_jsonb(f) order by f.id) from public.document_files f
                join public.business_registrations r on f.document_id in (r.document_id, r.vat_document_id)
               where r.id = p_id),
    'objects', (select jsonb_agg(jsonb_build_object('id', o.id, 'name', o.name, 'updated_at', o.updated_at,
                                                    'metadata', o.metadata) order by o.name)
                  from storage.objects o
                 where o.bucket_id = 'identity-documents'
                   and o.name in (select f.file_path from public.document_files f
                                   join public.business_registrations r
                                     on f.document_id in (r.document_id, r.vat_document_id)
                                  where r.id = p_id)),
    'applicant', (select to_jsonb(k) - 'updated_at' from public.business_registrations r
                    join public.kao_id_identities k on k.profile_id = r.user_id and k.identity_type = 'personal'
                   where r.id = p_id)
  )::text, 'UTF8')), 'hex');
$$;

create or replace function kaoid_private.business_review_rows_r15b(p_target uuid default null)
returns jsonb
language plpgsql
stable security definer
set search_path to ''
as $$
begin
  if not kaoid_private.can_review_r7c() then
    raise exception 'reviewer_required' using errcode = '42501';
  end if;
  return (
    select coalesce(jsonb_agg(row_data order by submitted_at, id), '[]'::jsonb)
      from (
        select r.id, r.submitted_at, jsonb_build_object(
          'id', r.id,
          'status', r.status,
          'submitted_at', r.submitted_at,
          'business_type', r.business_type,
          'business_name', r.business_name,
          'legal_name_en', r.legal_name_en,
          'registration_number', r.registration_number,
          'registration_number_valid', kaoid_private.valid_thai_pid_r16b(r.registration_number),
          'registration_number_taken', exists (select 1 from public.organization_legal_profiles lp
                                                where lp.registration_country = 'TH'
                                                  and lp.registration_number = r.registration_number
                                                  and lp.registration_status = 'active'
                                                  and lp.organization_id is distinct from r.organization_id),
          'business_category', r.business_category,
          'business_description', r.business_description,
          'certificate_issued_on', r.certificate_issued_on,
          'certificate_fresh', r.certificate_issued_on >= (current_date - interval '6 months')::date,
          'document_name', d.file_name,
          'document_mime', d.mime_type,
          'paths', (select coalesce(jsonb_agg(f.file_path order by f.file_path), '[]'::jsonb)
                      from public.document_files f where f.document_id = d.id),
          'vat_document_name', v.file_name,
          'vat_document_mime', v.mime_type,
          'vat_paths', (select coalesce(jsonb_agg(f.file_path order by f.file_path), '[]'::jsonb)
                          from public.document_files f where f.document_id = v.id),
          'owner_kao_id', (select k.kao_id from public.kao_id_identities k
                            where k.profile_id = r.user_id and k.identity_type = 'personal' and k.status = 'active'),
          'owner_name', kaoid_private.business_owner_name_r15b(r.user_id),
          'director_declared', r.director_declared_at is not null,
          'dual_review', (select dual_review from kaoid_private.security_policy_r14a where id),
          'first_reviewer', ar.requested_by,
          'first_decision', h.metadata -> 'approve',
          'first_reason', ar.reason
        ) as row_data
          from public.business_registrations r
          left join public.identity_documents d
            on d.id = r.document_id and d.owner_id = r.user_id
           and d.document_type = 'company_registration' and d.deleted_at is null
          left join public.identity_documents v
            on v.id = r.vat_document_id and v.owner_id = r.user_id
           and v.document_type = 'vat_registration' and v.deleted_at is null
          left join public.approval_requests ar
            on ar.resource = 'kaoid_business_review' and ar.resource_id = r.id
           and ar.status = 'pending' and ar.expires_at > now()
          left join public.approval_histories h
            on h.approval_request_id = ar.id and h.event = 'request_created'
         where r.status in ('submitted', 'under_review')
           and r.user_id <> auth.uid()
           and (p_target is null or r.id = p_target)
           -- guard_closed_target_r10d blocks any decision write for a closed applicant.
           and exists (select 1 from public.profiles p where p.id = r.user_id and p.account_status <> 'closed')
         order by r.submitted_at, r.id
         limit 50
      ) q
  );
end $$;

create or replace function kaoid_private.can_read_business_evidence_r15b(p_path text)
returns boolean
language sql
stable security definer
set search_path to ''
as $$
  select kaoid_private.can_review_r7c() and exists(
    select 1
      from public.business_registrations r
      join public.identity_documents d on d.id in (r.document_id, r.vat_document_id)
      join public.document_files f on f.document_id = d.id
     where f.file_path = p_path
       and r.status in ('submitted', 'under_review')
       and r.user_id <> auth.uid()
       and d.owner_id = r.user_id
       and d.document_type in ('company_registration', 'vat_registration')
       and d.deleted_at is null);
$$;

-- p_director_confirmed: the reviewer checked that the applicant's verified name appears as a director
-- in the company certificate.
create or replace function kaoid_private.business_review_decide_r27c(
  p_expected_user uuid, p_registration uuid, p_approve boolean, p_reason text, p_director_confirmed boolean)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  reviewer uuid := auth.uid();
  reason text := nullif(btrim(coalesce(p_reason, '')), '');
  outcome text := case when p_approve then 'approved' else 'rejected' end;
  r public.business_registrations%rowtype;
  d public.identity_documents%rowtype;
  v public.identity_documents%rowtype;
  business_kao_id text;
begin
  if reviewer is null or p_expected_user is distinct from reviewer or not kaoid_private.account_active_r9f() then
    raise exception 'session_required' using errcode = '42501';
  end if;
  if not kaoid_private.can_review_r7c() then
    raise exception 'reviewer_required' using errcode = '42501';
  end if;
  perform kaoid_private.require_fresh_mfa_r14a();
  if p_registration is null or p_approve is null or length(coalesce(reason, '')) > 1000
     or (not p_approve and length(coalesce(reason, '')) < 3) then
    raise exception 'invalid_decision' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('business-review:' || p_registration, 151));
  select * into r from public.business_registrations where id = p_registration for update;
  if not found or r.user_id = reviewer then
    raise exception 'request_not_available' using errcode = '42501';
  end if;
  if r.status in ('approved', 'rejected') then
    if r.status = outcome then return jsonb_build_object('status', r.status); end if;
    raise exception 'request_already_reviewed' using errcode = '42501';
  end if;
  if r.status not in ('submitted', 'under_review') or r.organization_id is null then
    raise exception 'request_not_available' using errcode = '42501';
  end if;

  select * into d from public.identity_documents
   where id = r.document_id and owner_id = r.user_id and document_type = 'company_registration' and deleted_at is null;
  select * into v from public.identity_documents
   where id = r.vat_document_id and owner_id = r.user_id and document_type = 'vat_registration' and deleted_at is null;

  if p_approve then
    if p_director_confirmed is not true then
      raise exception 'director_confirmation_required' using errcode = '22023';
    end if;
    if d.id is null or d.status <> 'pending_review' or not exists (
         select 1 from public.document_files f
           join storage.objects o on o.bucket_id = 'identity-documents' and o.name = f.file_path
          where f.document_id = d.id) then
      raise exception 'document_files_missing' using errcode = '22023';
    end if;
    if r.vat_document_id is not null and (v.id is null or v.status <> 'pending_review' or not exists (
         select 1 from public.document_files f
           join storage.objects o on o.bucket_id = 'identity-documents' and o.name = f.file_path
          where f.document_id = v.id)) then
      raise exception 'document_files_missing' using errcode = '22023';
    end if;
    if r.certificate_issued_on is null or r.certificate_issued_on < (current_date - interval '6 months')::date then
      raise exception 'certificate_too_old' using errcode = '22023';
    end if;
    if not kaoid_private.valid_thai_pid_r16b(r.registration_number) then
      raise exception 'invalid_registration_number' using errcode = '22023';
    end if;
    if not exists (select 1 from public.profiles p
                    where p.id = r.user_id and p.account_status = 'active' and p.deleted_at is null) then
      raise exception 'inactive_account' using errcode = '42501';
    end if;
    if not exists (select 1 from public.kao_id_identities k
                    where k.profile_id = r.user_id and k.identity_type = 'personal' and k.status = 'active') then
      raise exception 'owner_kao_id_required' using errcode = '42501';
    end if;
    if not exists (select 1 from public.organization_members m
                    where m.organization_id = r.organization_id and m.profile_id = r.user_id
                      and m.role = 'owner' and m.status = 'active') then
      raise exception 'request_not_available' using errcode = '42501';
    end if;
  end if;

  if not kaoid_private.business_review_vote_r15b(r.id, p_approve, reason) then
    return jsonb_build_object('status', 'awaiting_second');
  end if;

  if p_approve then
    update public.identity_documents
       set status = 'approved', verified_by = reviewer, verified_at = now(), rejected_reason = null
     where id in (d.id, v.id);
    update public.organization_verifications
       set status = 'approved', legal_name_verified = true, registration_verified = true,
           authorized_person_verified = true, identity_score = 100,
           last_reviewed_by = reviewer, last_verified_at = now(), rejected_reason = null
     where organization_id = r.organization_id;
    update public.organization_legal_profiles
       set verification_status = 'approved', verified_by = reviewer, verified_at = now()
     where organization_id = r.organization_id;

    select kao_id into business_kao_id from public.kao_id_identities
     where organization_id = r.organization_id and identity_type = 'business';
    if business_kao_id is null then
      business_kao_id := public.generate_kao_id();
      insert into public.kao_id_identities(profile_id, organization_id, identity_type, kao_id, status, issued_at)
      values (null, r.organization_id, 'business', business_kao_id, 'active', now());
    end if;

    update public.business_registrations
       set status = 'approved', document_status = 'verified', review_reason = reason, reviewed_at = now(),
           director_confirmed_by = reviewer, director_confirmed_at = now()
     where id = r.id;
  else
    update public.identity_documents
       set status = 'rejected', verified_by = reviewer, verified_at = now(), rejected_reason = reason
     where id in (d.id, v.id);
    update public.organization_verifications
       set status = 'rejected', last_reviewed_by = reviewer, rejected_reason = reason
     where organization_id = r.organization_id;
    update public.organization_legal_profiles
       set verification_status = 'rejected', registration_status = 'inactive'
     where organization_id = r.organization_id;
    update public.organization_members
       set status = 'inactive', ends_at = greatest(now(), starts_at + interval '1 second')
     where organization_id = r.organization_id and status = 'active';
    update public.organizations set status = 'inactive' where id = r.organization_id;

    update public.business_registrations
       set status = 'rejected', document_status = 'rejected', review_reason = reason, reviewed_at = now()
     where id = r.id;
  end if;

  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (reviewer, 'kyc.business.' || case when p_approve then 'approve' else 'reject' end,
          'business_registrations', r.id, reason);

  perform kaoid_private.emit_notice_r10a(r.user_id, 'business:' || r.id || ':' || outcome, 'business_' || outcome, r.id);

  return jsonb_build_object('status', outcome, 'business_kao_id', business_kao_id);
end $$;

create or replace function public.business_review_decide_r27c(
  p_expected_user uuid, p_registration uuid, p_approve boolean, p_reason text default null,
  p_director_confirmed boolean default false)
returns jsonb
language sql
set search_path to ''
as $$
  select kaoid_private.business_review_decide_r27c(p_expected_user, p_registration, p_approve, p_reason,
                                                   p_director_confirmed);
$$;

create or replace function public.attach_business_document_r27c(
  p_registration_id uuid, p_kind text, p_document_id uuid, p_path text, p_file_name text)
returns public.business_registrations
language sql
set search_path to ''
as $$ select kaoid_private.attach_business_document_r27c(p_registration_id, p_kind, p_document_id, p_path, p_file_name); $$;

create or replace function public.remove_business_vat_document_r27c(p_registration_id uuid)
returns public.business_registrations
language sql
set search_path to ''
as $$ select kaoid_private.remove_business_vat_document_r27c(p_registration_id); $$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
revoke all on function kaoid_private.business_fields_r27c(text, text, text, text, text, text, date),
  kaoid_private.business_applicant_r27c(), kaoid_private.business_number_taken_r27c(text, uuid)
  from public, anon, authenticated;

revoke all on function kaoid_private.attach_business_document_r27c(uuid, text, uuid, text, text),
  kaoid_private.remove_business_vat_document_r27c(uuid),
  kaoid_private.business_review_decide_r27c(uuid, uuid, boolean, text, boolean),
  public.attach_business_document_r27c(uuid, text, uuid, text, text),
  public.remove_business_vat_document_r27c(uuid),
  public.business_review_decide_r27c(uuid, uuid, boolean, text, boolean),
  public.create_business_registration(text, text, text, text, text, text, date),
  public.update_business_registration(uuid, text, text, text, text, text, text, date),
  public.submit_business_registration(uuid, boolean)
  from public, anon;
grant execute on function kaoid_private.attach_business_document_r27c(uuid, text, uuid, text, text),
  kaoid_private.remove_business_vat_document_r27c(uuid),
  kaoid_private.business_review_decide_r27c(uuid, uuid, boolean, text, boolean),
  public.attach_business_document_r27c(uuid, text, uuid, text, text),
  public.remove_business_vat_document_r27c(uuid),
  public.business_review_decide_r27c(uuid, uuid, boolean, text, boolean),
  public.create_business_registration(text, text, text, text, text, text, date),
  public.update_business_registration(uuid, text, text, text, text, text, text, date),
  public.submit_business_registration(uuid, boolean)
  to authenticated;

-- Superseded paths: the r15a attach skipped the Kao ID check, the r15b decision required the owner's personal
-- bank and had no director confirmation, and the legacy RPCs let any member mint a business Kao ID or shop.
revoke execute on function kaoid_private.attach_business_document_r15a(uuid, uuid, text, text),
  public.attach_business_document_r15a(uuid, uuid, text, text),
  kaoid_private.business_review_decide_r15b(uuid, uuid, boolean, text),
  public.business_review_decide_r15b(uuid, uuid, boolean, text),
  public.create_business_shop(uuid, text, text, text),
  public.issue_business_kao_id(uuid)
  from public, anon, authenticated;
