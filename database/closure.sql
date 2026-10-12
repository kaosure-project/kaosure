-- Closure is enabled only for accounts without unresolved service footprints.
create table kaoid_private.account_closures_r10d (
 profile_id uuid primary key references public.profiles(id),
 request_id uuid not null unique references kaoid_private.lifecycle_requests_r10b(id),
 closed_at timestamptz not null default clock_timestamp(),
 closed_by uuid not null references public.profiles(id),
 prior_access jsonb not null,
 reason text not null check(length(btrim(reason)) between 3 and 1000));
alter table kaoid_private.account_closures_r10d enable row level security;
revoke all on kaoid_private.account_closures_r10d from public,anon,authenticated;

create function kaoid_private.account_access_r10d() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare u uuid:=auth.uid(); s text; closed_time timestamptz; valid_session boolean;
begin
 if u is null then return jsonb_build_object('state','signed_out');end if;
 select account_status into s from public.profiles where id=u;
 select closed_at into closed_time from kaoid_private.account_closures_r10d where profile_id=u;
 if closed_time is not null then
  select exists(select 1 from auth.sessions where user_id=u and id::text=auth.jwt()->>'session_id' and created_at>closed_time) into valid_session;
  if not valid_session then return jsonb_build_object('state','session_revoked');end if;
 end if;
 return jsonb_build_object('state',case when s='closed' then 'closed' else 'active' end);
end $$;
create function kaoid_private.data_access_r10d() returns boolean language sql stable security definer set search_path='' as $$
 select coalesce(kaoid_private.account_access_r10d()->>'state','') in ('active','signed_out');
$$;
create function kaoid_private.pre_request_r10d() returns void language plpgsql security definer set search_path='' as $$
declare st text; path text:=trim(both '/' from coalesce(current_setting('request.path',true),''));
begin
 if auth.uid() is null then return;end if;
 -- Minimal status is safe even when the caller's old Auth session has been revoked.
 if path='rpc/account_access_r10d' then return;end if;
 st:=kaoid_private.account_access_r10d()->>'state';
 if st='session_revoked' then raise exception 'account_session_revoked' using errcode='42501';end if;
 if st='closed' and path not in ('rpc/lifecycle_snapshot_r10b','rpc/lifecycle_submit_r10b','rpc/lifecycle_cancel_r10b') then
  raise exception 'account_closed' using errcode='42501';end if;
end $$;
create function public.account_access_r10d() returns jsonb language sql security invoker set search_path='' as $$select kaoid_private.account_access_r10d();$$;
revoke all on function kaoid_private.account_access_r10d(),kaoid_private.data_access_r10d(),kaoid_private.pre_request_r10d(),public.account_access_r10d() from public;
grant execute on function kaoid_private.account_access_r10d(),kaoid_private.data_access_r10d(),kaoid_private.pre_request_r10d(),public.account_access_r10d() to anon,authenticated,service_role;

-- Additional RLS restriction for table/Storage paths (PostgREST hook does not cover Storage).
do $$ declare t record;begin
 for t in select n.nspname,c.relname from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relkind='r' and c.relrowsecurity loop
 execute format('create policy account_closure_r10d on %I.%I as restrictive for all to authenticated using ((select kaoid_private.data_access_r10d())) with check ((select kaoid_private.data_access_r10d()))',t.nspname,t.relname);
 end loop;
end $$;
create policy account_closure_r10d on storage.objects as restrictive for all to authenticated
using ((select kaoid_private.data_access_r10d())) with check ((select kaoid_private.data_access_r10d()));

