alter table public.activity_logs alter column profile_id drop not null;
alter table public.activity_logs add constraint activity_system_actor_r11a check (profile_id is not null or action='kyc.expire');
CREATE OR REPLACE FUNCTION kaoid_private.audit_actor_r10c()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
 if (tg_op in ('DELETE','UPDATE') and (old.action like 'governance.%' or old.action like 'account.%' or old.action like 'kyc.%'))
 or (tg_op<>'DELETE' and (new.action like 'governance.%' or new.action like 'account.%' or new.action like 'kyc.%')) then
  if current_user in ('anon','authenticated') then raise exception 'trusted_audit_required' using errcode='42501';end if;
  if tg_op='INSERT' then
   select display_name into new.actor_name_at_event from public.profiles where id=new.profile_id;
   if new.profile_id is null then new.actor_roles_at_event:='["system"]'::jsonb;
   elsif exists(select 1 from public.company_owners where profile_id=new.profile_id) then new.actor_roles_at_event:='["owner"]'::jsonb;
   else
    select coalesce(jsonb_agg(r.code order by r.code),'[]') into new.actor_roles_at_event
    from public.admin_assignments a join public.admin_roles r on r.id=a.role_id
    where a.profile_id=new.profile_id and a.is_active and r.is_active and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now());
   end if;
  end if;
 end if;
 if tg_op='DELETE' then return old;end if;
 return new;
end $function$
;;
