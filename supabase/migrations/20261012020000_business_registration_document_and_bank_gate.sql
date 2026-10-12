-- Business registration hardening (r15a)
-- 1. Business documents are uploaded to Storage by the owner, then registered server-side
--    (authenticated has no direct insert grant on identity_documents/document_files).
-- 2. Submission requires the owner's approved Kao ID bank account and a company_registration document.
-- 3. The legacy attach RPC accepted any owned identity document, so it is no longer executable by clients.

create or replace function kaoid_private.attach_business_document_r15a(
  p_registration_id uuid,
  p_document_id uuid,
  p_path text,
  p_file_name text
)
returns public.business_registrations
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := auth.uid();
  r public.business_registrations%rowtype;
  d public.identity_documents%rowtype;
  o storage.objects%rowtype;
begin
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_restricted' using errcode = '42501';
  end if;
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if p_registration_id is null or p_document_id is null or p_path is null
     or p_path !~ ('^' || u::text || '/business-registration/' || p_registration_id::text
                   || '/' || p_document_id::text || '\.(jpg|png|pdf)$') then
    raise exception 'invalid_document_paths' using errcode = '22023';
  end if;
  if p_file_name is null or length(btrim(p_file_name)) not between 1 and 200
     or p_file_name ~ '[[:cntrl:]]' then
    raise exception 'invalid_document' using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(u::text, 721));

  select * into r from public.business_registrations
   where id = p_registration_id and user_id = u
   for update;
  if not found or r.status <> 'draft' then
    raise exception 'DRAFT_NOT_FOUND_OR_NOT_EDITABLE' using errcode = '42501';
  end if;

  select * into d from public.identity_documents where id = p_document_id;
  if found then
    -- Idempotent retry of the same upload.
    if d.owner_id <> u or d.document_type <> 'company_registration'
       or d.file_path is distinct from p_path or d.deleted_at is not null then
      raise exception 'document_conflict' using errcode = '42501';
    end if;
  else
    if not exists (select 1 from storage.buckets where id = 'identity-documents' and public = false) then
      raise exception 'private_storage_required' using errcode = '55000';
    end if;
    select * into o from storage.objects
     where bucket_id = 'identity-documents' and name = p_path
     for update;
    if not found or o.owner_id is distinct from u::text
       or coalesce((o.metadata->>'size')::bigint, 0) not between 1 and 10485760
       or coalesce(o.metadata->>'mimetype', '') not in ('image/jpeg', 'image/png', 'application/pdf') then
      raise exception 'invalid_uploaded_file' using errcode = '22023';
    end if;

    insert into public.identity_documents(
      id, owner_id, document_type, document_number, full_name, country_code,
      status, file_path, file_name, file_size, mime_type, uploaded_at)
    values (
      p_document_id, u, 'company_registration', r.registration_number, r.business_name, 'TH',
      'draft', p_path, btrim(p_file_name), (o.metadata->>'size')::bigint, o.metadata->>'mimetype', now());

    insert into public.document_files(document_id, file_path, file_name, mime_type, file_size)
    values (p_document_id, p_path, btrim(p_file_name), o.metadata->>'mimetype', (o.metadata->>'size')::bigint);
  end if;

  -- A replaced, never-submitted business document is retired, not reused.
  update public.identity_documents
     set deleted_at = now()
   where id = r.document_id and id <> p_document_id and owner_id = u
     and document_type = 'company_registration' and status = 'draft' and deleted_at is null;

  update public.business_registrations
     set document_id = p_document_id, document_status = 'uploaded'
   where id = r.id
  returning * into r;

  return r;
end;
$$;

create or replace function public.attach_business_document_r15a(
  p_registration_id uuid,
  p_document_id uuid,
  p_path text,
  p_file_name text
)
returns public.business_registrations
language sql
set search_path to ''
as $$
  select * from kaoid_private.attach_business_document_r15a(p_registration_id, p_document_id, p_path, p_file_name);
$$;

create or replace function public.submit_business_registration(p_registration_id uuid)
returns public.business_registrations
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_row public.business_registrations;
  v_org_id uuid;
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
  -- Same approval rule the Kao ID bank screen shows as "approved" (kaoid_private.list_banks_r8c).
  if not exists (
       select 1 from public.bank_accounts b
         join public.financial_verifications f on f.bank_account_id = b.id
        where b.profile_id = auth.uid() and b.organization_id is null
          and b.is_active and b.deleted_at is null
          and b.is_verified and b.status = 'verified'
          and f.status = 'approved' and f.name_match_status = 'matched') then
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
  return v_row;
end;
$$;

revoke all on function kaoid_private.attach_business_document_r15a(uuid, uuid, text, text) from public, anon;
grant execute on function kaoid_private.attach_business_document_r15a(uuid, uuid, text, text) to authenticated;
revoke all on function public.attach_business_document_r15a(uuid, uuid, text, text) from public, anon;
grant execute on function public.attach_business_document_r15a(uuid, uuid, text, text) to authenticated;

revoke execute on function public.submit_business_registration(uuid) from public, anon;
grant execute on function public.submit_business_registration(uuid) to authenticated;

revoke execute on function public.attach_business_registration_document(uuid, uuid) from public, anon, authenticated;
