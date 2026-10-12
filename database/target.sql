CREATE OR REPLACE FUNCTION kaoid_private.review_target_base_r14b(p_target uuid)
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
 where r.id=p_target and r.status in ('pending','under_review') and r.requested_by<>auth.uid() and d.owner_id=r.requested_by
 and d.document_type in ('thai_national_id','passport','residence_card') and d.deleted_at is null
 union all
 select f.id,f.status,f.created_at,'bank',b.account_name,b.account_number,null::date,null::date,
 null::text,null::text,jsonb_build_array(b.evidence_path),b.bank_name,
 (select d.full_name from public.identity_documents d join public.verification_requests r on r.document_id=d.id
 where d.owner_id=b.profile_id and d.document_type in ('thai_national_id','passport') and d.status='approved'
 and d.deleted_at is null and (d.expiry_date is null or d.expiry_date>=current_date) and r.status='approved'
 and r.reviewed_by<>b.profile_id order by d.verified_at desc limit 1)
 from public.financial_verifications f join public.bank_accounts b on b.id=f.bank_account_id
 where f.id=p_target and f.status='pending' and b.profile_id=f.profile_id and b.profile_id<>auth.uid()
 and b.organization_id is null and b.deleted_at is null and b.is_active and b.evidence_path is not null
 order by submitted_at,id limit 50)q;
 return result;
end $function$
;
revoke all on function kaoid_private.review_target_base_r14b(uuid) from public,anon,authenticated;
create function kaoid_private.notice_target_r14b(p_notice uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare n public.notifications%rowtype; q jsonb; ar public.approval_requests%rowtype; e kaoid_private.recovery_evidence_r10e%rowtype; d public.identity_documents%rowtype;
begin
 if auth.uid() is null or not kaoid_private.account_active_r9f() then raise exception 'session_required' using errcode='42501';end if;
 select * into n from public.notifications where id=p_notice and profile_id=auth.uid() and not is_deleted and notification_type='kaoid';
 if not found then raise exception 'notice_unavailable' using errcode='42501';end if;
 if n.message in ('review_new','review_second','review_restart') then
  if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501';end if;
  q:=kaoid_private.review_target_base_r14b(n.target_id)->0;
  if q is null then return jsonb_build_object('kind','unavailable');end if;
  select * into ar from public.approval_requests where resource_id=n.target_id and resource in ('kaoid_review','kaoid_recovery') and status='pending' and expires_at>now();
  select * into e from kaoid_private.recovery_evidence_r10e where id=n.target_id;
  select * into d from public.identity_documents where id=e.previous_document;
  q:=q||jsonb_build_object('dual_review',(select dual_review from kaoid_private.security_policy_r14a where id),
   'first_reviewer',ar.requested_by,'first_reason',ar.reason,'first_decision',(select metadata->'approve' from public.approval_histories where approval_request_id=ar.id and event='request_created' limit 1),
   'is_recovery',e.id is not null,'previous_name',d.full_name,'previous_number',d.document_number,
   'previous_paths',(select coalesce(jsonb_agg(file_path),'[]') from public.document_files where document_id=e.previous_document));
  return jsonb_build_object('kind','review','row',q);
 elsif n.message in ('submitted','approved','rejected') then
  select jsonb_build_object('kind','result','status',status,'reason',rejection_reason) into q from public.verification_requests where id=n.target_id and requested_by=auth.uid();
 elsif n.message in ('bank_approved','bank_rejected') then
  select jsonb_build_object('kind','result','status',f.status,'reason',f.notes) into q from public.financial_verifications f join public.bank_accounts b on b.id=f.bank_account_id where b.id=n.target_id and f.profile_id=auth.uid() and b.profile_id=auth.uid() order by f.created_at desc limit 1;
 elsif n.message in ('role_assigned','role_revoked') then
  select jsonb_build_object('kind','role','role',r.code,'active',a.is_active and r.is_active and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now())) into q
  from public.admin_assignments a join public.admin_roles r on r.id=a.role_id where a.id=n.target_id and a.profile_id=auth.uid();
 end if;
 return coalesce(q,jsonb_build_object('kind','unavailable'));
end $$;
create function public.kaoid_notice_target_r14b(p_notice uuid) returns jsonb language sql security invoker set search_path='' as $$ select kaoid_private.notice_target_r14b(p_notice); $$;
revoke all on function public.kaoid_notice_target_r14b(uuid),kaoid_private.notice_target_r14b(uuid) from public,anon;
grant execute on function public.kaoid_notice_target_r14b(uuid),kaoid_private.notice_target_r14b(uuid) to authenticated;
