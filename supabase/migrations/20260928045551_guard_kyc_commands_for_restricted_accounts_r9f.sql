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
end $function$;
CREATE OR REPLACE FUNCTION kaoid_private.submit_bank_r8c(p_id uuid, p_bank text, p_name text, p_number text, p_branch text, p_type text, p_evidence text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 u uuid:=auth.uid(); b public.bank_accounts%rowtype; o storage.objects%rowtype;
begin
 if not kaoid_private.account_active_r9f() then raise exception 'account_restricted' using errcode='42501'; end if;
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then
  raise exception 'authentication_required' using errcode='42501'; end if;
 if p_id is null or p_bank is null or length(btrim(p_bank)) not between 2 and 100
  or p_name is null or length(btrim(p_name)) not between 1 and 200
  or p_number is null or p_number !~ '^[0-9]{6,20}$'
  or p_branch is null or length(btrim(p_branch))>100
  or (p_bank||p_name||p_branch) ~ '[[:cntrl:]]'
  or p_type is null or p_type not in ('savings','current') then
  raise exception 'invalid_bank' using errcode='22023'; end if;
 if p_evidence is null or p_evidence<>u::text||'/bank-account/'||p_id::text||'/evidence.jpg' then
  raise exception 'invalid_document_paths' using errcode='22023'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(u::text,718));
 if not exists(select 1 from public.profiles where id=u and account_status='active' and deleted_at is null) then
  raise exception 'inactive_account' using errcode='42501'; end if;
 select * into b from public.bank_accounts where id=p_id;
 if found then
  if b.profile_id=u and b.organization_id is null and b.bank_name=btrim(p_bank)
   and b.account_name=btrim(p_name) and b.account_number=p_number and b.branch_name=btrim(p_branch)
   and b.account_type=p_type and b.currency_code='THB' and b.evidence_path=p_evidence
   and b.deleted_at is null and exists(select 1 from public.financial_verifications where bank_account_id=b.id) then
   return p_id; end if;
  raise exception 'bank_conflict' using errcode='42501'; end if;
 -- Financial review is separate from identity-document review.
 if exists(select 1 from public.bank_accounts where profile_id=u and deleted_at is null and is_active
   and status in ('pending','manual_review')) then
  raise exception 'bank_review_active' using errcode='55000'; end if;
 if exists(select 1 from public.bank_accounts where profile_id=u and deleted_at is null and is_active
   and status not in ('rejected','expired') and lower(btrim(bank_name))=lower(btrim(p_bank)) and account_number=p_number) then
  raise exception 'bank_duplicate' using errcode='23505'; end if;
 if not exists(select 1 from storage.buckets where id='identity-documents' and not public) then
  raise exception 'private_storage_required'; end if;
 select * into o from storage.objects where bucket_id='identity-documents' and name=p_evidence for update;
 if not found or o.owner_id is distinct from u::text
  or coalesce((o.metadata->>'size')::bigint,0) not between 1 and 10485760
  or coalesce(o.metadata->>'mimetype','')<>'image/jpeg' then
  raise exception 'invalid_uploaded_file' using errcode='22023'; end if;
 insert into public.bank_accounts(id,profile_id,bank_code,bank_name,account_name,account_number,
  branch_name,account_type,currency_code,evidence_path,is_default,is_verified,is_active,status)
 values(p_id,u,'manual',btrim(p_bank),btrim(p_name),p_number,btrim(p_branch),p_type,'THB',p_evidence,false,false,true,'pending');
 insert into public.financial_verifications(bank_account_id,identity_type,profile_id,name_match_status,status)
 values(p_id,'personal',u,'pending','pending');
 return p_id;
end;
$function$;
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
$function$;
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
$function$;
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
     (status='approved' and (expiry_date is null or expiry_date>=current_date)))) then
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
$function$;
