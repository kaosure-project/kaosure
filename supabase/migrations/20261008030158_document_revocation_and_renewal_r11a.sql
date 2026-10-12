-- Preserve documents and Kao ID; suspend entitlement, never issue a replacement ID.
create table kaoid_private.identity_holds_r11a (
 profile_id uuid primary key references public.profiles(id), created_at timestamptz not null default now()
);
alter table kaoid_private.identity_holds_r11a enable row level security;
revoke all on kaoid_private.identity_holds_r11a from public,anon,authenticated;
create or replace function kaoid_private.valid_identity_r11a(p_profile uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.identity_documents d join public.verification_requests r on r.document_id=d.id
 where d.owner_id=p_profile and d.document_type in ('thai_national_id','passport') and d.status='approved'
 and d.deleted_at is null and (d.expiry_date is null or d.expiry_date>=current_date)
 and r.requested_by=p_profile and r.status='approved' and r.reviewed_by is not null and r.reviewed_by<>p_profile);
$$;
create or replace function kaoid_private.sync_identity_r11a(p_profile uuid) returns void
language plpgsql security definer set search_path='' as $$
declare valid boolean; affected integer;
begin
 perform 1 from public.profiles where id=p_profile for update;
 valid:=kaoid_private.valid_identity_r11a(p_profile);
 if not valid then
  update public.kao_id_identities set status='suspended',updated_at=now()
   where profile_id=p_profile and identity_type='personal' and status='active';
  get diagnostics affected=row_count;
  if affected>0 then insert into kaoid_private.identity_holds_r11a(profile_id) values(p_profile) on conflict do nothing;end if;
 else
  if exists(select 1 from public.profiles where id=p_profile and account_status='active' and deleted_at is null) then
   update public.kao_id_identities set status='active',updated_at=now() where profile_id=p_profile and identity_type='personal'
    and status='suspended' and exists(select 1 from kaoid_private.identity_holds_r11a where profile_id=p_profile);
   delete from kaoid_private.identity_holds_r11a where profile_id=p_profile;
  end if;
 end if;
 update public.verifications v set status=case when valid then 'approved'
    when exists(select 1 from public.identity_documents where owner_id=p_profile and document_type in ('thai_national_id','passport') and status='revoked') then 'revoked'
    when exists(select 1 from public.identity_documents where owner_id=p_profile and document_type in ('thai_national_id','passport') and (status='expired' or (status='approved' and expiry_date<current_date))) then 'expired' else v.status end,
  account_level=case when valid then 'verified' else 'registered' end,
  identity_card_status=coalesce((select case when status='approved' and (expiry_date is null or expiry_date>=current_date) then 'verified' when status='approved' then 'expired' else status end from public.identity_documents where owner_id=p_profile and document_type='thai_national_id' and deleted_at is null order by created_at desc,id desc limit 1),v.identity_card_status),
  passport_status=coalesce((select case when status='approved' and (expiry_date is null or expiry_date>=current_date) then 'verified' when status='approved' then 'expired' else status end from public.identity_documents where owner_id=p_profile and document_type='passport' and deleted_at is null order by created_at desc,id desc limit 1),v.passport_status),
  residence_permit_status=coalesce((select case when status='approved' and (expiry_date is null or expiry_date>=current_date) then 'verified' when status='approved' then 'expired' else status end from public.identity_documents where owner_id=p_profile and document_type='residence_card' and deleted_at is null order by created_at desc,id desc limit 1),v.residence_permit_status),
  updated_at=now() where profile_id=p_profile;
