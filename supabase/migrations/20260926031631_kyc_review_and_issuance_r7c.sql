-- Protect authority-bearing profile fields while retaining normal profile edits.
revoke update on public.profiles from authenticated, anon;
grant update(display_name,avatar_url,bio,language_code,first_name,last_name,country_code,timezone,username) on public.profiles to authenticated;
create or replace function kaoid_private.guard_profile_role_r7c()
returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if current_user in ('authenticated','anon') and new.role is distinct from 'user' then
  raise exception 'role_assignment_requires_administrator' using errcode='42501';
 end if;
 return new;
end $$;
revoke all on function kaoid_private.guard_profile_role_r7c() from public,anon,authenticated;
create trigger guard_profile_role_r7c before insert on public.profiles
for each row execute function kaoid_private.guard_profile_role_r7c();

create or replace function kaoid_private.can_review_r7c()
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false)
 and exists(select 1 from public.profiles p where p.id=auth.uid() and p.account_status='active' and p.deleted_at is null
 and exists(
 select 1 from public.admin_assignments a join public.admin_roles r on r.id=a.role_id
 where a.profile_id=p.id and a.is_active and r.is_active and r.code='kyc_officer'
 and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now())));
$$;
revoke all on function kaoid_private.can_review_r7c() from public,anon;
grant execute on function kaoid_private.can_review_r7c() to authenticated;
create or replace function public.can_review_kyc_r7c() returns boolean
language sql stable security invoker set search_path='' as $$ select kaoid_private.can_review_r7c(); $$;
revoke all on function public.can_review_kyc_r7c() from public,anon;
grant execute on function public.can_review_kyc_r7c() to authenticated;

create or replace function kaoid_private.review_queue_r7c()
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_result jsonb;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
 select coalesce(jsonb_agg(to_jsonb(q)),'[]'::jsonb) into v_result from (
 select r.id,r.status,r.submitted_at,d.full_name,d.document_number,d.issued_date,d.expiry_date,
 (select coalesce(jsonb_agg(f.file_path order by f.file_path),'[]'::jsonb) from public.document_files f where f.document_id=d.id) as paths
 from public.verification_requests r join public.identity_documents d on d.id=r.document_id
 where r.status in ('pending','under_review') and r.requested_by<>auth.uid()
 and d.owner_id=r.requested_by and d.document_type='thai_national_id' and d.deleted_at is null
 order by r.submitted_at,r.id limit 50)q;
 return v_result;
end $$;
revoke all on function kaoid_private.review_queue_r7c() from public,anon;
grant execute on function kaoid_private.review_queue_r7c() to authenticated;
create or replace function public.kyc_review_queue_r7c() returns jsonb
language sql security invoker set search_path='' as $$ select kaoid_private.review_queue_r7c(); $$;
revoke all on function public.kyc_review_queue_r7c() from public,anon;
grant execute on function public.kyc_review_queue_r7c() to authenticated;

create or replace function kaoid_private.review_decision_r7c(p_request uuid,p_approve boolean,p_reason text)
returns boolean language plpgsql security definer set search_path='' as $$
declare r public.verification_requests%rowtype; d public.identity_documents%rowtype; v_status text;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
 if p_approve is null or length(coalesce(p_reason,''))>1000 or (not p_approve and length(btrim(coalesce(p_reason,'')))<3) then
  raise exception 'invalid_decision' using errcode='22023'; end if;
 select * into r from public.verification_requests where id=p_request for update;
 if not found or r.requested_by=auth.uid() then raise exception 'request_not_available' using errcode='42501'; end if;
 v_status:=case when p_approve then 'approved' else 'rejected' end;
 if r.status=v_status and r.reviewed_by=auth.uid() then return true; end if;
 if r.status not in ('pending','under_review') then raise exception 'request_already_reviewed' using errcode='55000'; end if;
 select * into d from public.identity_documents where id=r.document_id for update;
 if not found or d.owner_id<>r.requested_by or d.document_type<>'thai_national_id' or d.deleted_at is not null then
  raise exception 'invalid_document' using errcode='22023'; end if;
 perform 1 from public.profiles where id=r.requested_by and account_status='active' and deleted_at is null for update;
 if not found then raise exception 'inactive_account' using errcode='42501'; end if;
 perform 1 from public.verifications where profile_id=r.requested_by for update;
 if not found then raise exception 'verification_record_missing' using errcode='55000'; end if;
 if p_approve then
  if d.status<>'pending_review' or d.full_name is null or d.document_number !~ '^[0-9]{13}$'
  or (d.expiry_date is not null and d.expiry_date<current_date) then raise exception 'document_not_ready' using errcode='22023'; end if;
  if (select count(*) from public.document_files f join storage.objects o on o.bucket_id='identity-documents' and o.name=f.file_path
      where f.document_id=d.id and o.owner_id=d.owner_id::text
      and f.file_path in (d.owner_id::text||'/national-id/'||d.id::text||'/front.jpg',d.owner_id::text||'/national-id/'||d.id::text||'/back.jpg'))<>2 then
   raise exception 'document_files_missing' using errcode='22023'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(d.document_number,715));
  if exists(select 1 from public.identity_documents x where x.document_type='thai_national_id' and x.document_number=d.document_number
     and x.owner_id<>d.owner_id and x.status='approved' and x.deleted_at is null) then
   raise exception 'identity_already_registered' using errcode='23505'; end if;
 end if;
 update public.identity_documents set status=v_status,verified_by=auth.uid(),
  verified_at=case when p_approve then now() else null end,
  rejected_reason=case when p_approve then null else btrim(p_reason) end where id=d.id;
 update public.verification_requests set status=v_status,reviewed_at=now(),reviewed_by=auth.uid(),
  rejection_reason=case when p_approve then null else btrim(p_reason) end,notes=p_reason where id=r.id;
 update public.verifications set identity_card_status=case when p_approve then 'verified' else 'rejected' end,
  status=v_status,account_level=case when p_approve then 'verified' else 'registered' end,
  identity_expiry=d.expiry_date,last_reviewed_by=auth.uid(),
  last_verified_at=case when p_approve then now() else last_verified_at end,
  rejected_reason=case when p_approve then null else btrim(p_reason) end where profile_id=r.requested_by;
 insert into public.verification_logs(verification_request_id,action,old_status,new_status,performed_by,notes)
 values(r.id,case when p_approve then 'approve' else 'reject' end,r.status,v_status,auth.uid(),p_reason);
 return true;
