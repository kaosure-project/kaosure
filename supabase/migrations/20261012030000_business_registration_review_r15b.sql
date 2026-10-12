-- Business registration review queue (r15b)
-- 1. Reviewers (Owner / kyc_officer, fresh MFA when required, two-person rule when enabled) approve or
--    reject submitted business registrations. Approval issues the Business Kao ID in the same transaction.
-- 2. Reviewers can read the submitted business document while the registration is under review.
-- 3. A rejected registration releases its registration number so the real owner can resubmit.
-- 4. Organization bootstrap functions are only reachable through submit_business_registration.

alter table public.business_registrations
  add column if not exists review_reason text,
  add column if not exists reviewed_at timestamptz;

alter table public.business_registrations
  drop constraint if exists business_registrations_review_reason_check;
alter table public.business_registrations
  add constraint business_registrations_review_reason_check
  check (review_reason is null or length(review_reason) <= 1000);

alter table public.organization_legal_profiles
  drop constraint if exists uq_organization_legal_profile_registration;
create unique index if not exists uq_organization_legal_profile_registration_active
  on public.organization_legal_profiles (registration_country, registration_number)
  where registration_status = 'active';

create unique index if not exists kaoid_pending_business_review_r15b
  on public.approval_requests (resource, resource_id)
  where resource = 'kaoid_business_review' and status = 'pending';

