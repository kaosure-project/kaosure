-- Recovery reuses verification_requests and the existing review rules.
create table kaoid_private.recovery_evidence_r10e(
 id uuid primary key default gen_random_uuid(),
 lifecycle_id uuid not null unique references kaoid_private.lifecycle_requests_r10b(id),
 profile_id uuid not null references public.profiles(id),
 document_type text not null check(document_type in ('thai_national_id','passport')),
 previous_document uuid references public.identity_documents(id),
 status text not null default 'draft' check(status in ('draft','submitted','approved','rejected','cancelled')),
 created_at timestamptz not null default now());
alter table kaoid_private.recovery_evidence_r10e enable row level security;
revoke all on kaoid_private.recovery_evidence_r10e from public,anon,authenticated;
create table kaoid_private.recovery_writes_r10e(tx bigint not null,profile_id uuid not null,document_id uuid not null,primary key(tx,profile_id));
alter table kaoid_private.recovery_writes_r10e enable row level security;
revoke all on kaoid_private.recovery_writes_r10e from public,anon,authenticated;

create function kaoid_private.recovery_paths_r10e(u uuid,d uuid,t text) returns text[] language sql immutable set search_path='' as $$
 select case when t='passport' then array[u::text||'/passport/'||d::text||'/data.jpg']
 else array[u::text||'/national-id/'||d::text||'/front.jpg',u::text||'/national-id/'||d::text||'/back.jpg'] end;
$$;
revoke all on function kaoid_private.recovery_paths_r10e(uuid,uuid,text) from public,anon,authenticated;
create function kaoid_private.recovery_storage_r10e(p_path text,p_write boolean) returns boolean language sql stable security definer set search_path='' as $$
 select not coalesce((auth.jwt()->>'is_anonymous')::boolean,false)
 and kaoid_private.account_access_r10d()->>'state'='closed'
 and exists(select 1 from kaoid_private.recovery_evidence_r10e e join kaoid_private.lifecycle_requests_r10b l on l.id=e.lifecycle_id
 where e.profile_id=auth.uid() and l.profile_id=auth.uid() and l.status='pending' and l.kind='recovery'
 and e.status in ('draft','submitted') and (not p_write or e.status='draft')
 and p_path=any(kaoid_private.recovery_paths_r10e(e.profile_id,e.id,e.document_type)));
$$;
revoke all on function kaoid_private.recovery_storage_r10e(text,boolean) from public,anon;
grant execute on function kaoid_private.recovery_storage_r10e(text,boolean) to authenticated;
-- Existing permissive owner policies still require Storage owner_id to match.
alter policy account_closure_r10d on storage.objects
 using(kaoid_private.data_access_r10d() or (bucket_id='identity-documents' and kaoid_private.recovery_storage_r10e(name,false)))
 with check(kaoid_private.data_access_r10d() or (bucket_id='identity-documents' and kaoid_private.recovery_storage_r10e(name,true)));
alter policy restricted_kyc_storage_r9f on storage.objects
 using(bucket_id<>'identity-documents' or kaoid_private.account_active_r9f() or kaoid_private.recovery_storage_r10e(name,false))
 with check(bucket_id<>'identity-documents' or kaoid_private.account_active_r9f() or kaoid_private.recovery_storage_r10e(name,true));

create function kaoid_private.prepare_recovery_r10e(p_lifecycle uuid,p_type text) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();e kaoid_private.recovery_evidence_r10e%rowtype;old_id uuid;
begin
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) or kaoid_private.account_access_r10d()->>'state'<>'closed' then raise exception 'recovery_access_required' using errcode='42501';end if;
 perform 1 from public.profiles where id=u and account_status='closed' and deleted_at is null for update;
 if not found then raise exception 'account_unavailable';end if;
 perform 1 from kaoid_private.lifecycle_requests_r10b where id=p_lifecycle and profile_id=u and kind='recovery' and status='pending' for update;
 if not found or p_type is null or p_type not in ('thai_national_id','passport') then raise exception 'recovery_request_required';end if;
 select * into e from kaoid_private.recovery_evidence_r10e where lifecycle_id=p_lifecycle;
 if found then
  if e.document_type<>p_type then raise exception 'recovery_type_locked';end if;
 else
  if exists(select 1 from public.verification_requests where requested_by=u and status in ('pending','under_review')) then raise exception 'review_already_active';end if;
  select d.id into old_id from public.identity_documents d join public.verification_requests r on r.document_id=d.id
  where d.owner_id=u and d.document_type in ('thai_national_id','passport') and d.status='approved' and d.deleted_at is null
   and r.status='approved' and r.reviewed_by is not null and r.reviewed_by<>u order by d.verified_at desc nulls last,d.created_at desc limit 1;
  if exists(select 1 from public.kao_id_identities where profile_id=u and identity_type='personal') and old_id is null then raise exception 'recovery_history_required';end if;
  insert into kaoid_private.recovery_evidence_r10e(lifecycle_id,profile_id,document_type,previous_document) values(p_lifecycle,u,p_type,old_id) returning * into e;
 end if;
 return jsonb_build_object('id',e.id,'document_type',e.document_type,'status',e.status,'paths',kaoid_private.recovery_paths_r10e(u,e.id,e.document_type));
