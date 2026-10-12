create or replace function kaoid_private.review_bank_r9c(p_request uuid,p_approve boolean,p_reason text) returns boolean
language plpgsql security definer set search_path='' as $$
declare f public.financial_verifications%rowtype; b public.bank_accounts%rowtype; result text;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
 if p_approve is null or length(coalesce(p_reason,''))>1000 or (not p_approve and length(btrim(coalesce(p_reason,'')))<3) then raise exception 'invalid_decision'; end if;
 select * into f from public.financial_verifications where id=p_request for update;
 if not found or f.profile_id=auth.uid() or f.organization_id is not null then raise exception 'request_not_available' using errcode='42501'; end if;
 result:=case when p_approve then 'approved' else 'rejected' end;
 if f.status=result and f.verified_by=auth.uid() then return true; end if;
 if f.status<>'pending' then raise exception 'request_already_reviewed'; end if;
 select * into b from public.bank_accounts where id=f.bank_account_id for update;
 if not found or b.profile_id<>f.profile_id or b.deleted_at is not null or not b.is_active or b.organization_id is not null then raise exception 'invalid_document'; end if;
 perform 1 from public.profiles where id=b.profile_id and account_status='active' and deleted_at is null for update;
 if not found then raise exception 'inactive_account'; end if;
 if p_approve then
  if not exists(select 1 from public.identity_documents d join public.verification_requests r on r.document_id=d.id
   where d.owner_id=b.profile_id and d.status='approved' and d.document_type in ('thai_national_id','passport') and d.deleted_at is null
   and (d.expiry_date is null or d.expiry_date>=current_date) and r.status='approved' and r.reviewed_by<>b.profile_id
   and lower(regexp_replace(btrim(d.full_name),'\s+',' ','g'))=lower(regexp_replace(btrim(b.account_name),'\s+',' ','g')))
  then raise exception 'bank_verified_name_required'; end if;
  if b.evidence_path is distinct from b.profile_id::text||'/bank-account/'||b.id::text||'/evidence.jpg'
   or not exists(select 1 from storage.objects where bucket_id='identity-documents' and name=b.evidence_path and owner_id=b.profile_id::text)
   then raise exception 'document_files_missing'; end if;
  perform pg_advisory_xact_lock(hashtextextended(lower(btrim(b.bank_name))||':'||b.account_number,920));
  if exists(select 1 from public.bank_accounts x where x.profile_id<>b.profile_id and x.deleted_at is null and x.is_verified
   and lower(btrim(x.bank_name))=lower(btrim(b.bank_name)) and x.account_number=b.account_number)
   then raise exception 'bank_already_registered'; end if;
 end if;
 update public.bank_accounts set status=case when p_approve then 'verified' else 'rejected' end,
  is_verified=p_approve,verified_by=auth.uid(),verified_at=case when p_approve then now() else null end,updated_at=now() where id=b.id;
 update public.financial_verifications set status=result,name_match_status=case when p_approve then 'matched' else 'pending' end,
  verified_by=auth.uid(),verified_at=case when p_approve then now() else null end,notes=btrim(p_reason),updated_at=now() where id=f.id;
 update public.verifications set bank_status=case when p_approve then 'verified' else 'rejected' end where profile_id=b.profile_id;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description)
 values(auth.uid(),case when p_approve then 'kyc.bank.approve' else 'kyc.bank.reject' end,'bank_accounts',b.id,btrim(p_reason));
 return true;
end $$;
revoke all on function kaoid_private.review_bank_r9c(uuid,boolean,text) from public,anon;
grant execute on function kaoid_private.review_bank_r9c(uuid,boolean,text) to authenticated;

CREATE OR REPLACE FUNCTION kaoid_private.review_decision_r7c(p_request uuid, p_approve boolean, p_reason text)
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
     and x.owner_id<>d.owner_id and x.status='approved' and x.deleted_at is null)
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
 return true;
end $function$;

