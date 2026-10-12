create or replace function kaoid_private.review_recovery_r10e(p_request uuid,p_approve boolean,p_reason text,p_confirm boolean) returns boolean language plpgsql security definer set search_path='' as $$ begin
 if not exists(select 1 from kaoid_private.recovery_evidence_r10e where id=p_request) then raise exception 'request_not_available' using errcode='42501';end if;
 if p_approve and p_confirm is distinct from true then raise exception 'recovery_confirmation_required';end if;
 if not kaoid_private.review_vote_r14a(p_request,p_approve,p_reason,true) then return false;end if;
 return kaoid_private.review_recovery_execute_r14a(p_request,p_approve,p_reason,p_confirm);
end $$;
;
