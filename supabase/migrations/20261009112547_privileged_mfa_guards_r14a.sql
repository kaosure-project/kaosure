CREATE OR REPLACE FUNCTION kaoid_private.can_read_members_r9a()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select kaoid_private.account_active_r9f() and kaoid_private.privileged_ready_r14a() and auth.uid() is not null
 and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false)
 and exists(select 1 from public.company_owners o join public.profiles p on p.id=o.profile_id
 where o.profile_id=auth.uid() and p.account_status='active' and p.deleted_at is null);
$function$;

CREATE OR REPLACE FUNCTION kaoid_private.effective_roles_r13a()
 RETURNS TABLE(role_id uuid, code text, name text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select distinct r.id,r.code,r.name from public.admin_assignments a
 join public.admin_roles r on r.id=a.role_id
 where kaoid_private.account_active_r9f() and kaoid_private.privileged_ready_r14a() and a.profile_id=auth.uid()
 and a.is_active and r.is_active and a.starts_at<=now()
 and (a.expires_at is null or a.expires_at>now())
 and (r.code='kyc_officer' or exists(
  select 1 from public.verifications v join public.kao_id_identities k on k.profile_id=v.profile_id
  where v.profile_id=a.profile_id and v.status='approved' and k.status='active'));
$function$;

CREATE OR REPLACE FUNCTION kaoid_private.staff_assign_r9b(p_target text, p_role text, p_expires timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare target uuid; role_id_value uuid; assignment uuid; existing public.admin_assignments%rowtype; role_code text:=lower(btrim(p_role));
begin
 perform kaoid_private.require_fresh_mfa_r14a();
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
end $function$;

CREATE OR REPLACE FUNCTION kaoid_private.staff_revoke_r9b(p_assignment uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.admin_assignments%rowtype; code text;
begin
 perform kaoid_private.require_fresh_mfa_r14a();
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
end $function$;

CREATE OR REPLACE FUNCTION kaoid_private.partner_decide_r12b(p_user uuid, p_id uuid, p_revision integer, p_action text, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare p kaoid_private.partners_r12b%rowtype; next_approval text; next_enabled boolean;
begin
 perform kaoid_private.require_fresh_mfa_r14a();
 perform kaoid_private.partner_owner_r12b(p_user);
 if p_reason is null or length(btrim(p_reason)) not between 3 and 500 then raise exception 'reason_required' using errcode='22023';end if;
 select * into p from kaoid_private.partners_r12b where id=p_id for update;
 if not found then raise exception 'partner_not_found' using errcode='22023';end if;
 if p.revision is distinct from p_revision then raise exception 'partner_changed_reload' using errcode='40001';end if;
 next_approval:=p.approval;next_enabled:=p.enabled;
 if p_action='approve' and p.approval='pending' then next_approval:='approved';next_enabled:=false;
 elsif p_action='reject' and p.approval='pending' then next_approval:='rejected';next_enabled:=false;
 elsif p_action='disable' and p.approval='approved' then next_approval:='disabled';next_enabled:=false;
 elsif p_action='resubmit' and p.approval in ('rejected','disabled') then next_approval:='pending';next_enabled:=false;
 elsif p_action='enable' and p.approval='approved' and not p.enabled then
  if not kaoid_private.partner_ready_r12b(p.id) then raise exception 'partner_not_ready' using errcode='22023';end if;
  next_enabled:=true;
 else raise exception 'invalid_partner_transition' using errcode='22023';end if;
 update kaoid_private.partners_r12b set approval=next_approval,enabled=next_enabled,revision=revision+1,updated_at=now() where id=p.id;
 insert into kaoid_private.partner_history_r12b(partner_id,action,actor_id,actor_role,reason,revision) values(p.id,p_action,auth.uid(),'Owner',btrim(p_reason),p.revision+1);
end $function$;
;
