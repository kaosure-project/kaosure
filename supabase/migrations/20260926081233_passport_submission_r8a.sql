-- Additive passport submission only. No approval, role assignment or ID issuance.
alter table public.identity_documents
 add column if not exists given_names text,
 add column if not exists family_name text,
 add column if not exists single_name boolean,
 add column if not exists family_name_first boolean,
 add column if not exists issuing_country text,
 add column if not exists date_of_birth date;

create or replace function kaoid_private.submit_passport_r8a(
 p_id uuid,p_number text,p_given text,p_family text,p_single boolean,p_family_first boolean,
 p_country text,p_birth date,p_issued date,p_expiry date,p_path text
) returns uuid language plpgsql security definer set search_path='' as $$
declare
 u uuid:=auth.uid(); d public.identity_documents%rowtype; o storage.objects%rowtype;
 fullname text;
begin
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then
  raise exception 'authentication_required' using errcode='42501'; end if;
 if p_single is null or p_family_first is null or p_id is null
  or p_number is null or length(btrim(p_number)) not between 1 and 30
  or p_number ~ '[[:cntrl:]]'
  or p_given is null or length(btrim(p_given)) not between 1 and 100
  or p_family is null or length(btrim(p_family))>100
  or (not p_single and btrim(p_family)='') or (p_single and btrim(p_family)<>'')
  or p_country is null or length(btrim(p_country)) not between 2 and 100
  or p_birth is null or p_birth>current_date or p_birth<date '1900-01-01'
  or p_issued is null or p_issued<p_birth or p_issued>current_date
  or p_expiry is null or p_expiry<=p_issued or p_expiry<current_date then
  raise exception 'invalid_passport' using errcode='22023'; end if;
 fullname:=case when p_single then btrim(p_given) when p_family_first
  then btrim(p_family)||' '||btrim(p_given) else btrim(p_given)||' '||btrim(p_family) end;
 if p_path is null or p_path<>u::text||'/passport/'||p_id::text||'/data.jpg' then
  raise exception 'invalid_document_paths' using errcode='22023'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(u::text,714));
 if not exists(select 1 from public.profiles where id=u and account_status='active' and deleted_at is null) then
  raise exception 'inactive_account' using errcode='42501'; end if;
 select * into d from public.identity_documents where id=p_id;
 if found then
  if d.owner_id=u and d.document_type='passport' and d.document_number=btrim(p_number)
   and d.given_names=btrim(p_given) and d.family_name=btrim(p_family)
   and d.single_name=p_single and d.family_name_first=p_family_first
   and d.issuing_country=btrim(p_country) and d.date_of_birth=p_birth
   and d.issued_date=p_issued and d.expiry_date=p_expiry and d.deleted_at is null
   and exists(select 1 from public.document_files where document_id=p_id and file_path=p_path) then return p_id; end if;
  raise exception 'document_conflict' using errcode='42501'; end if;
 -- Keep one active KYC request per person, consistent with existing national-ID path.
 if exists(select 1 from public.verification_requests where requested_by=u and status in ('pending','under_review'))
  or exists(select 1 from public.identity_documents where owner_id=u and document_type='passport'
   and deleted_at is null and (status='pending_review' or
     (status='approved' and (expiry_date is null or expiry_date>=current_date)))) then
  raise exception 'review_already_active' using errcode='55000'; end if;
 if not exists(select 1 from storage.buckets where id='identity-documents' and not public) then
  raise exception 'private_storage_required'; end if;
 select * into o from storage.objects where bucket_id='identity-documents' and name=p_path for update;
 if not found or o.owner_id is distinct from u::text
  or coalesce((o.metadata->>'size')::bigint,0) not between 1 and 10485760
  or coalesce(o.metadata->>'mimetype','')<>'image/jpeg' then
  raise exception 'invalid_uploaded_file' using errcode='22023'; end if;
 insert into public.identity_documents(id,owner_id,document_type,document_number,full_name,
  given_names,family_name,single_name,family_name_first,issuing_country,date_of_birth,
  issued_date,expiry_date,status,file_path)
 values(p_id,u,'passport',btrim(p_number),fullname,btrim(p_given),btrim(p_family),p_single,p_family_first,
  btrim(p_country),p_birth,p_issued,p_expiry,'pending_review',p_path);
 insert into public.document_files(document_id,file_path,file_name,mime_type,file_size)
 values(p_id,p_path,'data.jpg','image/jpeg',(o.metadata->>'size')::bigint);
 insert into public.verification_requests(document_id,requested_by,status) values(p_id,u,'pending');
 insert into public.verifications(profile_id,passport_status,passport_expiry)
 values(u,'pending',p_expiry) on conflict(profile_id) do update
 set passport_status='pending',passport_expiry=p_expiry,updated_at=now();
 return p_id;
end;
$$;
revoke all on function kaoid_private.submit_passport_r8a(uuid,text,text,text,boolean,boolean,text,date,date,date,text) from public,anon;
grant execute on function kaoid_private.submit_passport_r8a(uuid,text,text,text,boolean,boolean,text,date,date,date,text) to authenticated;
create or replace function public.submit_passport_r8a(
 p_id uuid,p_number text,p_given text,p_family text,p_single boolean,p_family_first boolean,
 p_country text,p_birth date,p_issued date,p_expiry date,p_path text
) returns uuid language sql security invoker set search_path='' as $$
 select kaoid_private.submit_passport_r8a(p_id,p_number,p_given,p_family,p_single,p_family_first,p_country,p_birth,p_issued,p_expiry,p_path);
$$;
revoke all on function public.submit_passport_r8a(uuid,text,text,text,boolean,boolean,text,date,date,date,text) from public,anon;
grant execute on function public.submit_passport_r8a(uuid,text,text,text,boolean,boolean,text,date,date,date,text) to authenticated;
