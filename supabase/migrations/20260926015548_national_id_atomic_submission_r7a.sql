-- Kao ID: narrowly scoped atomic national-ID submission.
-- Existing signup, contact verification, passport and officer logic are unchanged.
create schema if not exists kaoid_private;
revoke all on schema kaoid_private from public, anon;
grant usage on schema kaoid_private to authenticated;

create or replace function kaoid_private.submit_national_id_r7a(
 p_id uuid, p_number text, p_full_name text, p_issued date, p_expiry date,
 p_front text, p_back text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare
 v_uid uuid := auth.uid();
 v_existing public.identity_documents%rowtype;
 v_path text; v_object storage.objects%rowtype;
begin
 if v_uid is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then
   raise exception 'authentication_required' using errcode='42501';
 end if;
 if p_id is null or p_number is null or p_number !~ '^[0-9]{13}$'
    or p_full_name is null or length(btrim(p_full_name)) not between 2 and 200
    or p_issued is null or p_issued > current_date
    or (p_expiry is not null and (p_expiry <= p_issued or p_expiry < current_date)) then
   raise exception 'invalid_document' using errcode='22023';
 end if;
 if p_front is null or p_back is null
    or p_front !~ ('^'||v_uid::text||'/national-id/'||p_id::text||'/front\.(jpg|png)$')
    or p_back !~ ('^'||v_uid::text||'/national-id/'||p_id::text||'/back\.(jpg|png)$') then
   raise exception 'invalid_document_paths' using errcode='22023';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_uid::text,714));
 select * into v_existing from public.identity_documents where id=p_id;
 if found then
   if v_existing.owner_id=v_uid and v_existing.document_number=p_number
      and v_existing.full_name=btrim(p_full_name)
      and v_existing.issued_date=p_issued
      and v_existing.expiry_date is not distinct from p_expiry
      and (select count(*) from public.document_files where document_id=p_id and file_path in(p_front,p_back))=2 then
     return p_id;
   end if;
   raise exception 'document_conflict' using errcode='42501';
 end if;
 if exists(select 1 from public.verification_requests where requested_by=v_uid and status in ('pending','under_review'))
    or exists(select 1 from public.identity_documents where owner_id=v_uid and document_type='thai_national_id' and status in ('approved','pending_review') and deleted_at is null) then
   raise exception 'review_already_active' using errcode='55000';
 end if;
 if not exists(select 1 from storage.buckets where id='identity-documents' and public=false) then
   raise exception 'private_storage_required' using errcode='55000';
 end if;
 foreach v_path in array array[p_front,p_back] loop
   select * into v_object from storage.objects where bucket_id='identity-documents' and name=v_path for update;
   if not found or v_object.owner_id is distinct from v_uid::text
      or coalesce((v_object.metadata->>'size')::bigint,0) not between 1 and 10485760
      or coalesce(v_object.metadata->>'mimetype','') not in ('image/jpeg','image/png') then
     raise exception 'invalid_uploaded_file' using errcode='22023';
   end if;
 end loop;
 insert into public.identity_documents(id,owner_id,document_type,document_number,full_name,country_code,
   issued_date,expiry_date,status,file_path)
 values(p_id,v_uid,'thai_national_id',p_number,btrim(p_full_name),'TH',p_issued,p_expiry,'pending_review',p_front);
 insert into public.document_files(document_id,file_path,file_name,mime_type,file_size)
 select p_id,o.name,case when o.name=p_front then 'front' else 'back' end,
   o.metadata->>'mimetype',(o.metadata->>'size')::bigint
 from storage.objects o where o.bucket_id='identity-documents' and o.name in(p_front,p_back);
 insert into public.verification_requests(document_id,requested_by,status) values(p_id,v_uid,'pending');
 update public.verifications set identity_card_status='pending',updated_at=now() where profile_id=v_uid;
 return p_id;
end;
$$;
revoke all on function kaoid_private.submit_national_id_r7a(uuid,text,text,date,date,text,text) from public,anon;
grant execute on function kaoid_private.submit_national_id_r7a(uuid,text,text,date,date,text,text) to authenticated;

create or replace function public.submit_national_id_r7a(
 p_id uuid,p_number text,p_full_name text,p_issued date,p_expiry date,p_front text,p_back text
) returns uuid language sql security invoker set search_path = '' as $$
 select kaoid_private.submit_national_id_r7a(p_id,p_number,p_full_name,p_issued,p_expiry,p_front,p_back);
$$;
revoke all on function public.submit_national_id_r7a(uuid,text,text,date,date,text,text) from public,anon;
grant execute on function public.submit_national_id_r7a(uuid,text,text,date,date,text,text) to authenticated;
-- Read-only nested file metadata remains filtered by the existing owner RLS.
grant select on public.document_files to authenticated;

;
