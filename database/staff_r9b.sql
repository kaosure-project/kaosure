create or replace function kaoid_private.staff_snapshot_r9b() returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501'; end if;
 select jsonb_build_object(
 'roles',(select coalesce(jsonb_agg(x),'[]') from (select r.code,
 (select coalesce(jsonb_agg(p.code order by p.code),'[]') from public.role_permissions rp join public.permissions p on p.id=rp.permission_id and p.is_active where rp.role_id=r.id) permissions
 from public.admin_roles r where r.is_active order by r.code)x),
 'assignments',(select coalesce(jsonb_agg(x),'[]') from(select a.id,a.profile_id,p.display_name,r.code,a.is_active,a.starts_at,a.expires_at,
 (a.is_active and r.is_active and p.account_status='active' and p.deleted_at is null and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now())) as currently_assigned
 from public.admin_assignments a join public.admin_roles r on r.id=a.role_id join public.profiles p on p.id=a.profile_id order by a.updated_at desc,a.id limit 100)x),
 'history',(select coalesce(jsonb_agg(x),'[]') from(select id,profile_id,action,target_id,description,created_at from public.activity_logs where action in ('governance.role.assign','governance.role.revoke') order by created_at desc,id limit 100)x)) into result;
 return result;
end $$;
create or replace function kaoid_private.staff_assign_r9b(p_target text,p_role text,p_expires timestamptz default null) returns uuid
language plpgsql security definer set search_path='' as $$
declare target uuid; role_id_value uuid; assignment uuid; existing public.admin_assignments%rowtype; role_code text:=lower(btrim(p_role));
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501'; end if;
 if p_expires is not null and p_expires<=now() then raise exception 'invalid_expiry'; end if;
 select p.id into target from public.profiles p join auth.users u on u.id=p.id
 left join public.kao_id_identities k on k.profile_id=p.id
 where (p.id::text=btrim(p_target) or k.kao_id=upper(btrim(p_target)))
 and p.account_status='active' and p.deleted_at is null and u.email_confirmed_at is not null and coalesce(u.email,'')<>'';
 if target is null then raise exception 'target_unavailable'; end if;
 if target=auth.uid() or exists(select 1 from public.company_owners where profile_id=target) then raise exception 'owner_role_protected'; end if;
 select id into role_id_value from public.admin_roles where code=role_code and is_active;
 if role_id_value is null then raise exception 'role_unavailable'; end if;
 -- Initial reviewer assignment is operational authority, not a customer KYC decision.
 if role_code<>'kyc_officer' and not exists(select 1 from public.verifications v join public.kao_id_identities k on k.profile_id=v.profile_id where v.profile_id=target and v.status='approved' and k.status='active') then raise exception 'target_kyc_required'; end if;
 perform pg_advisory_xact_lock(hashtextextended(target::text||role_id_value::text,919));
 select * into existing from public.admin_assignments where profile_id=target and role_id=role_id_value for update;
 if found and existing.is_active and existing.starts_at<=now() and existing.expires_at is not distinct from p_expires then return existing.id; end if;
 insert into public.admin_assignments(profile_id,role_id,assigned_by,starts_at,expires_at,is_active)
 values(target,role_id_value,auth.uid(),now(),p_expires,true)
 on conflict(profile_id,role_id) do update set assigned_by=excluded.assigned_by,starts_at=now(),expires_at=excluded.expires_at,is_active=true,updated_at=now()
 returning id into assignment;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description)
 values(auth.uid(),'governance.role.assign','admin_assignments',assignment,
 jsonb_build_object('target_profile_id',target,'role',role_code,'expires_at',p_expires)::text);
 return assignment;
end $$;
create or replace function kaoid_private.staff_revoke_r9b(p_assignment uuid) returns boolean
language plpgsql security definer set search_path='' as $$
declare a public.admin_assignments%rowtype; code text;
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501'; end if;
 select * into a from public.admin_assignments where id=p_assignment for update;
 if not found then raise exception 'assignment_missing'; end if;
 if not a.is_active then return true; end if;
 select r.code into code from public.admin_roles r where r.id=a.role_id;
 update public.admin_assignments set is_active=false,updated_at=now() where id=a.id;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description)
 values(auth.uid(),'governance.role.revoke','admin_assignments',a.id,
 jsonb_build_object('target_profile_id',a.profile_id,'role',code,'expires_at',a.expires_at)::text);
 return true;
end $$;
revoke all on function kaoid_private.staff_snapshot_r9b(),kaoid_private.staff_assign_r9b(text,text,timestamptz),kaoid_private.staff_revoke_r9b(uuid) from public,anon;
grant execute on function kaoid_private.staff_snapshot_r9b(),kaoid_private.staff_assign_r9b(text,text,timestamptz),kaoid_private.staff_revoke_r9b(uuid) to authenticated;
create or replace function public.staff_snapshot_r9b() returns jsonb language sql security invoker set search_path='' as $$ select kaoid_private.staff_snapshot_r9b(); $$;
create or replace function public.assign_admin_role(p_target_kao_id text,p_role_code text,p_expires_at timestamptz default null) returns uuid language sql security invoker set search_path='' as $$ select kaoid_private.staff_assign_r9b(p_target_kao_id,p_role_code,p_expires_at); $$;
create or replace function public.revoke_admin_assignment(p_assignment_id uuid) returns boolean language sql security invoker set search_path='' as $$ select kaoid_private.staff_revoke_r9b(p_assignment_id); $$;
revoke all on function public.staff_snapshot_r9b(),public.assign_admin_role(text,text,timestamptz),public.revoke_admin_assignment(uuid) from public,anon;
grant execute on function public.staff_snapshot_r9b(),public.assign_admin_role(text,text,timestamptz),public.revoke_admin_assignment(uuid) to authenticated;