create or replace function public.register_organization(
  p_name text,
  p_legal_name text,
  p_registration_number text,
  p_organization_type text default 'company',
  p_registration_country text default 'TH'
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_profile_id uuid := auth.uid();
  v_organization_id uuid;
begin
  if v_profile_id is null then raise exception 'Authentication required'; end if;
  if nullif(trim(p_name), '') is null then raise exception 'Organization name is required'; end if;
  if nullif(trim(p_legal_name), '') is null then raise exception 'Legal name is required'; end if;
  if nullif(trim(p_registration_number), '') is null then raise exception 'Registration number is required'; end if;
  if nullif(trim(p_registration_country), '') is null then raise exception 'Registration country is required'; end if;
  if not exists (select 1 from public.profiles where id = v_profile_id and account_status = 'active') then
    raise exception 'Active profile not found';
  end if;

  -- Rejected registrations are inactive and must not keep the number reserved.
  if exists (
    select 1 from public.organization_legal_profiles
     where registration_country = upper(trim(p_registration_country))
       and registration_number = trim(p_registration_number)
       and registration_status = 'active'
  ) then
    raise exception 'Organization registration number already exists';
  end if;

  insert into public.organizations (name, organization_type, status)
  values (trim(p_name), trim(p_organization_type), 'active')
  returning id into v_organization_id;

  insert into public.organization_legal_profiles (
    organization_id, registration_number, legal_name, organization_type,
    registration_country, registration_status, verification_status)
  values (
    v_organization_id, trim(p_registration_number), trim(p_legal_name), trim(p_organization_type),
    upper(trim(p_registration_country)), 'active', 'pending');

  insert into public.organization_members (organization_id, profile_id, role, status, starts_at)
  values (v_organization_id, v_profile_id, 'authorized_person', 'active', now());

  -- The Business Kao ID is issued by kaoid_private.business_review_decide_r15b after review.
  return v_organization_id;
exception when unique_violation then
  raise exception 'Organization registration number already exists';
end;
$$;

revoke all on function public.register_organization(text, text, text, text, text) from public, anon, authenticated;
revoke all on function public.initialize_organization_verification(uuid) from public, anon, authenticated;

create or replace function kaoid_private.business_owner_name_r15b(p_owner uuid)
returns text
language sql
stable
security definer
set search_path to ''
as $$
  select d.full_name
    from public.identity_documents d
    join public.verification_requests r on r.document_id = d.id
   where d.owner_id = p_owner
     and d.document_type in ('thai_national_id', 'passport', 'residence_card')
     and d.status = 'approved' and d.deleted_at is null
     and (d.expiry_date is null or d.expiry_date >= current_date)
     and r.status = 'approved'
   order by d.verified_at desc nulls last
   limit 1;
$$;

-- Same approval rule as submit_business_registration and kaoid_private.list_banks_r8c.
create or replace function kaoid_private.business_owner_bank_r15b(p_owner uuid)
returns table (bank_account_id uuid, bank_name text, account_last4 text, account_name text)
language sql
stable
security definer
set search_path to ''
as $$
  select b.id, b.bank_name::text, right(b.account_number::text, 4), b.account_name::text
    from public.bank_accounts b
    join public.financial_verifications f on f.bank_account_id = b.id
   where b.profile_id = p_owner and b.organization_id is null
     and b.is_active and b.deleted_at is null
     and b.is_verified and b.status = 'verified'
     and f.status = 'approved' and f.name_match_status = 'matched'
   order by f.created_at desc
   limit 1;
$$;

create or replace function kaoid_private.business_review_fingerprint_r15b(p_id uuid)
returns text
language sql
stable
security definer
set search_path to ''
as $$
  select encode(sha256(convert_to(jsonb_build_object(
    'registration', (select to_jsonb(r) - 'updated_at' from public.business_registrations r where r.id = p_id),
    'document', (select to_jsonb(d) from public.identity_documents d
                   join public.business_registrations r on r.document_id = d.id where r.id = p_id),
    'files', (select jsonb_agg(to_jsonb(f) order by f.id) from public.document_files f
                join public.business_registrations r on r.document_id = f.document_id where r.id = p_id),
    'objects', (select jsonb_agg(jsonb_build_object('id', o.id, 'name', o.name, 'updated_at', o.updated_at,
                  'metadata', o.metadata) order by o.name)
                  from storage.objects o
                 where o.bucket_id = 'identity-documents'
                   and o.name in (select f.file_path from public.document_files f
                                   join public.business_registrations r on r.document_id = f.document_id
                                  where r.id = p_id)),
    'bank', (select to_jsonb(b) from public.business_registrations r
               cross join lateral kaoid_private.business_owner_bank_r15b(r.user_id) b where r.id = p_id)
  )::text, 'UTF8')), 'hex');
$$;

-- p_target null returns the whole queue; otherwise only that registration if it is still reviewable.
create or replace function kaoid_private.business_review_rows_r15b(p_target uuid default null)
returns jsonb
language plpgsql
stable
security definer
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
          'registration_number', r.registration_number,
          'business_category', r.business_category,
          'business_description', r.business_description,
          'document_name', d.file_name,
          'document_mime', d.mime_type,
          'paths', (select coalesce(jsonb_agg(f.file_path order by f.file_path), '[]'::jsonb)
                      from public.document_files f where f.document_id = d.id),
          'owner_kao_id', (select k.kao_id from public.kao_id_identities k
                            where k.profile_id = r.user_id and k.identity_type = 'personal' and k.status = 'active'),
          'owner_name', kaoid_private.business_owner_name_r15b(r.user_id),
          'bank_name', bank.bank_name,
          'bank_account_last4', bank.account_last4,
          'bank_account_name', bank.account_name,
          'dual_review', (select dual_review from kaoid_private.security_policy_r14a where id),
          'first_reviewer', ar.requested_by,
          'first_decision', h.metadata -> 'approve',
          'first_reason', ar.reason
        ) as row_data
          from public.business_registrations r
          left join public.identity_documents d
            on d.id = r.document_id and d.owner_id = r.user_id
           and d.document_type = 'company_registration' and d.deleted_at is null
          left join lateral kaoid_private.business_owner_bank_r15b(r.user_id) bank on true
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
end;
$$;

create or replace function kaoid_private.business_review_queue_r15b()
returns jsonb
language sql
stable
security definer
set search_path to ''
as $$ select kaoid_private.business_review_rows_r15b(null); $$;

-- Two-person rule for business reviews; mirrors kaoid_private.review_vote_r14a.
-- Returns true when the caller's decision is final.
create or replace function kaoid_private.business_review_vote_r15b(p_id uuid, p_approve boolean, p_reason text)
returns boolean
language plpgsql
security definer
set search_path to ''
as $$
declare
  ar public.approval_requests%rowtype;
  meta jsonb;
  rid uuid;
  sid uuid;
  hid uuid;
  applicant uuid;
  recipient uuid;
  fingerprint text;
  first_ok boolean;