end $$;
create or replace function kaoid_private.revoke_document_r11a(p_document uuid,p_reason text) returns boolean
language plpgsql security definer set search_path='' as $$
declare d public.identity_documents%rowtype;
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501';end if;
 if length(btrim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'reason_required' using errcode='22023';end if;
 select * into d from public.identity_documents where id=p_document;
 if not found or d.owner_id=auth.uid() or d.deleted_at is not null then raise exception 'not_authorized' using errcode='42501';end if;
 perform 1 from public.profiles where id=d.owner_id for update;
 select * into d from public.identity_documents where id=p_document for update;
 if d.status='revoked' then return true;end if;
 if d.status not in ('approved','expired') then raise exception 'approved_document_required';end if;
 update public.identity_documents set status='revoked',rejected_reason=btrim(p_reason),updated_at=now() where id=p_document;
 perform kaoid_private.sync_identity_r11a(d.owner_id);
 insert into public.activity_logs(profile_id,action,target_table,target_id,description)
 values(auth.uid(),'kyc.revoke','identity_documents',p_document,jsonb_build_object('owner_id',d.owner_id,'previous',d.status,'reason',btrim(p_reason))::text);
 perform kaoid_private.emit_notice_r10a(d.owner_id,'kyc-revoked:'||p_document,'kyc_revoked',p_document);
 return true;
end $$;
create or replace function kaoid_private.document_health_r11a(p_profile uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare target uuid:=coalesce(p_profile,auth.uid());
begin
 if not kaoid_private.account_active_r9f() or (target<>auth.uid() and not kaoid_private.can_read_members_r9a()) then raise exception 'not_authorized' using errcode='42501';end if;
 return jsonb_build_object('eligible',kaoid_private.valid_identity_r11a(target),
 'documents',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (
 select d.id,d.document_type,case when d.status='approved' and d.expiry_date<current_date then 'expired' else d.status end status,
 d.expiry_date,d.created_at,d.rejected_reason from public.identity_documents d where d.owner_id=target and d.deleted_at is null order by d.created_at desc,d.id desc limit 100)x),
 'history',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (select a.id,a.action,a.created_at,a.profile_id as actor_id,a.description
 from public.activity_logs a where a.action in ('kyc.revoke','kyc.expire') and a.target_id in (select id from public.identity_documents where owner_id=target)
 order by a.created_at desc,a.id desc limit 100)x));
end $$;
create or replace function kaoid_private.expire_documents_r11a() returns integer
language plpgsql security definer set search_path='' as $$
declare d record; n integer:=0;
begin
 -- Bounded batches, only documents that still need an expiry transition.
 for d in select id,owner_id from public.identity_documents where status='approved' and deleted_at is null
 and document_type in ('thai_national_id','passport','residence_card') and expiry_date<current_date
 order by expiry_date,id limit 200 for update skip locked loop
  update public.identity_documents set status='expired',updated_at=now() where id=d.id;
  perform kaoid_private.sync_identity_r11a(d.owner_id);
  insert into public.activity_logs(profile_id,action,target_table,target_id,description)
   values(null,'kyc.expire','identity_documents',d.id,'{"process":"document-expiry-r11a"}');
  perform kaoid_private.emit_notice_r10a(d.owner_id,'kyc-expired:'||d.id,'kyc_expired',d.id);n:=n+1;
 end loop;
 for d in select id,owner_id from public.identity_documents where status='approved' and deleted_at is null
 and document_type in ('thai_national_id','passport','residence_card') and expiry_date between current_date and current_date+30
 and not exists(select 1 from public.notifications where event_key='kyc-expiring:'||identity_documents.id)
 order by expiry_date,id limit 200 loop
  perform kaoid_private.emit_notice_r10a(d.owner_id,'kyc-expiring:'||d.id,'kyc_expiring',d.id);
 end loop;
 return n;
end $$;
create or replace function public.revoke_document_r11a(p_document uuid,p_reason text) returns boolean language sql set search_path='' as $$select kaoid_private.revoke_document_r11a(p_document,p_reason);$$;
create or replace function public.document_health_r11a(p_profile uuid default null) returns jsonb language sql set search_path='' as $$select kaoid_private.document_health_r11a(p_profile);$$;
revoke all on function kaoid_private.valid_identity_r11a(uuid),kaoid_private.sync_identity_r11a(uuid),kaoid_private.revoke_document_r11a(uuid,text),kaoid_private.document_health_r11a(uuid),kaoid_private.expire_documents_r11a(),public.revoke_document_r11a(uuid,text),public.document_health_r11a(uuid) from public,anon,authenticated;
grant execute on function kaoid_private.revoke_document_r11a(uuid,text),kaoid_private.document_health_r11a(uuid),public.revoke_document_r11a(uuid,text),public.document_health_r11a(uuid) to authenticated;

