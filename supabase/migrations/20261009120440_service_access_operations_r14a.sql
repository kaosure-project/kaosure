create function kaoid_private.service_context_r14a(p_expected_user uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare good boolean;begin
 if auth.uid() is null or auth.uid() is distinct from p_expected_user or not kaoid_private.account_active_r9f() then raise exception 'session_required' using errcode='42501';end if;
 good:=kaoid_private.valid_identity_r11a(auth.uid());
 return jsonb_build_object('profile_id',auth.uid(),'account_active',true,
 'identity_verified',good,'personal_kao_id',(select kao_id from public.kao_id_identities where profile_id=auth.uid() and identity_type='personal' and status='active' and good),
 'can_manage_members',kaoid_private.can_read_members_r9a(),'can_review',kaoid_private.can_review_r7c(),
 'mfa_verified',coalesce(kaoid_private.aal2_r14a(),false),'contract_version','r14a');
end $$;
create function public.service_context_r14a(p_expected_user uuid) returns jsonb language sql set search_path='' as $$ select kaoid_private.service_context_r14a(p_expected_user); $$;
create function kaoid_private.security_operations_r14a() returns jsonb language plpgsql stable security definer set search_path='' as $$ begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501';end if;
 return jsonb_build_object(
 'pending_reviews',(select count(*) from public.approval_requests where resource in ('kaoid_review','kaoid_recovery') and status='pending' and expires_at>now()),
 'expired_reviews',(select count(*) from public.approval_requests where resource in ('kaoid_review','kaoid_recovery') and status='pending' and expires_at<=now()),
 'failed_email',(select count(*) from kaoid_private.jobs_r10a where kind='email' and status='failed'),
 'stalled_email',(select count(*) from kaoid_private.jobs_r10a where kind='email' and status='processing' and lease_until<now()),
 'pending_email',(select count(*) from kaoid_private.jobs_r10a where kind='email' and status='pending'),
 'checked_at',now());end $$;
create function public.security_operations_r14a() returns jsonb language sql set search_path='' as $$ select kaoid_private.security_operations_r14a(); $$;
revoke all on function kaoid_private.service_context_r14a(uuid),kaoid_private.security_operations_r14a(),public.service_context_r14a(uuid),public.security_operations_r14a() from public,anon;
grant execute on function kaoid_private.service_context_r14a(uuid),kaoid_private.security_operations_r14a(),public.service_context_r14a(uuid),public.security_operations_r14a() to authenticated;
;