begin
  if not (select dual_review from kaoid_private.security_policy_r14a where id) then return true; end if;
  select user_id into applicant from public.business_registrations where id = p_id;
  fingerprint := kaoid_private.business_review_fingerprint_r15b(p_id);

  select * into ar from public.approval_requests
   where resource = 'kaoid_business_review' and resource_id = p_id and status = 'pending'
   for update;
  if found then
    select metadata into meta from public.approval_histories
     where approval_request_id = ar.id and event = 'request_created'
     order by created_at, id limit 1;
    select exists(
      select 1 from public.profiles p
       where p.id = ar.requested_by and p.account_status = 'active' and p.deleted_at is null
         and exists(select 1 from auth.mfa_factors f where f.user_id = p.id and f.status::text = 'verified')
         and (exists(select 1 from public.company_owners o where o.profile_id = p.id)
              or exists(select 1 from public.admin_assignments a join public.admin_roles r on r.id = a.role_id
                         where a.profile_id = p.id and a.is_active and r.is_active and r.code = 'kyc_officer'
                           and a.starts_at <= now() and (a.expires_at is null or a.expires_at > now())))
    ) into first_ok;
    if ar.expires_at <= now() or meta ->> 'fingerprint' is distinct from fingerprint or not first_ok then
      update public.approval_requests set status = 'expired', completed_at = now(), updated_at = now() where id = ar.id;
      insert into public.approval_histories(approval_request_id, actor_profile_id, event, previous_status, current_status, comment)
      values (ar.id, auth.uid(), 'expired', 'pending', 'expired', 'Evidence, reviewer authority or time changed');
    elsif ar.requested_by = auth.uid() then
      return false;
    elsif (meta ->> 'approve')::boolean is distinct from p_approve then
      update public.approval_requests set status = 'rejected', completed_at = now(), updated_at = now() where id = ar.id;
      insert into public.approval_histories(approval_request_id, actor_profile_id, event, previous_status, current_status, comment)
      values (ar.id, auth.uid(), 'rejected', 'pending', 'rejected', btrim(p_reason))
      returning id into hid;
      for recipient in select * from kaoid_private.review_recipients_r14b(applicant, null) loop
        perform kaoid_private.emit_notice_r10a(recipient, 'business-vote:' || hid || ':' || recipient, 'business_review_restart', p_id);
      end loop;
      return false;
    else
      insert into public.approval_steps(approval_request_id, role_id, step_order, status, approved_by, approved_at, comment)
      values (ar.id, (select id from public.admin_roles where code = 'kyc_officer'), 2, 'approved', auth.uid(), now(), p_reason)
      returning id into sid;
      update public.approval_requests set status = 'approved', completed_at = now(), updated_at = now() where id = ar.id;
      insert into public.approval_histories(approval_request_id, approval_step_id, actor_profile_id, event, previous_status, current_status, comment)
      values (ar.id, sid, auth.uid(), 'completed', 'pending', 'approved', p_reason);
      return true;
    end if;
  end if;

  insert into public.approval_requests(policy_id, requested_by, resource, resource_id, status, reason, expires_at)
  select id, auth.uid(), 'kaoid_business_review', p_id, 'pending', p_reason, now() + interval '24 hours'
    from public.approval_policies where code = 'kaoid_two_person_r14a'
  returning id into rid;
  if rid is null then raise exception 'approval_policy_missing' using errcode = '55000'; end if;
  insert into public.approval_steps(approval_request_id, role_id, step_order, status, approved_by, approved_at, comment)
  values (rid, (select id from public.admin_roles where code = 'kyc_officer'), 1, 'approved', auth.uid(), now(), p_reason)
  returning id into sid;
  insert into public.approval_histories(approval_request_id, approval_step_id, actor_profile_id, event, current_status, metadata)
  values (rid, sid, auth.uid(), 'request_created', 'pending',
          jsonb_build_object('approve', p_approve, 'fingerprint', fingerprint, 'policy_version', 'r15b'))
  returning id into hid;
  for recipient in select * from kaoid_private.review_recipients_r14b(applicant, auth.uid()) loop
    perform kaoid_private.emit_notice_r10a(recipient, 'business-vote:' || hid || ':' || recipient, 'business_review_second', p_id);
  end loop;
  return false;
end;
$$;