CREATE OR REPLACE FUNCTION kaoid_private.submit_national_id_r7a(p_id uuid, p_number text, p_full_name text, p_issued date, p_expiry date, p_front text, p_back text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_uid uuid := auth.uid();
 v_existing public.identity_documents%rowtype;
 v_path text; v_object storage.objects%rowtype;
begin
 if not kaoid_private.account_active_r9f() then raise exception 'account_restricted' using errcode='42501'; end if;
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
    or exists(select 1 from public.identity_documents where owner_id=v_uid and document_type='thai_national_id' and (status='pending_review' or (status='approved' and (expiry_date is null or expiry_date>current_date+30))) and deleted_at is null) then
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
$function$
;
CREATE OR REPLACE FUNCTION kaoid_private.submit_passport_r8a(p_id uuid, p_number text, p_given text, p_family text, p_single boolean, p_family_first boolean, p_country text, p_birth date, p_issued date, p_expiry date, p_path text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 u uuid:=auth.uid(); d public.identity_documents%rowtype; o storage.objects%rowtype;
 fullname text;
begin
 if not kaoid_private.account_active_r9f() then raise exception 'account_restricted' using errcode='42501'; end if;
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
     (status='approved' and (expiry_date is null or expiry_date>current_date+30)))) then
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
$function$
;
CREATE OR REPLACE FUNCTION kaoid_private.submit_residence_r8b(p_id uuid, p_number text, p_given text, p_family text, p_single boolean, p_family_first boolean, p_country text, p_format text, p_no_expiry boolean, p_issued date, p_expiry date, p_front text, p_back text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 u uuid:=auth.uid(); d public.identity_documents%rowtype; o storage.objects%rowtype;
 fullname text; paths text[]; path text;
begin
 if not kaoid_private.account_active_r9f() then raise exception 'account_restricted' using errcode='42501'; end if;
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then
  raise exception 'authentication_required' using errcode='42501'; end if;
 if p_single is null or p_family_first is null or p_id is null
  or p_number is null or length(btrim(p_number)) not between 1 and 30
  or p_number ~ '[[:cntrl:]]'
  or p_given is null or length(btrim(p_given)) not between 1 and 100
  or p_family is null or length(btrim(p_family))>100
  or (not p_single and btrim(p_family)='') or (p_single and btrim(p_family)<>'')
  or p_country is null or length(btrim(p_country)) not between 2 and 100
  or p_format is null or p_format not in ('card','paper') or p_no_expiry is null
  or p_issued is null or p_issued>current_date or p_issued<date '1900-01-01'
  or (p_no_expiry and p_expiry is not null)
  or (not p_no_expiry and (p_expiry is null or p_expiry<=p_issued or p_expiry<current_date)) then
  raise exception 'invalid_residence' using errcode='22023'; end if;
 fullname:=case when p_single then btrim(p_given) when p_family_first
  then btrim(p_family)||' '||btrim(p_given) else btrim(p_given)||' '||btrim(p_family) end;
 if p_front is null or p_front<>u::text||'/residence/'||p_id::text||'/front.jpg'
  or (p_format='card' and (p_back is null or p_back<>u::text||'/residence/'||p_id::text||'/back.jpg'))
  or (p_format='paper' and p_back is not null) then
  raise exception 'invalid_document_paths' using errcode='22023'; end if;
 paths:=case when p_format='card' then array[p_front,p_back] else array[p_front] end;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(u::text,714));
 if not exists(select 1 from public.profiles where id=u and account_status='active' and deleted_at is null) then
  raise exception 'inactive_account' using errcode='42501'; end if;
 select * into d from public.identity_documents where id=p_id;
 if found then
  if d.owner_id=u and d.document_type='residence_card' and d.document_number=btrim(p_number)
   and d.given_names=btrim(p_given) and d.family_name=btrim(p_family)
   and d.single_name=p_single and d.family_name_first=p_family_first
   and d.issuing_country=btrim(p_country) and d.residence_format=p_format and d.no_expiry=p_no_expiry
   and d.issued_date=p_issued and d.expiry_date is not distinct from p_expiry and d.deleted_at is null
   and (select count(*) from public.document_files where document_id=p_id and file_path=any(paths))=cardinality(paths) then return p_id; end if;
  raise exception 'document_conflict' using errcode='42501'; end if;
 -- Keep one active KYC request per person, consistent with existing national-ID path.
 if exists(select 1 from public.verification_requests where requested_by=u and status in ('pending','under_review'))
  or exists(select 1 from public.identity_documents where owner_id=u and document_type='residence_card'
   and deleted_at is null and (status='pending_review' or
     (status='approved' and (expiry_date is null or expiry_date>current_date+30)))) then
  raise exception 'review_already_active' using errcode='55000'; end if;
 if not exists(select 1 from storage.buckets where id='identity-documents' and not public) then
  raise exception 'private_storage_required'; end if;
 foreach path in array paths loop
 select * into o from storage.objects where bucket_id='identity-documents' and name=path for update;
 if not found or o.owner_id is distinct from u::text
  or coalesce((o.metadata->>'size')::bigint,0) not between 1 and 10485760
  or coalesce(o.metadata->>'mimetype','')<>'image/jpeg' then
  raise exception 'invalid_uploaded_file' using errcode='22023'; end if;
 end loop;
 insert into public.identity_documents(id,owner_id,document_type,document_number,full_name,
  given_names,family_name,single_name,family_name_first,issuing_country,residence_format,no_expiry,
  issued_date,expiry_date,status,file_path)
 values(p_id,u,'residence_card',btrim(p_number),fullname,btrim(p_given),btrim(p_family),p_single,p_family_first,
  btrim(p_country),p_format,p_no_expiry,p_issued,p_expiry,'pending_review',p_front);
 insert into public.document_files(document_id,file_path,file_name,mime_type,file_size)
 select p_id,obj.name,case when obj.name=p_front then 'front.jpg' else 'back.jpg' end,'image/jpeg',(obj.metadata->>'size')::bigint
 from storage.objects obj where obj.bucket_id='identity-documents' and obj.name=any(paths);
 insert into public.verification_requests(document_id,requested_by,status) values(p_id,u,'pending');
 insert into public.verifications(profile_id,residence_permit_status,residence_permit_expiry)
 values(u,'pending',p_expiry) on conflict(profile_id) do update
 set residence_permit_status='pending',residence_permit_expiry=p_expiry,updated_at=now();
 return p_id;