end $$;

create or replace function kaoid_private.guard_account_write_r9f() returns trigger language plpgsql security definer set search_path='' as $$
declare doc uuid;j jsonb;
begin
 if auth.uid() is not null and exists(select 1 from public.profiles where id=auth.uid() and (account_status<>'active' or deleted_at is not null)) then
  if tg_op<>'DELETE' then
   j:=to_jsonb(new);doc:=case when tg_table_name='identity_documents' then (j->>'id')::uuid else (j->>'document_id')::uuid end;
   if kaoid_private.account_access_r10d()->>'state'='closed'
    and ((tg_op='INSERT' and tg_table_name in ('identity_documents','document_files','verification_requests'))
      or (tg_op='UPDATE' and tg_table_name='verification_requests' and j->>'status'='cancelled'))
    and exists(select 1 from kaoid_private.recovery_writes_r10e where tx=txid_current() and profile_id=auth.uid() and document_id=doc)
    then return new;end if;
  end if;
  raise exception 'account_restricted' using errcode='42501';
 end if;
 if tg_op='DELETE' then return old;end if;return new;
end $$;

create function kaoid_private.submit_recovery_r10e(p_id uuid,p_data jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();e kaoid_private.recovery_evidence_r10e%rowtype;j jsonb:=p_data;paths text[];path text;o storage.objects%rowtype;
 num text:=btrim(j->>'number');given text:=btrim(j->>'given');family text:=btrim(coalesce(j->>'family',''));v_single boolean:=(j->>'single')::boolean;
 birth date:=(j->>'birth')::date;issued date:=(j->>'issued')::date;expiry date:=(j->>'expiry')::date;fullname text;
begin
 if kaoid_private.account_access_r10d()->>'state'<>'closed' or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'recovery_access_required' using errcode='42501';end if;
 perform 1 from public.profiles where id=u and account_status='closed' and deleted_at is null for update;
 if not found then raise exception 'account_unavailable';end if;
 select * into e from kaoid_private.recovery_evidence_r10e where id=p_id and profile_id=u for update;
 if not found then raise exception 'recovery_request_required';end if;
 perform 1 from kaoid_private.lifecycle_requests_r10b where id=e.lifecycle_id and profile_id=u and status='pending' and kind='recovery' for update;
 if not found then raise exception 'recovery_request_required';end if;
 if e.status='submitted' then
  if exists(select 1 from public.identity_documents d where d.id=e.id and d.document_number=num and d.given_names=given and d.family_name=family and d.single_name=v_single and d.date_of_birth=birth and d.issued_date=issued and d.expiry_date is not distinct from expiry and d.family_name_first=coalesce((j->>'family_first')::boolean,false) and (e.document_type<>'passport' or d.issuing_country=btrim(j->>'country'))) then return e.id;end if;
  raise exception 'document_conflict';end if;
 if e.status<>'draft' then raise exception 'request_already_processed';end if;
 if num is null or length(num) not between 1 and 30 or num~'[[:cntrl:]]'
 or given is null or length(given) not between 1 and 100 or length(family)>100
 or v_single is null or (v_single and family<>'') or (not v_single and family='')
 or birth is null or birth<date '1900-01-01' or birth>current_date
 or issued is null or issued>current_date or issued<birth
 or (e.document_type='passport' and expiry is null) or (expiry is not null and (expiry<current_date or expiry<=issued))
 or (e.document_type='thai_national_id' and num!~'^[0-9]{13}$')
 or (e.document_type='passport' and length(btrim(coalesce(j->>'country',''))) not between 2 and 100)
 then raise exception 'invalid_recovery_document' using errcode='22023';end if;
 if exists(select 1 from public.verification_requests where requested_by=u and status in ('pending','under_review')) then raise exception 'review_already_active';end if;
 paths:=kaoid_private.recovery_paths_r10e(u,e.id,e.document_type);
 foreach path in array paths loop
  select * into o from storage.objects where bucket_id='identity-documents' and name=path for update;
  if not found or o.owner_id is distinct from u::text or coalesce((o.metadata->>'size')::bigint,0) not between 1 and 10485760 or o.metadata->>'mimetype' is distinct from 'image/jpeg' then raise exception 'invalid_uploaded_file';end if;
 end loop;
 fullname:=case when v_single then given when coalesce((j->>'family_first')::boolean,false) then family||' '||given else given||' '||family end;
 insert into kaoid_private.recovery_writes_r10e values(txid_current(),u,e.id);
 insert into public.identity_documents(id,owner_id,document_type,document_number,full_name,given_names,family_name,single_name,family_name_first,issuing_country,country_code,date_of_birth,issued_date,expiry_date,status,file_path)
 values(e.id,u,e.document_type,num,fullname,given,family,v_single,coalesce((j->>'family_first')::boolean,false),case when e.document_type='thai_national_id' then 'TH' else btrim(j->>'country') end,case when e.document_type='thai_national_id' then 'TH' else null end,birth,issued,expiry,'pending_review',paths[1]);
 insert into public.document_files(document_id,file_path,file_name,mime_type,file_size)
 select e.id,name,split_part(name,'/',4),'image/jpeg',(metadata->>'size')::bigint from storage.objects where bucket_id='identity-documents' and name=any(paths);
 insert into public.verification_requests(id,document_id,requested_by,status) values(e.id,e.id,u,'pending');
 delete from kaoid_private.recovery_writes_r10e where tx=txid_current() and profile_id=u;
 update kaoid_private.recovery_evidence_r10e set status='submitted' where id=e.id;
 return e.id;
end $$;

create function kaoid_private.recovery_snapshot_r10e() returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or kaoid_private.account_access_r10d()->>'state' not in ('closed','active') or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'recovery_access_required' using errcode='42501';end if;
 return (select coalesce(jsonb_agg(jsonb_build_object('id',e.id,'lifecycle_id',e.lifecycle_id,'document_type',e.document_type,'status',e.status,'paths',kaoid_private.recovery_paths_r10e(e.profile_id,e.id,e.document_type),'reason',r.rejection_reason) order by e.created_at desc),'[]') from kaoid_private.recovery_evidence_r10e e left join public.verification_requests r on r.id=e.id where e.profile_id=auth.uid());
end $$;

-- Retain the current review engine, including duplicate identity and file checks.
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
end $function$

;
revoke all on function kaoid_private.review_decision_base_r10e(uuid,boolean,text) from public,anon,authenticated;
create or replace function kaoid_private.review_decision_r7c(p_request uuid,p_approve boolean,p_reason text) returns boolean language plpgsql security definer set search_path='' as $$
begin
 if exists(select 1 from kaoid_private.recovery_evidence_r10e where id=p_request) then raise exception 'recovery_confirmation_required';end if;
 return kaoid_private.review_decision_base_r10e(p_request,p_approve,p_reason);
end $$;
create function kaoid_private.review_recovery_r10e(p_request uuid,p_approve boolean,p_reason text,p_confirm boolean) returns boolean language plpgsql security definer set search_path='' as $$
declare e kaoid_private.recovery_evidence_r10e%rowtype;s text;u uuid;
begin
 if not kaoid_private.can_review_r7c() or not kaoid_private.data_access_r10d() then raise exception 'reviewer_required' using errcode='42501';end if;
 if p_approve is null or length(btrim(coalesce(p_reason,''))) not between 3 and 1000 or (p_approve and p_confirm is distinct from true) then raise exception 'recovery_confirmation_required';end if;
 select profile_id into u from kaoid_private.recovery_evidence_r10e where id=p_request;
 if u is null or u=auth.uid() then raise exception 'request_not_available' using errcode='42501';end if;
 perform 1 from public.profiles where id=u for update;
 select * into e from kaoid_private.recovery_evidence_r10e where id=p_request for update;
 s:=case when p_approve then 'approved' else 'rejected' end;
 if e.status=s and exists(select 1 from public.verification_requests where id=p_request and reviewed_by=auth.uid() and status=s) then return true;end if;
 if e.status<>'submitted' then raise exception 'request_already_processed';end if;
 perform 1 from kaoid_private.lifecycle_requests_r10b where id=e.lifecycle_id and profile_id=u and kind='recovery' and status='pending' for update;
 if not found or not exists(select 1 from public.profiles where id=u and account_status='closed' and deleted_at is null)
 or not exists(select 1 from kaoid_private.account_closures_r10d where profile_id=u) then raise exception 'recovery_request_required';end if;
 if exists(select 1 from public.kao_id_identities where profile_id=u and identity_type='personal' and status<>'closed') then raise exception 'identity_state_changed';end if;
 if exists(select 1 from public.kao_id_identities where profile_id=u and identity_type='personal') and not exists(
 select 1 from public.identity_documents d join public.verification_requests r on r.document_id=d.id where d.id=e.previous_document and d.owner_id=u and d.status='approved' and d.deleted_at is null and r.status='approved' and r.reviewed_by<>u) then raise exception 'recovery_history_required';end if;
 if p_approve and e.previous_document is not null then
  if not exists(select 1 from public.document_files where document_id=e.previous_document)
  or exists(select 1 from public.document_files f where f.document_id=e.previous_document and not exists(select 1 from storage.objects o where o.bucket_id='identity-documents' and o.name=f.file_path and o.owner_id=u::text)) then raise exception 'recovery_history_required';end if;
 end if;
 -- Intermediate active status is transaction-local: any failure rolls everything back.
 update public.profiles set account_status='active',updated_at=now() where id=u;
 perform kaoid_private.review_decision_base_r10e(e.id,p_approve,p_reason);
 if p_approve then
  update public.kao_id_identities set status='active',updated_at=now() where profile_id=u and identity_type='personal' and status='closed';
 else
  update public.profiles set account_status='closed',updated_at=now() where id=u;
 end if;
 update kaoid_private.recovery_evidence_r10e set status=s where id=e.id;
 update kaoid_private.lifecycle_requests_r10b set status=s,updated_at=now() where id=e.lifecycle_id;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description) values(auth.uid(),case when p_approve then 'account.request.recover' else 'account.request.reject' end,'lifecycle_requests_r10b',e.lifecycle_id,btrim(p_reason));
 perform kaoid_private.emit_notice_r10a(u,'recovery-result:'||e.id,case when p_approve then 'account_recovered' else 'lifecycle_rejected' end,e.lifecycle_id);
 return true;
