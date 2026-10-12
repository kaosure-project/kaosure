CREATE OR REPLACE FUNCTION kaoid_private.staff_snapshot_r9b()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare result jsonb;
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501'; end if;
 select jsonb_build_object(
 'roles',(select coalesce(jsonb_agg(x),'[]') from (select r.code,
 (select coalesce(jsonb_agg(p.code order by p.code),'[]') from public.role_permissions rp join public.permissions p on p.id=rp.permission_id and p.is_active where rp.role_id=r.id and p.code not in ('admin.assignments.create','admin.assignments.update','admin.assignments.delete','admin.owners.update')) permissions
 from public.admin_roles r where r.is_active order by r.code)x),
 'assignments',(select coalesce(jsonb_agg(x),'[]') from(select a.id,a.profile_id,p.display_name,ac.account_code,r.code,a.is_active,a.starts_at,a.expires_at,
 (a.is_active and r.is_active and p.account_status='active' and p.deleted_at is null and (r.code='kyc_officer' or exists(select 1 from public.verifications v join public.kao_id_identities k on k.profile_id=v.profile_id where v.profile_id=p.id and v.status='approved' and k.status='active')) and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now())) as currently_assigned
 from public.admin_assignments a join public.admin_roles r on r.id=a.role_id join public.profiles p on p.id=a.profile_id left join kaoid_private.account_refs_r10c ac on ac.profile_id=p.id order by a.updated_at desc,a.id limit 100)x),
 'history',(select coalesce(jsonb_agg(x),'[]') from(select al.id,al.profile_id,al.action,al.target_id,al.description,al.created_at,al.actor_name_at_event,al.actor_roles_at_event,ac.account_code as actor_code,tc.account_code as target_code,p.display_name as target_name from public.activity_logs al left join kaoid_private.account_refs_r10c ac on ac.profile_id=al.profile_id left join public.admin_assignments aa on aa.id=al.target_id left join kaoid_private.account_refs_r10c tc on tc.profile_id=aa.profile_id left join public.profiles p on p.id=aa.profile_id where al.action in ('governance.role.assign','governance.role.revoke') order by al.created_at desc,al.id limit 100)x)) into result;
 return result;
end $function$
;
