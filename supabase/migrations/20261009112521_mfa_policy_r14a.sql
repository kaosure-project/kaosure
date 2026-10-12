create table kaoid_private.security_policy_r14a (
 id boolean primary key default true check(id),
 mfa_required boolean not null default false,
 dual_review boolean not null default false,
 enabled_by uuid references public.profiles(id), enabled_at timestamptz
);
alter table kaoid_private.security_policy_r14a enable row level security;
revoke all on kaoid_private.security_policy_r14a from public,anon,authenticated;
insert into kaoid_private.security_policy_r14a(id) values(true);
create function kaoid_private.aal2_r14a() returns boolean language sql stable security definer set search_path='' as $$
 select kaoid_private.account_active_r9f() and auth.jwt()->>'aal'='aal2' and exists(
 select 1 from auth.sessions s join auth.mfa_factors f on f.id=s.factor_id and f.user_id=s.user_id
 where s.user_id=auth.uid() and s.id::text=auth.jwt()->>'session_id' and s.aal::text='aal2' and f.status::text='verified'); $$;
create function kaoid_private.privileged_ready_r14a() returns boolean language sql stable security definer set search_path='' as $$
 select not (select mfa_required from kaoid_private.security_policy_r14a where id) or coalesce(kaoid_private.aal2_r14a(),false); $$;
create function kaoid_private.security_status_r14a() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare own boolean;ready integer;begin
 if not kaoid_private.account_active_r9f() then raise exception 'session_required' using errcode='42501';end if;
 select exists(select 1 from public.company_owners where profile_id=auth.uid()) into own;
 select count(distinct a.profile_id) into ready from public.admin_assignments a join public.admin_roles r on r.id=a.role_id join public.profiles p on p.id=a.profile_id
 where r.code='kyc_officer' and r.is_active and a.is_active and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now())
 and p.account_status='active' and p.deleted_at is null and not exists(select 1 from public.company_owners o where o.profile_id=p.id)
 and exists(select 1 from auth.mfa_factors f where f.user_id=p.id and f.status::text='verified');
 return jsonb_build_object('owner',own,'aal2',coalesce(kaoid_private.aal2_r14a(),false),
 'verified_factors',(select count(*) from auth.mfa_factors where user_id=auth.uid() and status::text='verified'),
 'ready_reviewers',case when own then ready else null end,
 'mfa_required',(select mfa_required from kaoid_private.security_policy_r14a where id),
 'dual_review',(select dual_review from kaoid_private.security_policy_r14a where id));end $$;
create function public.security_status_r14a() returns jsonb language sql set search_path='' as $$ select kaoid_private.security_status_r14a(); $$;
create function kaoid_private.enable_security_r14a(p_expected_user uuid) returns void language plpgsql security definer set search_path='' as $$
declare s jsonb;begin
 if auth.uid() is distinct from p_expected_user or not exists(select 1 from public.company_owners where profile_id=auth.uid()) or not coalesce(kaoid_private.aal2_r14a(),false) then raise exception 'owner_mfa_required' using errcode='42501';end if;
 perform 1 from kaoid_private.security_policy_r14a where id for update;
 if (select dual_review and mfa_required from kaoid_private.security_policy_r14a where id) then return;end if;
 s:=kaoid_private.security_status_r14a();
 if (s->>'verified_factors')::int<2 or (s->>'ready_reviewers')::int<2 then raise exception 'security_setup_incomplete';end if;
 update kaoid_private.security_policy_r14a set mfa_required=true,dual_review=true,enabled_by=auth.uid(),enabled_at=now() where id;
 insert into public.activity_logs(profile_id,action,target_table,description) values(auth.uid(),'security.enforce','security_policy_r14a','MFA and two-person identity review enabled');
 perform kaoid_private.emit_notice_r10a(auth.uid(),'security-policy:r14a','security_policy_enabled',null);
end $$;
create function public.enable_security_r14a(p_expected_user uuid) returns void language sql set search_path='' as $$ select kaoid_private.enable_security_r14a(p_expected_user); $$;
revoke all on function kaoid_private.aal2_r14a(),kaoid_private.privileged_ready_r14a(),kaoid_private.security_status_r14a(),kaoid_private.enable_security_r14a(uuid) from public,anon,authenticated;
grant execute on function kaoid_private.security_status_r14a(),kaoid_private.enable_security_r14a(uuid) to authenticated;
revoke all on function public.security_status_r14a(),public.enable_security_r14a(uuid) from public,anon;
grant execute on function public.security_status_r14a(),public.enable_security_r14a(uuid) to authenticated;
create function kaoid_private.require_fresh_mfa_r14a() returns void language plpgsql security definer set search_path='' as $$ begin
 if not (select mfa_required from kaoid_private.security_policy_r14a where id) then return;end if;
 if not coalesce(kaoid_private.aal2_r14a(),false) or not exists(select 1 from auth.mfa_amr_claims
 where session_id::text=auth.jwt()->>'session_id' and authentication_method in ('totp','webauthn') and updated_at>now()-interval '10 minutes') then raise exception 'mfa_required' using errcode='42501';end if;
end $$;
revoke all on function kaoid_private.require_fresh_mfa_r14a() from public,anon,authenticated;
;
