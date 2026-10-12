-- Real account references: separate from verified Kao ID and internal UUID.
create table kaoid_private.account_refs_r10c (
 profile_id uuid primary key references public.profiles(id),
 account_code text not null unique,
 created_at timestamptz not null default now());
alter table kaoid_private.account_refs_r10c enable row level security;
revoke all on kaoid_private.account_refs_r10c from public,anon,authenticated;
create function kaoid_private.new_account_ref_r10c() returns trigger language plpgsql security definer set search_path='' as $$
begin
 loop
  begin
   insert into kaoid_private.account_refs_r10c(profile_id,account_code)
   values(new.id,'ACC-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,16)));
   exit;
  exception when unique_violation then
   if exists(select 1 from kaoid_private.account_refs_r10c where profile_id=new.id) then exit;end if;
  end;
 end loop;
 return new;
end $$;
revoke all on function kaoid_private.new_account_ref_r10c() from public,anon,authenticated;
create trigger account_ref_r10c after insert on public.profiles for each row execute function kaoid_private.new_account_ref_r10c();
do $$ declare p record;begin
 for p in select id from public.profiles loop
  loop begin
   insert into kaoid_private.account_refs_r10c(profile_id,account_code) values(p.id,'ACC-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,16)));
   exit;
  exception when unique_violation then
   if exists(select 1 from kaoid_private.account_refs_r10c where profile_id=p.id) then exit;end if;
  end;end loop;
 end loop;
end $$;

-- Historical roles are unknown unless captured when the event is written.
alter table public.activity_logs add column actor_name_at_event text, add column actor_roles_at_event jsonb;
create function kaoid_private.audit_actor_r10c() returns trigger language plpgsql set search_path='' as $$
begin
 if new.action like 'governance.%' or new.action like 'account.%' then
  if current_user in ('anon','authenticated') then raise exception 'trusted_audit_required' using errcode='42501';end if;
  if tg_op='INSERT' then
   select display_name into new.actor_name_at_event from public.profiles where id=new.profile_id;
   if exists(select 1 from public.company_owners where profile_id=new.profile_id) then new.actor_roles_at_event:='["owner"]'::jsonb;
   else
    select coalesce(jsonb_agg(r.code order by r.code),'[]') into new.actor_roles_at_event
    from public.admin_assignments a join public.admin_roles r on r.id=a.role_id
    where a.profile_id=new.profile_id and a.is_active and r.is_active and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now());
   end if;
  end if;
 end if;
 return new;
end $$;
revoke all on function kaoid_private.audit_actor_r10c() from public,anon,authenticated;
create trigger audit_actor_r10c before insert or update on public.activity_logs for each row execute function kaoid_private.audit_actor_r10c();

create function kaoid_private.lifecycle_queue_r10c(p_status text default 'pending',p_before timestamptz default null,p_before_id uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501';end if;
 if p_status not in ('pending','cancelled','approved','rejected') then raise exception 'invalid_status';end if;
 return (select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (
 select r.id,r.profile_id,r.kind,r.status,r.reason,r.created_at,r.updated_at,p.display_name,p.account_status,a.account_code,k.kao_id
 from kaoid_private.lifecycle_requests_r10b r join public.profiles p on p.id=r.profile_id
 left join kaoid_private.account_refs_r10c a on a.profile_id=p.id
 left join public.kao_id_identities k on k.profile_id=p.id and k.identity_type='personal'
 where r.status=p_status and (p_before is null or (r.created_at,r.id)<(p_before,p_before_id))
 order by r.created_at desc,r.id desc limit 30)x);
end $$;
create function kaoid_private.lifecycle_checks_r10c(p_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid;r kaoid_private.lifecycle_requests_r10b%rowtype;
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501';end if;
 select * into r from kaoid_private.lifecycle_requests_r10b where id=p_id;
 if not found then raise exception 'request_unavailable';end if;u:=r.profile_id;
 return jsonb_build_object('request',to_jsonb(r),
 'orders_total',(select count(*) from public.orders where buyer_id=u or seller_id=u),
 'disputes_total',(select count(*) from public.disputes where buyer_id=u or seller_id=u),
 'wallets',(select coalesce(jsonb_agg(jsonb_build_object('currency',currency,'balance',balance,'hold_balance',hold_balance,'status',wallet_status)),'[]') from public.wallets where profile_id=u),
 'kyc_pending',(select count(*) from public.verification_requests where requested_by=u and status in ('pending','under_review')),
 'staff_active',(select count(*) from public.admin_assignments where profile_id=u and is_active and starts_at<=now() and (expires_at is null or expires_at>now())),
 'close_ready',false,'blocked_reason','session_and_service_enforcement_pending',
 'history',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from(select a.id,a.action,a.description,a.created_at,a.profile_id as actor_id,a.actor_name_at_event,a.actor_roles_at_event,c.account_code as actor_code from public.activity_logs a left join kaoid_private.account_refs_r10c c on c.profile_id=a.profile_id where a.target_table='lifecycle_requests_r10b' and a.target_id=p_id order by a.created_at desc,a.id desc limit 50)x));
end $$;
create function kaoid_private.lifecycle_reject_r10c(p_id uuid,p_reason text) returns boolean language plpgsql security definer set search_path='' as $$
declare r kaoid_private.lifecycle_requests_r10b%rowtype;
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501';end if;
 if length(btrim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'invalid_reason';end if;
 select * into r from kaoid_private.lifecycle_requests_r10b where id=p_id for update;
 if not found or r.profile_id=auth.uid() then raise exception 'request_unavailable' using errcode='42501';end if;
 if r.status='rejected' then return true;end if;
 if r.status<>'pending' then raise exception 'request_already_processed';end if;
 update kaoid_private.lifecycle_requests_r10b set status='rejected',updated_at=now() where id=p_id;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description) values(auth.uid(),'account.request.reject','lifecycle_requests_r10b',p_id,btrim(p_reason));
 perform kaoid_private.emit_notice_r10a(r.profile_id,'lifecycle-rejected:'||p_id,'lifecycle_rejected',p_id);
 return true;
end $$;
create function public.lifecycle_queue_r10c(p_status text default 'pending',p_before timestamptz default null,p_before_id uuid default null) returns jsonb language sql security invoker set search_path='' as $$select kaoid_private.lifecycle_queue_r10c(p_status,p_before,p_before_id);$$;
create function public.lifecycle_checks_r10c(p_id uuid) returns jsonb language sql security invoker set search_path='' as $$select kaoid_private.lifecycle_checks_r10c(p_id);$$;
create function public.lifecycle_reject_r10c(p_id uuid,p_reason text) returns boolean language sql security invoker set search_path='' as $$select kaoid_private.lifecycle_reject_r10c(p_id,p_reason);$$;
revoke all on function kaoid_private.lifecycle_queue_r10c(text,timestamptz,uuid),kaoid_private.lifecycle_checks_r10c(uuid),kaoid_private.lifecycle_reject_r10c(uuid,text),public.lifecycle_queue_r10c(text,timestamptz,uuid),public.lifecycle_checks_r10c(uuid),public.lifecycle_reject_r10c(uuid,text) from public,anon;
grant execute on function kaoid_private.lifecycle_queue_r10c(text,timestamptz,uuid),kaoid_private.lifecycle_checks_r10c(uuid),kaoid_private.lifecycle_reject_r10c(uuid,text),public.lifecycle_queue_r10c(text,timestamptz,uuid),public.lifecycle_checks_r10c(uuid),public.lifecycle_reject_r10c(uuid,text) to authenticated;

create or replace function kaoid_private.find_member_r9a(p_query text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare q text:=btrim(p_query); result jsonb; target uuid;
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'member_access_denied' using errcode='42501'; end if;
 if q is null or length(q)<3 or length(q)>254 then raise exception 'member_query_invalid' using errcode='22023'; end if;
 select jsonb_build_object('id',p.id,'account_code',ac.account_code,'display_name',p.display_name,'account_status',p.account_status,
 'email',u.email,'email_verified',u.email_confirmed_at is not null and coalesce(u.email,'')<>'',
 'phone',u.phone,'phone_verified',u.phone_confirmed_at is not null and coalesce(u.phone,'')<>'',
 'kyc_status',v.status,'kao_id',k.kao_id,'identity_status',k.status,'created_at',p.created_at)
 into result from public.profiles p join auth.users u on u.id=p.id
 left join kaoid_private.account_refs_r10c ac on ac.profile_id=p.id
 left join public.verifications v on v.profile_id=p.id
 left join public.kao_id_identities k on k.profile_id=p.id
 where ac.account_code=upper(q) or lower(u.email)=lower(q) or p.id::text=q or k.kao_id=upper(q)
 order by p.id limit 1;
 target:=(result->>'id')::uuid;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description)
 values(auth.uid(),'governance.member.read','profiles',target,
 case when target is null then 'Exact member lookup: no match' else 'Read member summary' end);
 return result;
end $$;

create or replace function kaoid_private.staff_snapshot_r9b() returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501'; end if;
 select jsonb_build_object(
 'roles',(select coalesce(jsonb_agg(x),'[]') from (select r.code,
 (select coalesce(jsonb_agg(p.code order by p.code),'[]') from public.role_permissions rp join public.permissions p on p.id=rp.permission_id and p.is_active where rp.role_id=r.id) permissions
 from public.admin_roles r where r.is_active order by r.code)x),
 'assignments',(select coalesce(jsonb_agg(x),'[]') from(select a.id,a.profile_id,p.display_name,ac.account_code,r.code,a.is_active,a.starts_at,a.expires_at,
 (a.is_active and r.is_active and p.account_status='active' and p.deleted_at is null and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now())) as currently_assigned
 from public.admin_assignments a join public.admin_roles r on r.id=a.role_id join public.profiles p on p.id=a.profile_id left join kaoid_private.account_refs_r10c ac on ac.profile_id=p.id order by a.updated_at desc,a.id limit 100)x),
 'history',(select coalesce(jsonb_agg(x),'[]') from(select al.id,al.profile_id,al.action,al.target_id,al.description,al.created_at,al.actor_name_at_event,al.actor_roles_at_event,ac.account_code as actor_code,tc.account_code as target_code,p.display_name as target_name from public.activity_logs al left join kaoid_private.account_refs_r10c ac on ac.profile_id=al.profile_id left join public.admin_assignments aa on aa.id=al.target_id left join kaoid_private.account_refs_r10c tc on tc.profile_id=aa.profile_id left join public.profiles p on p.id=aa.profile_id where al.action in ('governance.role.assign','governance.role.revoke') order by al.created_at desc,al.id limit 100)x)) into result;
 return result;
end $$;

create or replace function kaoid_private.lifecycle_snapshot_r10b() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();s text;
begin
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'authentication_required' using errcode='42501';end if;
 select account_status into s from public.profiles where id=u and deleted_at is null;
 if s is null then raise exception 'account_unavailable';end if;
 return jsonb_build_object('account_status',s,'owner',exists(select 1 from public.company_owners where profile_id=u),
 'requests',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (select r.id,r.kind,r.status,r.reason,r.created_at,(select a.description from public.activity_logs a where a.target_table='lifecycle_requests_r10b' and a.target_id=r.id and a.action='account.request.reject' order by a.created_at desc,a.id desc limit 1) as decision_reason from kaoid_private.lifecycle_requests_r10b r where r.profile_id=u order by r.created_at desc,r.id desc limit 20)x));
end $$;