CREATE OR REPLACE FUNCTION kaoid_private.issue_kao_id_r7c(p_profile_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_existing text; v_status text; v_id text; i integer;
begin
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

CREATE OR REPLACE FUNCTION kaoid_private.can_read_evidence_r7c(p_path text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select kaoid_private.can_review_r7c() and (
 exists(select 1 from public.document_files f join public.identity_documents d on d.id=f.document_id
 join public.verification_requests r on r.document_id=d.id
 where f.file_path=p_path and d.document_type in ('thai_national_id','passport','residence_card') and d.deleted_at is null
 and d.owner_id=r.requested_by and d.owner_id<>auth.uid() and r.status in ('pending','under_review'))
 or exists(select 1 from public.bank_accounts b join public.financial_verifications f on f.bank_account_id=b.id
 where b.evidence_path=p_path and b.profile_id<>auth.uid() and b.profile_id=f.profile_id
 and b.organization_id is null and b.deleted_at is null and b.is_active and f.status='pending'));
$function$;

create or replace function kaoid_private.review_queue_r7c() returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
 select coalesce(jsonb_agg(to_jsonb(q)),'[]') into result from (
 select r.id,r.status,r.submitted_at,d.document_type,d.full_name,d.document_number,d.issued_date,d.expiry_date,
 d.issuing_country,d.residence_format,
 (select coalesce(jsonb_agg(f.file_path order by f.file_path),'[]') from public.document_files f where f.document_id=d.id) as paths,
 null::text bank_name,null::text identity_name
 from public.verification_requests r join public.identity_documents d on d.id=r.document_id
 where r.status in ('pending','under_review') and r.requested_by<>auth.uid() and d.owner_id=r.requested_by
 and d.document_type in ('thai_national_id','passport','residence_card') and d.deleted_at is null
 union all
 select f.id,f.status,f.created_at,'bank',b.account_name,b.account_number,null::date,null::date,
 null::text,null::text,jsonb_build_array(b.evidence_path),b.bank_name,
 (select d.full_name from public.identity_documents d join public.verification_requests r on r.document_id=d.id
 where d.owner_id=b.profile_id and d.document_type in ('thai_national_id','passport') and d.status='approved'
 and d.deleted_at is null and (d.expiry_date is null or d.expiry_date>=current_date) and r.status='approved'
 and r.reviewed_by<>b.profile_id order by d.verified_at desc limit 1)
 from public.financial_verifications f join public.bank_accounts b on b.id=f.bank_account_id
 where f.status='pending' and b.profile_id=f.profile_id and b.profile_id<>auth.uid()
 and b.organization_id is null and b.deleted_at is null and b.is_active and b.evidence_path is not null
 order by submitted_at,id limit 50)q;
 return result;
end $$;

CREATE OR REPLACE FUNCTION kaoid_private.list_banks_r8c()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid(); result jsonb;
begin
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false)
  or not exists(select 1 from public.profiles where id=u and account_status='active' and deleted_at is null) then
  raise exception 'authentication_required' using errcode='42501'; end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',b.id,'profile_id',b.profile_id,'bank_code',b.bank_code,'bank_name',b.bank_name,
  'account_name',b.account_name,'account_number','•••• '||right(b.account_number,4),
  'branch_name',b.branch_name,'account_type',b.account_type,'currency_code',b.currency_code,
  'status',case when b.status in ('rejected','expired') then b.status
    when f.status in ('rejected','expired') then f.status
    when b.is_verified and b.status='verified' and f.status='approved' and f.name_match_status='matched' then 'approved'
    when b.status in ('pending','manual_review') then b.status else 'unknown' end,
  'name_match_status',coalesce(f.name_match_status,'pending'),
  'is_verified',b.is_verified,'is_default',b.is_default,
  'verified_at',b.verified_at,'verified_by',b.verified_by,
  'review_events',(select coalesce(jsonb_agg(jsonb_build_object('id',a.id,'action',a.action,'notes',a.description,'created_at',a.created_at) order by a.created_at),'[]') from public.activity_logs a where a.target_table='bank_accounts' and a.target_id=b.id and a.action in ('kyc.bank.approve','kyc.bank.reject')),
  'evidence_path',b.evidence_path,'created_at',b.created_at,'updated_at',b.updated_at
 ) order by b.created_at desc,b.id), '[]'::jsonb) into result
 from public.bank_accounts b left join public.financial_verifications f on f.bank_account_id=b.id
 where b.profile_id=u and b.organization_id is null and b.is_active and b.deleted_at is null;
 return result;
end;
$function$;
;