-- Readiness uses actual records. Any service history requiring lifecycle semantics blocks closure.
create function kaoid_private.closure_blockers_r10d(u uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare blockers jsonb:='[]'; t text; predicate text; n bigint;
begin
 if not exists(select 1 from public.profiles where id=u and account_status='active' and deleted_at is null)
 or exists(select 1 from public.company_owners where profile_id=u) then
 blockers:=blockers||jsonb_build_array(jsonb_build_object('code','account_state','count',1));end if;
 if exists(select 1 from public.wallets where profile_id=u and (balance is null or hold_balance is null or balance<>0 or hold_balance<>0)) then
 blockers:=blockers||jsonb_build_array(jsonb_build_object('code','wallet_balance','count',1));end if;
 foreach t in array array['orders','order_items','disputes','withdraw_requests','refund_requests','return_requests','cancel_requests','shops','organization_members','organization_delegations','business_registrations','approval_requests','api_keys','oauth_clients','commission','tax_records','invoice','receipt'] loop
 select string_agg(format('%I=$1',column_name),' or ') into predicate from information_schema.columns
 where table_schema='public' and table_name=t and data_type='uuid' and column_name in ('profile_id','owner_id','seller_id','buyer_id','user_id','requested_by','requester_id','created_by','owner_profile_id','delegate_profile_id');
 if predicate is null then
  -- Schema unknown means review required; never silently treat it as zero.
  blockers:=blockers||jsonb_build_array(jsonb_build_object('code','schema_review','table',t,'count',null));
 else
  execute format('select count(*) from public.%I where %s',t,predicate) into n using u;
  if n>0 then blockers:=blockers||jsonb_build_array(jsonb_build_object('code','service_history','table',t,'count',n));end if;
 end if;
 end loop;
 select count(*) into n from public.payment_transactions p where p.payer_wallet_id in(select id from public.wallets where profile_id=u) or p.receiver_wallet_id in(select id from public.wallets where profile_id=u);
 if n>0 then blockers:=blockers||jsonb_build_array(jsonb_build_object('code','service_history','table','payment_transactions','count',n));end if;
 select count(*) into n from public.escrow_transactions e where e.buyer_wallet_id in(select id from public.wallets where profile_id=u) or e.seller_wallet_id in(select id from public.wallets where profile_id=u);
 if n>0 then blockers:=blockers||jsonb_build_array(jsonb_build_object('code','service_history','table','escrow_transactions','count',n));end if;
 select count(*) into n from public.wallet_transactions where wallet_id in(select id from public.wallets where profile_id=u);
 if n>0 then blockers:=blockers||jsonb_build_array(jsonb_build_object('code','service_history','table','wallet_transactions','count',n));end if;
 return blockers;
end $$;
revoke all on function kaoid_private.closure_blockers_r10d(uuid) from public,anon,authenticated;

create function kaoid_private.close_account_r10d(p_request uuid,p_reason text) returns boolean language plpgsql security definer set search_path='' as $$
declare r kaoid_private.lifecycle_requests_r10b%rowtype; u uuid; blockers jsonb; t text;
begin
 if not kaoid_private.data_access_r10d() or not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501';end if;
 if length(btrim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'invalid_reason';end if;
 select profile_id into u from kaoid_private.lifecycle_requests_r10b where id=p_request;
 if u is null or u=auth.uid() or exists(select 1 from public.company_owners where profile_id=u) then raise exception 'request_unavailable' using errcode='42501';end if;
 -- Short, bounded write barrier prevents service records arriving between checks and closure.
 foreach t in array array['orders','order_items','disputes','withdraw_requests','refund_requests','return_requests','cancel_requests','shops','organization_members','organization_delegations','business_registrations','approval_requests','api_keys','oauth_clients','commission','tax_records','invoice','receipt','wallets','wallet_transactions','payment_transactions','escrow_transactions'] loop
 execute format('lock table public.%I in share row exclusive mode',t);
 end loop;
 perform 1 from public.profiles where id=u for update;
 select * into r from kaoid_private.lifecycle_requests_r10b where id=p_request for update;
 if r.kind<>'closure' then raise exception 'closure_request_required';end if;
 if exists(select 1 from kaoid_private.account_closures_r10d where request_id=p_request) and r.status='approved' then return true;end if;
 if r.status<>'pending' then raise exception 'request_already_processed';end if;
 blockers:=kaoid_private.closure_blockers_r10d(u);
 if jsonb_array_length(blockers)>0 then raise exception 'closure_obligations_require_review';end if;
 insert into kaoid_private.account_closures_r10d(profile_id,request_id,closed_by,reason,prior_access) select u,p_request,auth.uid(),btrim(p_reason),jsonb_build_object('role',role,'seller_level',seller_level,'is_seller',is_seller) from public.profiles where id=u;
 update public.admin_assignments set is_active=false,updated_at=now() where profile_id=u and is_active;
 update public.owner_delegations set revoked_at=now(),revoked_by=auth.uid(),updated_at=now() where delegate_profile_id=u and revoked_at is null;
 update public.shop_staff set is_active=false,updated_at=now() where profile_id=u and is_active;
 update public.oauth_tokens set revoked_at=now(),revoked_by=auth.uid(),revoke_reason='account_closed',updated_at=now() where profile_id=u and revoked_at is null;
 update public.sessions set revoked_at=now(),logout_at=now(),logout_reason='account_closed',is_current=false,updated_at=now() where profile_id=u and revoked_at is null;
 update public.admin_sessions set is_active=false,terminated_at=now(),terminated_by=auth.uid(),termination_reason='account_closed',updated_at=now() where profile_id=u and is_active;
 update public.verification_requests set status='cancelled',updated_at=now() where requested_by=u and status in ('pending','under_review');
 update public.kao_id_identities set status='closed',updated_at=now() where profile_id=u and identity_type='personal';
 update public.profiles set account_status='closed',role='user',seller_level='standard',is_seller=false,updated_at=now() where id=u;
 update kaoid_private.lifecycle_requests_r10b set status='approved',updated_at=now() where id=p_request;
 -- Auth refresh tokens reference sessions with ON DELETE CASCADE; remove legacy tokens too.
 delete from auth.refresh_tokens where user_id=u::text;
 delete from auth.sessions where user_id=u;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description) values(auth.uid(),'account.request.close','lifecycle_requests_r10b',p_request,btrim(p_reason));
 perform kaoid_private.emit_notice_r10a(u,'account-closed:'||p_request,'account_closed',p_request);
 return true;
end $$;
create function public.close_account_r10d(p_request uuid,p_reason text) returns boolean language sql security invoker set search_path='' as $$select kaoid_private.close_account_r10d(p_request,p_reason);$$;
revoke all on function kaoid_private.close_account_r10d(uuid,text),public.close_account_r10d(uuid,text) from public,anon;
grant execute on function kaoid_private.close_account_r10d(uuid,text),public.close_account_r10d(uuid,text) to authenticated;

create or replace function kaoid_private.lifecycle_checks_r10c(p_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare blockers jsonb;u uuid;r kaoid_private.lifecycle_requests_r10b%rowtype;
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501';end if;
 select * into r from kaoid_private.lifecycle_requests_r10b where id=p_id;
 if not found then raise exception 'request_unavailable';end if;u:=r.profile_id; blockers:=kaoid_private.closure_blockers_r10d(u);
 return jsonb_build_object('request',to_jsonb(r),
 'orders_total',(select count(*) from public.orders where buyer_id=u or seller_id=u),
 'disputes_total',(select count(*) from public.disputes where buyer_id=u or seller_id=u),
 'wallets',(select coalesce(jsonb_agg(jsonb_build_object('currency',currency,'balance',balance,'hold_balance',hold_balance,'status',wallet_status)),'[]') from public.wallets where profile_id=u),
 'kyc_pending',(select count(*) from public.verification_requests where requested_by=u and status in ('pending','under_review')),
 'staff_active',(select count(*) from public.admin_assignments where profile_id=u and is_active and starts_at<=now() and (expires_at is null or expires_at>now())),
 'close_ready',r.kind='closure' and r.status='pending' and jsonb_array_length(blockers)=0,'blockers',blockers,
 'history',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from(select a.id,a.action,a.description,a.created_at,a.profile_id as actor_id,a.actor_name_at_event,a.actor_roles_at_event,c.account_code as actor_code from public.activity_logs a left join kaoid_private.account_refs_r10c c on c.profile_id=a.profile_id where a.target_table='lifecycle_requests_r10b' and a.target_id=p_id order by a.created_at desc,a.id desc limit 50)x));
end $$;

create or replace function kaoid_private.lifecycle_snapshot_r10b() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();s text;
begin
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'authentication_required' using errcode='42501';end if;
 if kaoid_private.account_access_r10d()->>'state'='session_revoked' then raise exception 'account_session_revoked' using errcode='42501';end if;
 select account_status into s from public.profiles where id=u and deleted_at is null;
 if s is null then raise exception 'account_unavailable';end if;
 return jsonb_build_object('account_status',s,'owner',exists(select 1 from public.company_owners where profile_id=u),
 'requests',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (select r.id,r.kind,r.status,r.reason,r.created_at,(select a.description from public.activity_logs a where a.target_table='lifecycle_requests_r10b' and a.target_id=r.id and a.action in ('account.request.reject','account.request.close') order by a.created_at desc,a.id desc limit 1) as decision_reason from kaoid_private.lifecycle_requests_r10b r where r.profile_id=u order by r.created_at desc,r.id desc limit 20)x));
