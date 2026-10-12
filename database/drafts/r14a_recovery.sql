CREATE OR REPLACE FUNCTION kaoid_private.review_recovery_execute_r14a(p_request uuid, p_approve boolean, p_reason text, p_confirm boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
 select 1 from public.identity_documents d join public.verification_requests r on r.document_id=d.id where d.id=e.previous_document and d.owner_id=u and d.status in ('approved','expired') and d.deleted_at is null and r.status='approved' and r.reviewed_by<>u) then raise exception 'recovery_history_required';end if;
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
end $function$;

revoke all on function kaoid_private.review_recovery_execute_r14a(uuid,boolean,text,boolean) from public,anon,authenticated;
create or replace function kaoid_private.review_recovery_r10e(p_request uuid,p_approve boolean,p_reason text,p_confirm boolean) returns boolean language plpgsql security definer set search_path='' as $$ begin
 if not exists(select 1 from kaoid_private.recovery_evidence_r10e where id=p_request) then raise exception 'request_not_available' using errcode='42501';end if;
 if p_approve and p_confirm is distinct from true then raise exception 'recovery_confirmation_required';end if;
 if not kaoid_private.review_vote_r14a(p_request,p_approve,p_reason,true) then return false;end if;
 return kaoid_private.review_recovery_execute_r14a(p_request,p_approve,p_reason,p_confirm);
end $$;
