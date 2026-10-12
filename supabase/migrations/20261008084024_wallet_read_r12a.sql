-- Read-only wallet foundation. Does not create wallets or move money.
drop policy if exists "Users can create own wallet" on public.wallets;
drop policy if exists "Users can update own wallet" on public.wallets;
drop policy if exists "System can create wallet transactions" on public.wallet_transactions;
revoke insert,update,delete,truncate on public.wallets, public.wallet_transactions from anon,authenticated;
create index if not exists wallet_history_r12a on public.wallet_transactions(wallet_id,created_at desc,id desc);
create or replace function kaoid_private.wallet_snapshot_r12a(p_expected_user uuid,p_before_time timestamptz default null,p_before_id uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare w public.wallets%rowtype; items jsonb; more boolean;
begin
 if auth.uid() is null or p_expected_user is distinct from auth.uid() or not kaoid_private.account_active_r9f() then
   raise exception 'wallet_access_denied' using errcode='42501';
 end if;
 if (p_before_time is null) <> (p_before_id is null) then raise exception 'invalid_cursor' using errcode='22023';end if;
 select * into w from public.wallets where profile_id=auth.uid();
 if not found then return jsonb_build_object('wallet',null,'transactions','[]'::jsonb,'has_more',false);end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',t.id,'order_id',t.order_id,'type',t.transaction_type,'amount',t.amount::text,
 'balance_before',t.balance_before::text,'balance_after',t.balance_after::text,'status',t.transaction_status,'created_at',t.created_at)
 order by t.created_at desc,t.id desc),'[]'::jsonb) into items
 from (select * from public.wallet_transactions where wallet_id=w.id and (p_before_time is null or (created_at,id)<(p_before_time,p_before_id)) order by created_at desc,id desc limit 30) t;
 select count(*)>30 into more from (select 1 from public.wallet_transactions where wallet_id=w.id and (p_before_time is null or (created_at,id)<(p_before_time,p_before_id)) limit 31) t;
 return jsonb_build_object('wallet',jsonb_build_object('id',w.id,'balance',w.balance::text,'hold_balance',w.hold_balance::text,'currency',w.currency,'status',w.wallet_status,'updated_at',w.updated_at),
 'transactions',items,'has_more',more);
end $$;
revoke all on function kaoid_private.wallet_snapshot_r12a(uuid,timestamptz,uuid) from public,anon;
grant execute on function kaoid_private.wallet_snapshot_r12a(uuid,timestamptz,uuid) to authenticated;
create or replace function public.wallet_snapshot_r12a(p_expected_user uuid,p_before_time timestamptz default null,p_before_id uuid default null)
returns jsonb language sql security invoker set search_path='' as $$ select kaoid_private.wallet_snapshot_r12a(p_expected_user,p_before_time,p_before_id); $$;
revoke all on function public.wallet_snapshot_r12a(uuid,timestamptz,uuid) from public,anon;
grant execute on function public.wallet_snapshot_r12a(uuid,timestamptz,uuid) to authenticated;