end $$;

-- Prevent services creating new obligations for a closed account, even via a privileged writer.
create function kaoid_private.guard_service_target_r10d() returns trigger language plpgsql security definer set search_path='' as $$
declare k text; v text; u uuid; st text; j jsonb:=to_jsonb(new);
begin
 foreach k in array tg_argv loop
  v:=j->>k; if v is null then continue;end if;
  if k in ('wallet_id','payer_wallet_id','receiver_wallet_id','buyer_wallet_id','seller_wallet_id') then
   select profile_id into u from public.wallets where id=v::uuid;
  else u:=v::uuid;end if;
  select account_status into st from public.profiles where id=u for share;
  if st='closed' then raise exception 'target_account_closed' using errcode='42501';end if;
 end loop;
 return new;
end $$;
revoke all on function kaoid_private.guard_service_target_r10d() from public,anon,authenticated;
do $$ declare t text;args text;begin
 foreach t in array array['orders','order_items','disputes','withdraw_requests','refund_requests','return_requests','cancel_requests','shops','organization_members','organization_delegations','business_registrations','approval_requests','api_keys','oauth_clients','commission','tax_records','invoice','receipt','wallets','wallet_transactions','payment_transactions','escrow_transactions'] loop
 select string_agg(quote_literal(column_name),',' order by column_name) into args from information_schema.columns where table_schema='public' and table_name=t and data_type='uuid' and column_name in ('profile_id','owner_id','seller_id','buyer_id','user_id','requested_by','requester_id','created_by','owner_profile_id','delegate_profile_id','wallet_id','payer_wallet_id','receiver_wallet_id','buyer_wallet_id','seller_wallet_id');
 if args is null then raise exception 'unmapped_service_table: %',t;end if;
 execute format('create trigger guard_closed_target_r10d before insert or update on public.%I for each row execute function kaoid_private.guard_service_target_r10d(%s)',t,args);
 end loop;