end;
$function$
;
CREATE OR REPLACE FUNCTION kaoid_private.review_decision_base_r10e(p_request uuid, p_approve boolean, p_reason text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r public.verification_requests%rowtype; d public.identity_documents%rowtype; v_status text; paths text[]; v_primary boolean;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
 if p_approve is null or length(coalesce(p_reason,''))>1000 or (not p_approve and length(btrim(coalesce(p_reason,'')))<3) then
  raise exception 'invalid_decision' using errcode='22023'; end if;
 if exists(select 1 from public.financial_verifications where id=p_request) then
 return kaoid_private.review_bank_r9c(p_request,p_approve,p_reason); end if;
 select * into r from public.verification_requests where id=p_request for update;
 if not found or r.requested_by=auth.uid() then raise exception 'request_not_available' using errcode='42501'; end if;
 v_status:=case when p_approve then 'approved' else 'rejected' end;
 if r.status=v_status and r.reviewed_by=auth.uid() then return true; end if;
 if r.status not in ('pending','under_review') then raise exception 'request_already_reviewed' using errcode='55000'; end if;
 select * into d from public.identity_documents where id=r.document_id for update;
 if not found or d.owner_id<>r.requested_by or d.document_type not in ('thai_national_id','passport','residence_card') or d.deleted_at is not null then
  raise exception 'invalid_document' using errcode='22023'; end if;
 perform 1 from public.profiles where id=r.requested_by and account_status='active' and deleted_at is null for update;
 if not found then raise exception 'inactive_account' using errcode='42501'; end if;
 perform 1 from public.verifications where profile_id=r.requested_by for update;
 if not found then raise exception 'verification_record_missing' using errcode='55000'; end if;
 if p_approve then
  if d.status<>'pending_review' or nullif(btrim(d.full_name),'') is null
  or nullif(btrim(d.document_number),'') is null or d.issued_date>current_date
  or (d.expiry_date is not null and d.expiry_date<current_date) then
   raise exception 'document_not_ready' using errcode='22023'; end if;
  if d.document_type='thai_national_id' then
   if d.document_number !~ '^[0-9]{13}$' then raise exception 'document_not_ready'; end if;
   paths:=array[d.owner_id::text||'/national-id/'||d.id::text||'/front.jpg',d.owner_id::text||'/national-id/'||d.id::text||'/back.jpg'];
  elsif d.document_type='passport' then
   if d.expiry_date is null or d.issued_date is null or d.date_of_birth is null
    or d.date_of_birth>d.issued_date or d.expiry_date<=d.issued_date
    or nullif(btrim(d.issuing_country),'') is null then raise exception 'document_not_ready'; end if;
   paths:=array[d.owner_id::text||'/passport/'||d.id::text||'/data.jpg'];
  else
   if d.issued_date is null or d.residence_format not in ('card','paper')
    or d.residence_format is null or d.no_expiry is null
    or (d.no_expiry and d.expiry_date is not null)
    or (not d.no_expiry and (d.expiry_date is null or d.expiry_date<=d.issued_date))
    then raise exception 'document_not_ready'; end if;
   paths:=array[d.owner_id::text||'/residence/'||d.id::text||'/front.jpg'];
   if d.residence_format='card' then paths:=array_append(paths,d.owner_id::text||'/residence/'||d.id::text||'/back.jpg'); end if;
  end if;
  if (select count(distinct f.file_path) from public.document_files f join storage.objects o
     on o.bucket_id='identity-documents' and o.name=f.file_path
     where f.document_id=d.id and o.owner_id=d.owner_id::text and f.file_path=any(paths))<>cardinality(paths)
    then raise exception 'document_files_missing'; end if;
  perform pg_advisory_xact_lock(hashtextextended(d.document_type||':'||lower(btrim(coalesce(d.issuing_country,'')))||':'||upper(btrim(d.document_number)),715));
  if exists(select 1 from public.identity_documents x where x.document_type=d.document_type
     and upper(btrim(x.document_number))=upper(btrim(d.document_number))
     and (d.document_type='thai_national_id' or lower(btrim(coalesce(x.issuing_country,'')))=lower(btrim(coalesce(d.issuing_country,''))))
     and x.owner_id<>d.owner_id and x.status in ('approved','expired','revoked') and x.deleted_at is null)
     then raise exception 'identity_already_registered' using errcode='23505'; end if;
 end if;
 update public.identity_documents set status=v_status,verified_by=auth.uid(),
  verified_at=case when p_approve then now() else null end,
  rejected_reason=case when p_approve then null else btrim(p_reason) end where id=d.id;
 update public.verification_requests set status=v_status,reviewed_at=now(),reviewed_by=auth.uid(),
  rejection_reason=case when p_approve then null else btrim(p_reason) end,notes=p_reason where id=r.id;
 select exists(select 1 from public.identity_documents x join public.verification_requests q on q.document_id=x.id
  where x.owner_id=r.requested_by and x.document_type in ('thai_national_id','passport')
  and x.status='approved' and x.deleted_at is null and (x.expiry_date is null or x.expiry_date>=current_date)
  and q.status='approved' and q.reviewed_by is not null and q.reviewed_by<>x.owner_id) into v_primary;
 update public.verifications set
 identity_card_status=case when d.document_type='thai_national_id' then case when p_approve then 'verified' else 'rejected' end else identity_card_status end,
 passport_status=case when d.document_type='passport' then case when p_approve then 'verified' else 'rejected' end else passport_status end,
 residence_permit_status=case when d.document_type='residence_card' then case when p_approve then 'verified' else 'rejected' end else residence_permit_status end,
 identity_expiry=case when d.document_type='thai_national_id' then d.expiry_date else identity_expiry end,
 passport_expiry=case when d.document_type='passport' then d.expiry_date else passport_expiry end,
 residence_permit_expiry=case when d.document_type='residence_card' then d.expiry_date else residence_permit_expiry end,
 status=case when v_primary then 'approved' when d.document_type='residence_card' then status else v_status end,
 account_level=case when v_primary then 'verified' when d.document_type='residence_card' then account_level else 'registered' end,
 last_reviewed_by=auth.uid(),last_verified_at=case when v_primary then now() else last_verified_at end,
 rejected_reason=case when v_primary then null when d.document_type='residence_card' then rejected_reason else btrim(p_reason) end
 where profile_id=r.requested_by;
 insert into public.verification_logs(verification_request_id,action,old_status,new_status,performed_by,notes)
 values(r.id,case when p_approve then 'approve' else 'reject' end,r.status,v_status,auth.uid(),p_reason);
 perform kaoid_private.sync_identity_r11a(r.requested_by);
 return true;
end $function$
;
CREATE OR REPLACE FUNCTION kaoid_private.issue_kao_id_r7c(p_profile_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_existing text; v_status text; v_id text; i integer;
begin
 if not kaoid_private.account_active_r9f() then raise exception 'account_restricted' using errcode='42501'; end if;
 if auth.uid() is null or p_profile_id is distinct from auth.uid() or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then
  raise exception 'not_authorized' using errcode='42501'; end if;
 perform 1 from public.profiles where id=p_profile_id and account_status='active' and deleted_at is null for update;
 if not found then raise exception 'inactive_account' using errcode='42501'; end if;
 if not kaoid_private.valid_identity_r11a(p_profile_id) then raise exception 'approved_identity_required' using errcode='42501';end if;
 select kao_id,status into v_existing,v_status from public.kao_id_identities where profile_id=p_profile_id;
 if found then
  if v_status<>'active' then raise exception 'identity_inactive' using errcode='42501'; end if;
  return v_existing;
 end if;
 if not exists(select 1 from public.verifications where profile_id=p_profile_id and status='approved')
 or not exists(select 1 from public.identity_documents d join public.verification_requests r on r.document_id=d.id
  where d.owner_id=p_profile_id and d.document_type in ('thai_national_id','passport') and d.status='approved' and d.deleted_at is null
  and (d.expiry_date is null or d.expiry_date>=current_date) and r.status='approved'
  and r.reviewed_by is not null and r.reviewed_by<>p_profile_id and r.requested_by=p_profile_id) then
  raise exception 'approved_identity_required' using errcode='42501'; end if;
 for i in 1..5 loop
  v_id:=public.generate_kao_id();
  begin
   insert into public.kao_id_identities(profile_id,kao_id,status,identity_type,issued_at) values(p_profile_id,v_id,'active','personal',now());
   return v_id;
  exception when unique_violation then
   select kao_id into v_existing from public.kao_id_identities where profile_id=p_profile_id;
   if found then return v_existing; end if;
  end;
 end loop;
 raise exception 'identity_generation_failed';
end $function$
;;