create or replace function kaoid_private.business_review_decide_r15b(
  p_expected_user uuid,
  p_registration uuid,
  p_approve boolean,
  p_reason text
)
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
   where id = r.document_id and owner_id = r.user_id
     and document_type = 'company_registration' and deleted_at is null;

  if p_approve then
    if d.id is null or d.status <> 'pending_review' or not exists (
         select 1 from public.document_files f
           join storage.objects o on o.bucket_id = 'identity-documents' and o.name = f.file_path
          where f.document_id = d.id) then
      raise exception 'document_files_missing' using errcode = '22023';
    end if;
    if not exists (select 1 from public.profiles p
                    where p.id = r.user_id and p.account_status = 'active' and p.deleted_at is null) then
      raise exception 'inactive_account' using errcode = '42501';
    end if;
    if not exists (select 1 from public.kao_id_identities k
                    where k.profile_id = r.user_id and k.identity_type = 'personal' and k.status = 'active') then
      raise exception 'owner_kao_id_required' using errcode = '42501';
    end if;
    if not exists (select 1 from kaoid_private.business_owner_bank_r15b(r.user_id)) then
      raise exception 'owner_bank_required' using errcode = '42501';
    end if;
  end if;

  if not kaoid_private.business_review_vote_r15b(r.id, p_approve, reason) then
    return jsonb_build_object('status', 'awaiting_second');
  end if;

  if p_approve then
    update public.identity_documents
       set status = 'approved', verified_by = reviewer, verified_at = now(), rejected_reason = null
     where id = d.id;
    update public.organization_verifications
       set status = 'approved', legal_name_verified = true, registration_verified = true,
           authorized_person_verified = true, bank_verified = true, identity_score = 100,
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
       set status = 'approved', document_status = 'verified', review_reason = reason, reviewed_at = now()
     where id = r.id;
  else
    if d.id is not null then
      update public.identity_documents
         set status = 'rejected', verified_by = reviewer, verified_at = now(), rejected_reason = reason
       where id = d.id;
    end if;
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

  perform kaoid_private.emit_notice_r10a(r.user_id, 'business:' || r.id || ':' || outcome,
    'business_' || outcome, r.id);

  return jsonb_build_object('status', outcome);
end;
$$;

create or replace function public.business_review_queue_r15b()
returns jsonb
language sql
stable
set search_path to ''
as $$ select kaoid_private.business_review_queue_r15b(); $$;

create or replace function public.business_review_decide_r15b(
  p_expected_user uuid,
  p_registration uuid,
  p_approve boolean,
  p_reason text default null
)
returns jsonb
language sql
set search_path to ''
as $$ select kaoid_private.business_review_decide_r15b(p_expected_user, p_registration, p_approve, p_reason); $$;

create or replace function kaoid_private.can_read_business_evidence_r15b(p_path text)
returns boolean
language sql
stable
security definer
set search_path to ''
as $$
  select kaoid_private.can_review_r7c() and exists(
    select 1
      from public.business_registrations r
      join public.identity_documents d on d.id = r.document_id
      join public.document_files f on f.document_id = d.id
     where f.file_path = p_path
       and r.status in ('submitted', 'under_review')
       and r.user_id <> auth.uid()
       and d.owner_id = r.user_id
       and d.document_type = 'company_registration'
       and d.deleted_at is null);
$$;

create or replace function kaoid_private.can_read_evidence_r7c(p_path text)
returns boolean
language sql
stable
security definer
set search_path to ''
as $$
  select kaoid_private.can_read_evidence_base_r10e(p_path)
      or (kaoid_private.can_review_r7c() and exists(
            select 1 from kaoid_private.recovery_evidence_r10e e
              join kaoid_private.lifecycle_requests_r10b l on l.id = e.lifecycle_id
              join public.document_files f on f.document_id = e.previous_document
             where f.file_path = p_path and e.status = 'submitted' and l.status = 'pending'
               and e.profile_id <> auth.uid()))
      or kaoid_private.can_read_business_evidence_r15b(p_path);
$$;