end $$;
-- Keep future access from closed accounts limited, including direct RPC calls.
create function kaoid_private.guard_lifecycle_session_r10d() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if kaoid_private.account_access_r10d()->>'state'='session_revoked' then raise exception 'account_session_revoked' using errcode='42501';end if;
 return new;
end $$;
revoke all on function kaoid_private.guard_lifecycle_session_r10d() from public,anon,authenticated;
create trigger lifecycle_session_r10d before insert or update on kaoid_private.lifecycle_requests_r10b for each row execute function kaoid_private.guard_lifecycle_session_r10d();
-- Existing project had no pre-request hook. Preserve this guard when adding future hooks.
alter role authenticator set pgrst.db_pre_request='kaoid_private.pre_request_r10d';
notify pgrst,'reload config';
notify pgrst,'reload schema';

create function kaoid_private.guard_staff_target_r10d() returns trigger language plpgsql security definer set search_path='' as $$
declare j jsonb:=to_jsonb(new);u uuid;st text;
begin
 if tg_table_name='owner_delegations' then
  if j->>'revoked_at' is not null then return new;end if;u:=(j->>'delegate_profile_id')::uuid;
 else
  if coalesce((j->>'is_active')::boolean,false)=false then return new;end if;u:=(j->>'profile_id')::uuid;
 end if;
 select account_status into st from public.profiles where id=u for share;
 if st='closed' then raise exception 'target_account_closed' using errcode='42501';end if;
 return new;
end $$;
revoke all on function kaoid_private.guard_staff_target_r10d() from public,anon,authenticated;
create trigger closed_staff_r10d before insert or update on public.admin_assignments for each row execute function kaoid_private.guard_staff_target_r10d();
create trigger closed_staff_r10d before insert or update on public.shop_staff for each row execute function kaoid_private.guard_staff_target_r10d();
create trigger closed_staff_r10d before insert or update on public.owner_delegations for each row execute function kaoid_private.guard_staff_target_r10d();

-- Narrow gateway supports anonymous REST requests without exposing kaoid_private.
create schema kaoid_gateway;
revoke all on schema kaoid_gateway from public;
grant usage on schema kaoid_gateway to anon,authenticated,service_role;
create function kaoid_gateway.pre_request_r10d() returns void language sql security definer set search_path='' as $$select kaoid_private.pre_request_r10d();$$;
revoke all on function kaoid_gateway.pre_request_r10d() from public;
grant execute on function kaoid_gateway.pre_request_r10d() to anon,authenticated,service_role;
alter role authenticator set pgrst.db_pre_request='kaoid_gateway.pre_request_r10d';
notify pgrst,'reload config';
