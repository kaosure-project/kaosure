-- R18b: retire the pre-SSO OAuth/session tables. Supabase Auth (auth.oauth_clients, auth.oauth_consents,
-- auth.sessions) and kaoid_private.app_clients_r18 are the only sources of truth from R18 onwards.
do $$
begin
  if exists(select 1 from public.oauth_tokens) or exists(select 1 from public.oauth_clients)
     or exists(select 1 from public.sessions)
     or exists(select 1 from public.analytics_events where session_id is not null)
     or exists(select 1 from public.page_views where session_id is not null) then
    raise exception 'legacy_oauth_tables_not_empty';
  end if;
end $$;

create or replace function kaoid_private.closure_blockers_r10d(u uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare blockers jsonb:='[]'; t text; predicate text; n bigint;
begin
 if not exists(select 1 from public.profiles where id=u and account_status='active' and deleted_at is null)
 or exists(select 1 from public.company_owners where profile_id=u) then
 blockers:=blockers||jsonb_build_array(jsonb_build_object('code','account_state','count',1));end if;
 if exists(select 1 from public.wallets where profile_id=u and (balance is null or hold_balance is null or balance<>0 or hold_balance<>0)) then
 blockers:=blockers||jsonb_build_array(jsonb_build_object('code','wallet_balance','count',1));end if;
 foreach t in array array['orders','order_items','disputes','withdraw_requests','refund_requests','return_requests','cancel_requests','shops','organization_members','organization_delegations','business_registrations','approval_requests','api_keys','commission','tax_records','invoice','receipt'] loop
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
 if exists(select 1 from kaoid_private.wallet_links_r12c where profile_id=u) then
 blockers:=blockers||jsonb_build_array(jsonb_build_object('code','service_history','table','partner_wallet','count',1));end if;
 return blockers;
end $$;

create or replace function kaoid_private.close_account_execute_r14a(p_request uuid, p_reason text) returns boolean language plpgsql security definer set search_path='' as $$
declare r kaoid_private.lifecycle_requests_r10b%rowtype; u uuid; blockers jsonb; t text;
begin
 if not kaoid_private.data_access_r10d() or not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501';end if;
 if length(btrim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'invalid_reason';end if;
 select profile_id into u from kaoid_private.lifecycle_requests_r10b where id=p_request;
 if u is null or u=auth.uid() or exists(select 1 from public.company_owners where profile_id=u) then raise exception 'request_unavailable' using errcode='42501';end if;
 -- Short, bounded write barrier prevents service records arriving between checks and closure.
 foreach t in array array['orders','order_items','disputes','withdraw_requests','refund_requests','return_requests','cancel_requests','shops','organization_members','organization_delegations','business_registrations','approval_requests','api_keys','commission','tax_records','invoice','receipt','wallets','wallet_transactions','payment_transactions','escrow_transactions'] loop
 execute format('lock table public.%I in share row exclusive mode',t);
 end loop;
 perform 1 from public.profiles where id=u for update;
 select * into r from kaoid_private.lifecycle_requests_r10b where id=p_request for update;
 if r.kind<>'closure' then raise exception 'closure_request_required';end if;
 if exists(select 1 from kaoid_private.account_closures_r10d where request_id=p_request) and r.status='approved' then return true;end if;
 if r.status<>'pending' then raise exception 'request_already_processed';end if;
 blockers:=kaoid_private.closure_blockers_r10d(u);
 if jsonb_array_length(blockers)>0 then raise exception 'closure_obligations_require_review';end if;
 insert into kaoid_private.account_closures_r10d(profile_id,request_id,closed_by,reason,prior_access) select u,p_request,auth.uid(),btrim(p_reason),jsonb_build_object('role',role,'seller_level',seller_level,'is_seller',is_seller) from public.profiles where id=u on conflict(profile_id) do update set request_id=excluded.request_id,closed_at=clock_timestamp(),closed_by=excluded.closed_by,reason=excluded.reason,prior_access=excluded.prior_access;
 update public.admin_assignments set is_active=false,updated_at=now() where profile_id=u and is_active;
 update public.owner_delegations set revoked_at=now(),revoked_by=auth.uid(),updated_at=now() where delegate_profile_id=u and revoked_at is null;
 update public.shop_staff set is_active=false,updated_at=now() where profile_id=u and is_active;
 update auth.oauth_consents set revoked_at=now() where user_id=u and revoked_at is null;
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

-- Columns stay for historical analytics; only the link to the retired table goes.
alter table public.analytics_events drop constraint analytics_events_session_id_fkey;
alter table public.page_views drop constraint page_views_session_id_fkey;

drop table public.oauth_tokens restrict;
drop table public.oauth_clients restrict;
drop table public.sessions restrict;

notify pgrst, 'reload schema';
