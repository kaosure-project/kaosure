-- Kao ID governance: one effective authority calculation, no marketplace actions.
create or replace function kaoid_private.company_owner_authority()
returns boolean language sql stable security definer set search_path='' as $$
 select kaoid_private.can_read_members_r9a();
$$;
create or replace function kaoid_private.effective_roles_r13a()
returns table(role_id uuid,code text,name text)
language sql stable security definer set search_path='' as $$
 select distinct r.id,r.code,r.name from public.admin_assignments a
 join public.admin_roles r on r.id=a.role_id
 where kaoid_private.account_active_r9f() and a.profile_id=auth.uid()
 and a.is_active and r.is_active and a.starts_at<=now()
 and (a.expires_at is null or a.expires_at>now())
 and (r.code='kyc_officer' or exists(
  select 1 from public.verifications v join public.kao_id_identities k on k.profile_id=v.profile_id
  where v.profile_id=a.profile_id and v.status='approved' and k.status='active'));
$$;
create or replace function kaoid_private.admin_active_r13a()
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from kaoid_private.effective_roles_r13a());
$$;
create or replace function kaoid_private.permission_r13a(p_code text)
returns boolean language sql stable security definer set search_path='' as $$
 select kaoid_private.account_active_r9f() and (
 kaoid_private.company_owner_authority() or (
 p_code not in ('admin.assignments.create','admin.assignments.update','admin.assignments.delete','admin.owners.update')
 and exists(select 1 from kaoid_private.effective_roles_r13a() r
 join public.role_permissions rp on rp.role_id=r.role_id
 join public.permissions p on p.id=rp.permission_id where p.code=p_code and p.is_active)));
$$;
create or replace function public.is_active_admin() returns boolean language sql stable set search_path='' as $$
 select kaoid_private.admin_active_r13a(); $$;
create or replace function public.can_access_admin() returns boolean language sql stable set search_path='' as $$
 select kaoid_private.company_owner_authority() or kaoid_private.admin_active_r13a(); $$;
create or replace function public.has_permission(p_permission_code text) returns boolean language sql stable set search_path='' as $$
 select kaoid_private.permission_r13a(p_permission_code); $$;
create or replace function kaoid_private.can_review_r7c() returns boolean language sql stable security definer set search_path='' as $$
 select kaoid_private.company_owner_authority() or exists(select 1 from kaoid_private.effective_roles_r13a() where code='kyc_officer'); $$;
create or replace function kaoid_private.governance_access_r13a() returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object(
 'is_owner',kaoid_private.company_owner_authority(),
 'is_admin',kaoid_private.admin_active_r13a(),
 'can_access_admin',kaoid_private.company_owner_authority() or kaoid_private.admin_active_r13a(),
 'can_view_assignments',kaoid_private.permission_r13a('admin.assignments.view'),
 'can_assign_admin',kaoid_private.company_owner_authority(),
 'can_revoke_admin',kaoid_private.company_owner_authority(),
 'roles',(select coalesce(jsonb_agg(jsonb_build_object('code',code,'name',name) order by name),'[]'::jsonb) from kaoid_private.effective_roles_r13a())); $$;
create or replace function public.get_governance_access() returns jsonb language sql stable set search_path='' as $$
 select kaoid_private.governance_access_r13a(); $$;
-- Existing clients remain compatible. New mutations bind to the initiating account.
create or replace function public.staff_assign_r13a(p_expected_user uuid,p_target text,p_role text)
returns uuid language plpgsql set search_path='' as $$ begin
 if auth.uid() is null or auth.uid() is distinct from p_expected_user then raise exception 'session_changed' using errcode='42501';end if;
 return kaoid_private.staff_assign_r9b(p_target,p_role,null);
end $$;
create or replace function public.staff_revoke_r13a(p_expected_user uuid,p_assignment uuid)
returns boolean language plpgsql set search_path='' as $$ begin
 if auth.uid() is null or auth.uid() is distinct from p_expected_user then raise exception 'session_changed' using errcode='42501';end if;
 return kaoid_private.staff_revoke_r9b(p_assignment);
end $$;
revoke all on function kaoid_private.effective_roles_r13a(),kaoid_private.admin_active_r13a(),kaoid_private.permission_r13a(text),kaoid_private.governance_access_r13a() from public,anon;
grant execute on function kaoid_private.effective_roles_r13a(),kaoid_private.admin_active_r13a(),kaoid_private.permission_r13a(text),kaoid_private.governance_access_r13a() to authenticated;
revoke all on function public.is_active_admin(),public.can_access_admin(),public.has_permission(text),public.get_governance_access(),public.staff_assign_r13a(uuid,text,text),public.staff_revoke_r13a(uuid,uuid) from public,anon;
grant execute on function public.is_active_admin(),public.can_access_admin(),public.has_permission(text),public.get_governance_access(),public.staff_assign_r13a(uuid,text,text),public.staff_revoke_r13a(uuid,uuid) to authenticated;
-- Legacy admin predicate must not trust editable/stale profile labels.
create or replace function public.is_admin() returns boolean language sql stable set search_path='' as $$
 select kaoid_private.company_owner_authority() or exists(select 1 from kaoid_private.effective_roles_r13a() where code in ('admin','super_admin')); $$;
revoke all on function public.is_admin() from public,anon;
grant execute on function public.is_admin() to authenticated;
;