end $$;
revoke all on function kaoid_private.review_decision_r7c(uuid,boolean,text) from public,anon;
grant execute on function kaoid_private.review_decision_r7c(uuid,boolean,text) to authenticated;
create or replace function public.kyc_review_decision_r7c(p_request uuid,p_approve boolean,p_reason text default null)
returns boolean language sql security invoker set search_path='' as $$ select kaoid_private.review_decision_r7c(p_request,p_approve,p_reason); $$;
revoke all on function public.kyc_review_decision_r7c(uuid,boolean,text) from public,anon;
grant execute on function public.kyc_review_decision_r7c(uuid,boolean,text) to authenticated;
-- Preserve the old API signature, close its incomplete/self-approval path.
create or replace function public.approve_kyc_verification(p_verification_request_id uuid,p_reviewer_id uuid,p_notes text default null)
returns boolean language plpgsql security invoker set search_path='' as $$
begin
 if p_reviewer_id is distinct from auth.uid() then raise exception 'reviewer_mismatch' using errcode='42501'; end if;
 return kaoid_private.review_decision_r7c(p_verification_request_id,true,p_notes);
end $$;
revoke all on function public.approve_kyc_verification(uuid,uuid,text) from public,anon;

create or replace function kaoid_private.issue_kao_id_r7c(p_profile_id uuid)
returns text language plpgsql security definer set search_path='' as $$
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
  where d.owner_id=p_profile_id and d.document_type='thai_national_id' and d.status='approved' and d.deleted_at is null
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
end $$;
revoke all on function kaoid_private.issue_kao_id_r7c(uuid) from public,anon;
grant execute on function kaoid_private.issue_kao_id_r7c(uuid) to authenticated;
create or replace function public.issue_kao_id(p_profile_id uuid) returns text
language sql security invoker set search_path='' as $$ select kaoid_private.issue_kao_id_r7c(p_profile_id); $$;
revoke all on function public.issue_kao_id(uuid) from public,anon;
grant execute on function public.issue_kao_id(uuid) to authenticated;
grant select on public.kao_id_identities to authenticated;

-- Reviewer downloads require a live server-side role and a pending request.
create or replace function kaoid_private.can_read_evidence_r7c(p_path text)
returns boolean language sql stable security definer set search_path='' as $$
 select kaoid_private.can_review_r7c() and exists(
 select 1 from public.document_files f join public.identity_documents d on d.id=f.document_id
 join public.verification_requests r on r.document_id=d.id
 where f.file_path=p_path and d.document_type='thai_national_id' and d.deleted_at is null
 and d.owner_id=r.requested_by and d.owner_id<>auth.uid() and r.status in ('pending','under_review'));
$$;
revoke all on function kaoid_private.can_read_evidence_r7c(text) from public,anon;
grant execute on function kaoid_private.can_read_evidence_r7c(text) to authenticated;
create policy national_id_reviewer_read_r7c on storage.objects for select to authenticated
using(bucket_id='identity-documents' and kaoid_private.can_read_evidence_r7c(name));
;
