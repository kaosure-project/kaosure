insert into public.approval_policies(code,name,resource,action,minimum_approvals,is_active,is_immutable)
values('kaoid_two_person_r14a','Kao ID independent review','kaoid_review','decide',2,true,true)
on conflict(code) do nothing;
create unique index kaoid_pending_review_r14a on public.approval_requests(resource,resource_id)
where resource in ('kaoid_review','kaoid_recovery') and status='pending';
create function kaoid_private.review_fingerprint_r14a(p_id uuid) returns text language sql stable security definer set search_path='' as $$
 select encode(sha256(convert_to(jsonb_build_object(
 'request',(select to_jsonb(r) from public.verification_requests r where r.id=p_id),
 'document',(select to_jsonb(d) from public.identity_documents d join public.verification_requests r on r.document_id=d.id where r.id=p_id),
 'files',(select jsonb_agg(to_jsonb(f) order by f.id) from public.document_files f join public.verification_requests r on r.document_id=f.document_id where r.id=p_id),
 'bank_check',(select to_jsonb(v) from public.financial_verifications v where v.id=p_id),
 'bank',(select to_jsonb(b) from public.bank_accounts b join public.financial_verifications v on v.bank_account_id=b.id where v.id=p_id),
 'recovery',(select to_jsonb(e) from kaoid_private.recovery_evidence_r10e e where e.id=p_id)
 )::text,'UTF8')),'hex'); $$;
create function kaoid_private.review_vote_r14a(p_id uuid,p_approve boolean,p_reason text,p_recovery boolean) returns boolean language plpgsql security definer set search_path='' as $$
declare target uuid; ar public.approval_requests%rowtype; meta jsonb; rid uuid; sid uuid; fingerprint text; kind text; first_ok boolean;begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501';end if;
 perform kaoid_private.require_fresh_mfa_r14a();
 if not (select dual_review from kaoid_private.security_policy_r14a where id) then return true;end if;
 if p_approve is null or length(coalesce(p_reason,''))>1000 or (not p_approve and length(btrim(coalesce(p_reason,'')))<3) then raise exception 'invalid_decision';end if;
 select requested_by into target from public.verification_requests where id=p_id;
 if target is null then select profile_id into target from public.financial_verifications where id=p_id;end if;
 if target is null or target=auth.uid() then raise exception 'request_not_available' using errcode='42501';end if;
 kind:=case when p_recovery then 'kaoid_recovery' else 'kaoid_review' end;
 perform pg_advisory_xact_lock(hashtextextended('dual-review:'||p_id,141));
 if exists(select 1 from public.verification_requests where id=p_id and status not in ('pending','under_review')) or exists(select 1 from public.financial_verifications where id=p_id and status<>'pending') then return true;end if;
 fingerprint:=kaoid_private.review_fingerprint_r14a(p_id);
 select * into ar from public.approval_requests where resource=kind and resource_id=p_id and status='pending' for update;
 if found then
  select metadata into meta from public.approval_histories where approval_request_id=ar.id and event='request_created' order by created_at,id limit 1;
  select exists(select 1 from public.profiles p where p.id=ar.requested_by and p.account_status='active' and p.deleted_at is null
   and exists(select 1 from auth.mfa_factors f where f.user_id=p.id and f.status::text='verified')
   and (exists(select 1 from public.company_owners o where o.profile_id=p.id) or exists(select 1 from public.admin_assignments a join public.admin_roles r on r.id=a.role_id
   where a.profile_id=p.id and a.is_active and r.is_active and r.code='kyc_officer' and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now())))) into first_ok;
  if ar.expires_at<=now() or meta->>'fingerprint' is distinct from fingerprint or not first_ok then
   update public.approval_requests set status='expired',completed_at=now(),updated_at=now() where id=ar.id;
   insert into public.approval_histories(approval_request_id,actor_profile_id,event,previous_status,current_status,comment) values(ar.id,auth.uid(),'expired','pending','expired','Evidence, reviewer authority or time changed');
   ar.id:=null;
  elsif ar.requested_by=auth.uid() then
   return false;
  else
   if (meta->>'approve')::boolean is distinct from p_approve then
    update public.approval_requests set status='rejected',completed_at=now(),updated_at=now() where id=ar.id;
    insert into public.approval_histories(approval_request_id,actor_profile_id,event,previous_status,current_status,comment) values(ar.id,auth.uid(),'rejected','pending','rejected',btrim(p_reason));
    return false;
   end if;
   insert into public.approval_steps(approval_request_id,role_id,step_order,status,approved_by,approved_at,comment) values(ar.id,(select id from public.admin_roles where code='kyc_officer'),2,'approved',auth.uid(),now(),p_reason) returning id into sid;
   update public.approval_requests set status='approved',completed_at=now(),updated_at=now() where id=ar.id;
   insert into public.approval_histories(approval_request_id,approval_step_id,actor_profile_id,event,previous_status,current_status,comment)
   values(ar.id,sid,auth.uid(),'completed','pending','approved',p_reason);
   return true;
  end if;
 end if;
 insert into public.approval_requests(policy_id,requested_by,resource,resource_id,status,reason,expires_at)
 select id,auth.uid(),kind,p_id,'pending',p_reason,now()+interval '24 hours' from public.approval_policies where code='kaoid_two_person_r14a' returning id into rid;
 insert into public.approval_steps(approval_request_id,role_id,step_order,status,approved_by,approved_at,comment) values(rid,(select id from public.admin_roles where code='kyc_officer'),1,'approved',auth.uid(),now(),p_reason) returning id into sid;
 insert into public.approval_histories(approval_request_id,approval_step_id,actor_profile_id,event,current_status,metadata)
 values(rid,sid,auth.uid(),'request_created','pending',jsonb_build_object('approve',p_approve,'fingerprint',fingerprint,'policy_version','r14a'));
 return false;
end $$;
create or replace function kaoid_private.review_decision_r7c(p_request uuid,p_approve boolean,p_reason text) returns boolean language plpgsql security definer set search_path='' as $$ begin
 if exists(select 1 from kaoid_private.recovery_evidence_r10e where id=p_request) then raise exception 'recovery_confirmation_required';end if;
 if not kaoid_private.review_vote_r14a(p_request,p_approve,p_reason,false) then return false;end if;
 return kaoid_private.review_decision_base_r10e(p_request,p_approve,p_reason);
end $$;
revoke all on function kaoid_private.review_vote_r14a(uuid,boolean,text,boolean),kaoid_private.review_fingerprint_r14a(uuid),kaoid_private.review_decision_base_r10e(uuid,boolean,text),kaoid_private.review_bank_r9c(uuid,boolean,text) from public,anon,authenticated;

revoke insert,update,delete,truncate on public.approval_requests,public.approval_steps,public.approval_histories,public.approval_policies from anon,authenticated;
;