end $$;
create function kaoid_private.cancel_recovery_r10e() returns trigger language plpgsql security definer set search_path='' as $$
declare e kaoid_private.recovery_evidence_r10e%rowtype;
begin
 if new.kind='recovery' and old.status='pending' and new.status in ('cancelled','rejected') then
  select * into e from kaoid_private.recovery_evidence_r10e where lifecycle_id=new.id for update;
  if found and e.status in ('draft','submitted') then
   insert into kaoid_private.recovery_writes_r10e values(txid_current(),e.profile_id,e.id);
   update public.verification_requests set status='cancelled',updated_at=now() where id=e.id and status in ('pending','under_review');
   delete from kaoid_private.recovery_writes_r10e where tx=txid_current() and profile_id=e.profile_id;
   update kaoid_private.recovery_evidence_r10e set status='cancelled' where id=e.id;
  end if;
 end if;return new;
end $$;
create trigger cancel_recovery_r10e after update on kaoid_private.lifecycle_requests_r10b for each row execute function kaoid_private.cancel_recovery_r10e();
revoke all on function kaoid_private.cancel_recovery_r10e() from public,anon,authenticated;
CREATE OR REPLACE FUNCTION kaoid_private.review_queue_base_r10e()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
end $function$

;
revoke all on function kaoid_private.review_queue_base_r10e() from public,anon,authenticated;
create or replace function kaoid_private.review_queue_r7c() returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501';end if;
 return (select coalesce(jsonb_agg(q || jsonb_build_object('is_recovery',e.id is not null,'previous_name',d.full_name,'previous_number',d.document_number,'previous_paths',(select coalesce(jsonb_agg(f.file_path),'[]') from public.document_files f where f.document_id=e.previous_document)) order by ord),'[]')
 from jsonb_array_elements(kaoid_private.review_queue_base_r10e()) with ordinality a(q,ord)
 left join kaoid_private.recovery_evidence_r10e e on e.id=(q->>'id')::uuid
 left join public.identity_documents d on d.id=e.previous_document);
