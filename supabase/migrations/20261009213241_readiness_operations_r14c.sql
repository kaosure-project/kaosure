create or replace function kaoid_private.security_operations_r14a() returns jsonb language plpgsql stable security definer set search_path='' as $$ begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501';end if;
 return jsonb_build_object(
 'pending_reviews',(select count(*) from public.approval_requests where resource in ('kaoid_review','kaoid_recovery') and status='pending' and expires_at>now()),
 'expired_reviews',(select count(*) from public.approval_requests where resource in ('kaoid_review','kaoid_recovery') and status='pending' and expires_at<=now()),
 'failed_email',(select count(*) from kaoid_private.jobs_r10a where kind='email' and status='failed'),
 'stalled_email',(select count(*) from kaoid_private.jobs_r10a where kind='email' and status='processing' and lease_until<now()),
 'pending_email',(select count(*) from kaoid_private.jobs_r10a where kind='email' and status='pending'),
 'sms_enabled',(select sms_enabled from kaoid_private.service_readiness_r14c where id),
 'event_email_enabled',(select event_email_enabled from kaoid_private.service_readiness_r14c where id),
 'mfa_required',(select mfa_required from kaoid_private.security_policy_r14a where id),
 'dual_review',(select dual_review from kaoid_private.security_policy_r14a where id),
 'checked_at',now());end $$;
;