create or replace function kaoid_private.notice_target_r15b(p_notice uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  n public.notifications%rowtype;
  q jsonb;
begin
  if auth.uid() is null or not kaoid_private.account_active_r9f() then
    raise exception 'session_required' using errcode = '42501';
  end if;
  select * into n from public.notifications
   where id = p_notice and profile_id = auth.uid() and not is_deleted and notification_type = 'kaoid';
  if not found then raise exception 'notice_unavailable' using errcode = '42501'; end if;

  if n.message in ('business_review_new', 'business_review_second', 'business_review_restart') then
    q := kaoid_private.business_review_rows_r15b(n.target_id) -> 0;
    if q is null then return jsonb_build_object('kind', 'unavailable'); end if;
    return jsonb_build_object('kind', 'business_review', 'row', q);
  elsif n.message in ('business_approved', 'business_rejected') then
    select jsonb_build_object('kind', 'result', 'status', status, 'reason', review_reason) into q
      from public.business_registrations where id = n.target_id and user_id = auth.uid();
    return coalesce(q, jsonb_build_object('kind', 'unavailable'));
  end if;
  return kaoid_private.notice_target_r14b(p_notice);
end;
$$;

create or replace function public.kaoid_notice_target_r14b(p_notice uuid)
returns jsonb
language sql
set search_path to ''
as $$ select kaoid_private.notice_target_r15b(p_notice); $$;

create or replace function public.submit_business_registration(p_registration_id uuid)
returns public.business_registrations
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_row public.business_registrations;
  v_org_id uuid;
  v_recipient uuid;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_restricted' using errcode = '42501';
  end if;
  select * into v_row from public.business_registrations
   where id = p_registration_id and user_id = auth.uid()
   for update;
  if v_row.id is null then raise exception 'REGISTRATION_NOT_FOUND'; end if;
  if v_row.status <> 'draft' then raise exception 'REGISTRATION_NOT_DRAFT'; end if;
  if v_row.document_id is null or not exists (
       select 1 from public.identity_documents d
        where d.id = v_row.document_id and d.owner_id = auth.uid()
          and d.document_type = 'company_registration' and d.deleted_at is null) then
    raise exception 'BUSINESS_DOCUMENT_REQUIRED';
  end if;
  if not exists (select 1 from kaoid_private.business_owner_bank_r15b(auth.uid())) then
    raise exception 'VERIFIED_BANK_REQUIRED';
  end if;

  v_org_id := public.register_organization(
    v_row.business_name, v_row.business_name, v_row.registration_number,
    case when v_row.business_type = 'registered_business' then 'company' else v_row.business_type end,
    'TH');
  perform public.initialize_organization_verification(v_org_id);

  -- Freeze the evidence: draft documents can still be replaced or deleted by the owner.
  update public.identity_documents
     set status = 'pending_review'
   where id = v_row.document_id and owner_id = auth.uid() and status = 'draft';

  update public.business_registrations
     set organization_id = v_org_id, status = 'under_review', submitted_at = now()
   where id = v_row.id
  returning * into v_row;

  for v_recipient in select * from kaoid_private.review_recipients_r14b(auth.uid(), null) loop
    perform kaoid_private.emit_notice_r10a(v_recipient, 'business-new:' || v_row.id || ':' || v_recipient,
      'business_review_new', v_row.id);
  end loop;
  return v_row;
end;
$$;

revoke all on function kaoid_private.business_owner_name_r15b(uuid) from public, anon, authenticated;
revoke all on function kaoid_private.business_owner_bank_r15b(uuid) from public, anon, authenticated;
revoke all on function kaoid_private.business_review_fingerprint_r15b(uuid) from public, anon, authenticated;
revoke all on function kaoid_private.business_review_rows_r15b(uuid) from public, anon, authenticated;
revoke all on function kaoid_private.business_review_vote_r15b(uuid, boolean, text) from public, anon, authenticated;
revoke all on function kaoid_private.can_read_business_evidence_r15b(text) from public, anon, authenticated;

revoke all on function kaoid_private.business_review_queue_r15b() from public, anon;
grant execute on function kaoid_private.business_review_queue_r15b() to authenticated;
revoke all on function kaoid_private.business_review_decide_r15b(uuid, uuid, boolean, text) from public, anon;
grant execute on function kaoid_private.business_review_decide_r15b(uuid, uuid, boolean, text) to authenticated;
revoke all on function kaoid_private.notice_target_r15b(uuid) from public, anon;
grant execute on function kaoid_private.notice_target_r15b(uuid) to authenticated;

revoke all on function public.business_review_queue_r15b() from public, anon;
grant execute on function public.business_review_queue_r15b() to authenticated;
revoke all on function public.business_review_decide_r15b(uuid, uuid, boolean, text) from public, anon;
grant execute on function public.business_review_decide_r15b(uuid, uuid, boolean, text) to authenticated;
revoke all on function public.kaoid_notice_target_r14b(uuid) from public, anon;
grant execute on function public.kaoid_notice_target_r14b(uuid) to authenticated;

revoke execute on function public.submit_business_registration(uuid) from public, anon;
grant execute on function public.submit_business_registration(uuid) to authenticated;