end $$;
CREATE OR REPLACE FUNCTION kaoid_private.can_read_evidence_base_r10e(p_path text)
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
$function$

;
revoke all on function kaoid_private.can_read_evidence_base_r10e(text) from public,anon,authenticated;
create or replace function kaoid_private.can_read_evidence_r7c(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select kaoid_private.can_read_evidence_base_r10e(p_path) or (kaoid_private.can_review_r7c() and exists(
 select 1 from kaoid_private.recovery_evidence_r10e e join kaoid_private.lifecycle_requests_r10b l on l.id=e.lifecycle_id join public.document_files f on f.document_id=e.previous_document
 where f.file_path=p_path and e.status='submitted' and l.status='pending' and e.profile_id<>auth.uid()));
$$;
CREATE OR REPLACE FUNCTION kaoid_private.pre_request_r10d()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare st text; path text:=trim(both '/' from coalesce(current_setting('request.path',true),''));
begin
 if auth.uid() is null then return;end if;
 -- Minimal status is safe even when the caller's old Auth session has been revoked.
 if path='rpc/account_access_r10d' then return;end if;
 st:=kaoid_private.account_access_r10d()->>'state';
 if st='session_revoked' then raise exception 'account_session_revoked' using errcode='42501';end if;
 if st='closed' and path not in ('rpc/lifecycle_snapshot_r10b','rpc/lifecycle_submit_r10b','rpc/lifecycle_cancel_r10b','rpc/prepare_recovery_r10e','rpc/submit_recovery_r10e','rpc/recovery_snapshot_r10e') then
  raise exception 'account_closed' using errcode='42501';end if;
end $function$

;
create function public.prepare_recovery_r10e(p_lifecycle uuid,p_type text) returns jsonb language sql security invoker set search_path='' as $$ select kaoid_private.prepare_recovery_r10e(p_lifecycle,p_type); $$;
revoke all on function public.prepare_recovery_r10e(uuid,text),kaoid_private.prepare_recovery_r10e(uuid,text) from public,anon;
grant execute on function public.prepare_recovery_r10e(uuid,text),kaoid_private.prepare_recovery_r10e(uuid,text) to authenticated;
create function public.submit_recovery_r10e(p_id uuid,p_data jsonb) returns uuid language sql security invoker set search_path='' as $$ select kaoid_private.submit_recovery_r10e(p_id,p_data); $$;
revoke all on function public.submit_recovery_r10e(uuid,jsonb),kaoid_private.submit_recovery_r10e(uuid,jsonb) from public,anon;
grant execute on function public.submit_recovery_r10e(uuid,jsonb),kaoid_private.submit_recovery_r10e(uuid,jsonb) to authenticated;
create function public.recovery_snapshot_r10e() returns jsonb language sql security invoker set search_path='' as $$ select kaoid_private.recovery_snapshot_r10e(); $$;
revoke all on function public.recovery_snapshot_r10e(),kaoid_private.recovery_snapshot_r10e() from public,anon;
grant execute on function public.recovery_snapshot_r10e(),kaoid_private.recovery_snapshot_r10e() to authenticated;
create function public.review_recovery_r10e(p_request uuid,p_approve boolean,p_reason text,p_confirm boolean) returns boolean language sql security invoker set search_path='' as $$ select kaoid_private.review_recovery_r10e(p_request,p_approve,p_reason,p_confirm); $$;
revoke all on function public.review_recovery_r10e(uuid,boolean,text,boolean),kaoid_private.review_recovery_r10e(uuid,boolean,text,boolean) from public,anon;
grant execute on function public.review_recovery_r10e(uuid,boolean,text,boolean),kaoid_private.review_recovery_r10e(uuid,boolean,text,boolean) to authenticated;
notify pgrst,'reload schema';

create or replace function kaoid_private.close_account_r10d(p_request uuid,p_reason text) returns boolean language plpgsql security definer set search_path='' as $$
declare r kaoid_private.lifecycle_requests_r10b%rowtype; u uuid; blockers jsonb; t text;
begin
 if not kaoid_private.data_access_r10d() or not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501';end if;
 if length(btrim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'invalid_reason';end if;
 select profile_id into u from kaoid_private.lifecycle_requests_r10b where id=p_request;
 if u is null or u=auth.uid() or exists(select 1 from public.company_owners where profile_id=u) then raise exception 'request_unavailable' using errcode='42501';end if;
 -- Short, bounded write barrier prevents service records arriving between checks and closure.
 foreach t in array array['orders','order_items','disputes','withdraw_requests','refund_requests','return_requests','cancel_requests','shops','organization_members','organization_delegations','business_registrations','approval_requests','api_keys','oauth_clients','commission','tax_records','invoice','receipt','wallets','wallet_transactions','payment_transactions','escrow_transactions'] loop
 execute format('lock table public.%I in share row exclusive mode',t);
 end loop;
 perform 1 from public.profiles where id=u for update;
 select * into r from kaoid_private.lifecycle_requests_r10b where id=p_request for update;
 if r.kind<>'closure' then raise exception 'closure_request_required';end if;
 if exists(select 1 from kaoid_private.account_closures_r10d where request_id=p_request) and r.status='approved' then return true;end if;
 if r.status<>'pending' then raise exception 'request_already_processed';end if;
 blockers:=kaoid_private.closure_blockers_r10d(u);
 if jsonb_array_length(blockers)>0 then raise exception 'closure_obligations_require_review';end if;
 insert into kaoid_private.account_closures_r10d(profile_id,request_id,closed_by,reason,prior_access) select u,p_request,auth.uid(),btrim(p_reason),jsonb_build_object('role',role,'seller_level',seller_level,'is_seller',is_seller) from public.profiles where id=u on conflict(profile_id) do update set request_id=excluded.request_id,closed_at=clock_timestamp(),closed_by=excluded.closed_by,reason=excluded.reason,prior_access=excluded.prior_access;
 update public.admin_assignments set is_active=false,updated_at=now() where profile_id=u and is_active;
 update public.owner_delegations set revoked_at=now(),revoked_by=auth.uid(),updated_at=now() where delegate_profile_id=u and revoked_at is null;
 update public.shop_staff set is_active=false,updated_at=now() where profile_id=u and is_active;
 update public.oauth_tokens set revoked_at=now(),revoked_by=auth.uid(),revoke_reason='account_closed',updated_at=now() where profile_id=u and revoked_at is null;
 update public.sessions set revoked_at=now(),logout_at=now(),logout_reason='account_closed',is_current=false,updated_at=now() where profile_id=u and revoked_at is null;
 update public.admin_sessions set is_active=false,terminated_at=now(),terminated_by=auth.uid(),termination_reason='account_closed',updated_at=now() where profile_id=u and is_active;
 update public.verification_requests set status='cancelled',updated_at=now() where requested_by=u and status in ('pending','under_review');
 update public.kao_id_identities set status='closed',updated_at=now() where profile_id=u and identity_type='personal';
 update public.profiles set account_status='closed',role='user',seller_level='standard',is_seller=false,updated_at=now() where id=u;
 update kaoid_private.lifecycle_requests_r10b set status='approved',updated_at=now() where id=p_request;
 -- Auth refresh tokens reference sessions with ON DELETE CASCADE; remove legacy tokens too.
 delete from auth.refresh_tokens where user_id=u::text;
 delete from auth.sessions where user_id=u;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description) values(auth.uid(),'account.request.close','lifecycle_requests_r10b',p_request,btrim(p_reason));
 perform kaoid_private.emit_notice_r10a(u,'account-closed:'||p_request,'account_closed',p_request);
 return true;
end $$;

create or replace function kaoid_private.lifecycle_snapshot_r10b() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();s text;
begin
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'authentication_required' using errcode='42501';end if;
 if kaoid_private.account_access_r10d()->>'state'='session_revoked' then raise exception 'account_session_revoked' using errcode='42501';end if;
 select account_status into s from public.profiles where id=u and deleted_at is null;
 if s is null then raise exception 'account_unavailable';end if;
 return jsonb_build_object('account_status',s,'owner',exists(select 1 from public.company_owners where profile_id=u),
 'requests',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (select r.id,r.kind,r.status,r.reason,r.created_at,(select a.description from public.activity_logs a where a.target_table='lifecycle_requests_r10b' and a.target_id=r.id and a.action in ('account.request.reject','account.request.close','account.request.recover') order by a.created_at desc,a.id desc limit 1) as decision_reason from kaoid_private.lifecycle_requests_r10b r where r.profile_id=u order by r.created_at desc,r.id desc limit 20)x));
end $$;