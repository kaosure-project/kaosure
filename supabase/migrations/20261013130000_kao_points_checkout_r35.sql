-- R35: KaoSure Points, part 1: spending points at Secondhand checkout.
--   * Points belong to the Kao ecosystem: one balance per member, shared by every app. Each movement is a
--     ledger row; members read only their own rows, and only server functions change them.
--   * A buyer may use points for up to the whole item price; 1 point is worth market_settings.point_value baht.
--     Points are taken at payment (pay_order), not when the order is placed.
--   * The platform bears the discount: escrow still holds the full price, so the seller is paid exactly as
--     before (total_amount - marketplace_fee).
--   * A cancelled paid order gives the cash part back to the wallet and the points back as points. Points never
--     turn into cash.
--   * How members earn points comes in a later round; until then every balance is 0.

create table public.kao_point_balances (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create table public.kao_point_transactions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  app text not null check (app in ('kao_id', 'secondhand', 'auction')),
  kind text not null check (kind in ('grant', 'spend', 'refund', 'expire', 'adjust')),
  delta integer not null check (delta <> 0),
  balance_after integer not null check (balance_after >= 0),
  order_id uuid references public.orders(id) on delete set null,
  note text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create index kao_point_transactions_profile_idx on public.kao_point_transactions (profile_id, created_at desc);
create index kao_point_transactions_order_idx on public.kao_point_transactions (order_id) where order_id is not null;

alter table public.kao_point_balances enable row level security;
alter table public.kao_point_transactions enable row level security;
revoke all on table public.kao_point_balances, public.kao_point_transactions from anon, authenticated;
grant select on table public.kao_point_balances, public.kao_point_transactions to authenticated;
create policy kao_point_balances_own_read on public.kao_point_balances for select to authenticated
  using (profile_id = (select auth.uid()));
create policy kao_point_transactions_own_read on public.kao_point_transactions for select to authenticated
  using (profile_id = (select auth.uid()));

-- The only way points move: locks the balance, refuses to go below zero, and writes the ledger row.
create function kaoid_private.kao_points_move_r35(
  p_profile uuid, p_app text, p_kind text, p_delta integer, p_order uuid, p_note text, p_actor uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_balance integer;
begin
  if p_delta is null or p_delta = 0 then
    raise exception 'invalid_points' using errcode = '22023';
  end if;
  insert into public.kao_point_balances (profile_id) values (p_profile) on conflict (profile_id) do nothing;
  select b.balance into strict v_balance from public.kao_point_balances b where b.profile_id = p_profile for update;
  if v_balance + p_delta < 0 then
    raise exception 'insufficient_points' using errcode = '22023';
  end if;
  update public.kao_point_balances set balance = v_balance + p_delta, updated_at = now() where profile_id = p_profile;
  insert into public.kao_point_transactions (profile_id, app, kind, delta, balance_after, order_id, note, created_by)
  values (p_profile, p_app, p_kind, p_delta, v_balance + p_delta, p_order, p_note, p_actor);
  return v_balance + p_delta;
end $$;
revoke all on function kaoid_private.kao_points_move_r35(uuid, text, text, integer, uuid, text, uuid)
  from public, anon, authenticated;

alter table secondhand.market_settings
  add column points_enabled boolean not null default true,
  add column point_value numeric(10,2) not null default 1 check (point_value > 0);

alter table secondhand.order_details
  add column points_used integer not null default 0 check (points_used >= 0),
  drop constraint order_details_payment_method_check,
  add constraint order_details_payment_method_check check (payment_method in ('wallet', 'mock', 'points'));

create or replace function secondhand.get_checkout(p_product_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_price jsonb := secondhand.offer_checkout_price_r20g(p_product_id, u);
  v_settings secondhand.market_settings;
begin
  select * into strict v_settings from secondhand.market_settings s where s.id;
  return (
    select jsonb_build_object(
      'product_id', p.id,
      'title', p.title,
      'image_path', (select i.image_url from public.product_images i where i.product_id = p.id
                      order by i.is_cover desc, i.image_order limit 1),
      'price', (v_price->>'price')::numeric,
      'listed_price', p.price,
      'offer_applied', v_price->>'offer_id' is not null,
      'shipping_fee', 0,
      'handling_time_days', p.handling_time_days,
      'seller', jsonb_build_object('shop_id', p.shop_id, 'display_name', secondhand.member_name_r22(l.seller_id)),
      'problem', secondhand.checkout_problem_r22(u, p.id),
      'pay_within_hours', v_settings.payment_window_hours,
      'wallet_balance', (select w.balance from public.wallets w where w.profile_id = u and w.wallet_status = 'active'),
      'mock_payment_enabled', v_settings.mock_payment_enabled,
      'points_enabled', v_settings.points_enabled,
      'points_balance', coalesce((select b.balance from public.kao_point_balances b where b.profile_id = u), 0),
      'point_value', v_settings.point_value)
      from public.products p
      join secondhand.listings l on l.product_id = p.id
     where p.id = p_product_id and secondhand.listing_visible_r20f(p.id)
  );
end $$;

drop function secondhand.pay_order(uuid, text);

-- p_points: how many points to use. The wallet (or the test gateway) pays the rest; when points cover the whole
-- price the method is 'points'.
create function secondhand.pay_order(p_order_id uuid, p_method text, p_points integer default 0)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_product_id uuid;
  v_order public.orders;
  v_details secondhand.order_details;
  v_settings secondhand.market_settings;
  v_problem text;
  v_price jsonb;
  v_buyer_wallet public.wallets;
  v_seller_wallet uuid;
  v_escrow uuid;
  v_days integer;
  v_points integer := coalesce(p_points, 0);
  v_discount numeric(12,2) := 0;
  v_cash numeric(12,2);
begin
  select o.product_id into v_product_id from public.orders o where o.id = p_order_id and o.buyer_id = u;
  if v_product_id is null then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  -- The item first: buyers paying for the same item queue here, and the one
  -- who comes second finds the item sold and their order cancelled.
  perform 1 from public.products p where p.id = v_product_id for update;
  select * into strict v_order from public.orders o where o.id = p_order_id for update;
  select * into strict v_details from secondhand.order_details d where d.order_id = p_order_id for update;

  if v_order.order_status = 'cancelled' and v_order.cancel_reason = 'sold_to_other' then
    raise exception 'sold_to_other' using errcode = '22023';
  end if;
  if v_order.order_status <> 'pending' or v_details.pay_by <= now() then
    raise exception 'order_not_payable' using errcode = '22023';
  end if;
  v_problem := secondhand.checkout_problem_r22(u, v_order.product_id);
  if v_problem is not null then
    raise exception '%', v_problem using errcode = case when v_problem = 'not_on_sale' then '22023' else '42501' end;
  end if;
  -- The price may have moved since the order was placed (a new listing price,
  -- or this buyer's accepted offer expired or arrived).
  v_price := secondhand.offer_checkout_price_r20g(v_order.product_id, u);
  if (v_price->>'price')::numeric is distinct from v_order.total_amount then
    raise exception 'price_changed' using errcode = '22023';
  end if;
  select * into strict v_settings from secondhand.market_settings s where s.id;

  if v_points < 0 then
    raise exception 'invalid_points' using errcode = '22023';
  end if;
  if v_points > 0 then
    if not v_settings.points_enabled then
      raise exception 'points_disabled' using errcode = '42501';
    end if;
    v_discount := v_points * v_settings.point_value;
    if v_discount > v_order.total_amount then
      raise exception 'points_over_total' using errcode = '22023';
    end if;
  end if;
  v_cash := v_order.total_amount - v_discount;

  if p_method is null or p_method not in ('wallet', 'mock', 'points') or (p_method = 'points') <> (v_cash = 0) then
    raise exception 'invalid_payment_method' using errcode = '22023';
  end if;
  if p_method = 'mock' and not v_settings.mock_payment_enabled then
    raise exception 'mock_payment_disabled' using errcode = '42501';
  end if;

  -- Escrow needs both wallets; they start empty. A business shop sells into its organization's wallet.
  insert into public.wallets(profile_id) values (v_order.buyer_id) on conflict (profile_id) do nothing;
  v_seller_wallet := secondhand.shop_wallet_r27(v_order.shop_id);
  select * into strict v_buyer_wallet from public.wallets w where w.profile_id = v_order.buyer_id for update;

  if p_method = 'wallet' then
    if v_buyer_wallet.wallet_status <> 'active' or v_buyer_wallet.balance < v_cash then
      raise exception 'insufficient_balance' using errcode = '22023';
    end if;
    update public.wallets set balance = balance - v_cash, updated_at = now()
     where id = v_buyer_wallet.id;
    insert into public.wallet_transactions(wallet_id, order_id, transaction_type, amount, balance_before,
                                           balance_after, description)
    values (v_buyer_wallet.id, v_order.id, 'payment', v_cash, v_buyer_wallet.balance,
            v_buyer_wallet.balance - v_cash, 'ชำระค่าสินค้า ' || v_order.order_number);
  end if;
  if v_points > 0 then
    perform kaoid_private.kao_points_move_r35(u, 'secondhand', 'spend', -v_points, v_order.id,
                                               'ใช้พอยท์ซื้อสินค้า ' || v_order.order_number, u);
  end if;

  -- Escrow holds the full price; the points part is the platform's.
  insert into public.escrow_transactions(order_id, buyer_wallet_id, seller_wallet_id, amount, escrow_status)
  values (v_order.id, v_buyer_wallet.id, v_seller_wallet, v_order.total_amount, 'holding')
  returning id into v_escrow;
  if v_cash > 0 then
    insert into public.payment_transactions(escrow_id, payer_wallet_id, transaction_type, amount, status,
                                            reference_no, note, processed_at)
    values (v_escrow, case when p_method = 'wallet' then v_buyer_wallet.id end, 'payment', v_cash,
            'completed', v_order.order_number, p_method, now());
  end if;
  if v_discount > 0 then
    insert into public.payment_transactions(escrow_id, transaction_type, amount, status, reference_no, note,
                                            processed_at)
    values (v_escrow, 'payment', v_discount, 'completed', v_order.order_number, 'points: ' || v_points, now());
  end if;

  select coalesce(p.handling_time_days, 3) into v_days from public.products p where p.id = v_order.product_id;
  update public.orders
     set order_status = 'paid', payment_status = 'paid', escrow_status = 'holding', paid_at = now(),
         discount_amount = v_discount, updated_at = now()
   where id = v_order.id;
  update secondhand.order_details
     set payment_method = p_method, points_used = v_points, escrow_id = v_escrow,
         offer_id = (v_price->>'offer_id')::uuid, ship_by = now() + make_interval(days => v_days), updated_at = now()
   where order_id = v_order.id;

  -- Use the offer before the item turns SOLD; SOLD cancels every other open
  -- offer and every other unpaid order for the item.
  if v_price->>'offer_id' is not null then
    perform secondhand.use_price_offer_r20g((v_price->>'offer_id')::uuid, v_order.id);
  end if;
  update public.products set status = 'sold', updated_at = now() where id = v_order.product_id;

  perform secondhand.order_log_r22(v_order.id, u, 'pending', 'paid', 'paid',
                                   p_method || case when v_points > 0 then ' + ' || v_points || ' points' else '' end);
  perform secondhand.order_notify_r22(v_order.seller_id, v_order.id, 'paid', 'สินค้าของคุณขายได้แล้ว',
    'คำสั่งซื้อ ' || v_order.order_number || ': ผู้ซื้อชำระเงินแล้ว กรุณาจัดส่งภายใน ' || v_days || ' วัน');

  return jsonb_build_object('order_id', v_order.id, 'status', 'paid', 'payment_method', p_method,
                            'points_used', v_points, 'paid_cash', v_cash);
end $$;
revoke all on function secondhand.pay_order(uuid, text, integer) from public, anon;
grant execute on function secondhand.pay_order(uuid, text, integer) to authenticated;

create or replace function secondhand.cancel_order_r22(p_order_id uuid, p_actor uuid, p_by text, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
  v_details secondhand.order_details;
  v_wallet public.wallets;
  v_paid boolean;
  v_cash numeric(12,2);
begin
  select * into strict v_order from public.orders o where o.id = p_order_id for update;
  select * into strict v_details from secondhand.order_details d where d.order_id = p_order_id for update;
  if v_order.order_status not in ('pending', 'paid', 'shipped') then
    raise exception 'order_not_cancellable' using errcode = '22023';
  end if;
  v_paid := v_order.order_status in ('paid', 'shipped');
  v_cash := v_order.total_amount - coalesce(v_order.discount_amount, 0);

  if v_paid then
    if v_details.payment_method = 'wallet' and v_cash > 0 then
      select * into strict v_wallet from public.wallets w where w.profile_id = v_order.buyer_id for update;
      update public.wallets set balance = balance + v_cash, updated_at = now() where id = v_wallet.id;
      insert into public.wallet_transactions(wallet_id, order_id, transaction_type, amount, balance_before,
                                             balance_after, description)
      values (v_wallet.id, v_order.id, 'refund', v_cash, v_wallet.balance,
              v_wallet.balance + v_cash, 'คืนเงินคำสั่งซื้อ ' || v_order.order_number);
    end if;
    -- Points go back as points, never as cash.
    if v_details.points_used > 0 then
      perform kaoid_private.kao_points_move_r35(v_order.buyer_id, 'secondhand', 'refund', v_details.points_used,
                                                 v_order.id, 'คืนพอยท์คำสั่งซื้อ ' || v_order.order_number, p_actor);
    end if;
    update public.escrow_transactions set escrow_status = 'refunded', refunded_at = now()
     where id = v_details.escrow_id;
    if v_cash > 0 then
      insert into public.payment_transactions(escrow_id, receiver_wallet_id, transaction_type, amount, status,
                                              reference_no, note, processed_at)
      values (v_details.escrow_id, v_wallet.id, 'refund', v_cash, 'completed', v_order.order_number,
              case when v_details.payment_method = 'mock' then 'mock: no money moved' else 'wallet' end, now());
    end if;
    if v_details.points_used > 0 then
      insert into public.payment_transactions(escrow_id, transaction_type, amount, status, reference_no, note,
                                              processed_at)
      values (v_details.escrow_id, 'refund', coalesce(v_order.discount_amount, 0), 'completed', v_order.order_number,
              'points: ' || v_details.points_used, now());
    end if;
  end if;

  update public.orders
     set order_status = 'cancelled',
         payment_status = case when v_paid then 'refunded' else 'cancelled' end,
         escrow_status = case when v_paid then 'refunded' else 'none' end,
         cancelled_at = now(), cancel_reason = p_reason, updated_at = now()
   where id = p_order_id;
  update secondhand.order_details set cancelled_by = p_by, updated_at = now() where order_id = p_order_id;

  -- A paid order had the item SOLD: close it, the seller decides when to reopen.
  if v_paid then
    update public.products set status = 'closed', updated_at = now()
     where id = v_order.product_id and status = 'sold';
  end if;

  perform secondhand.order_log_r22(p_order_id, p_actor, v_order.order_status, 'cancelled', 'cancelled',
                                   p_by || coalesce(': ' || p_reason, ''));
  if v_paid then
    perform secondhand.order_log_r22(p_order_id, p_actor, 'cancelled', 'cancelled', 'refunded',
                                     v_details.payment_method ||
                                     case when v_details.points_used > 0
                                          then ' + ' || v_details.points_used || ' points' else '' end);
  end if;
  perform secondhand.order_notify_r22(x.profile, p_order_id, 'cancelled', 'คำสั่งซื้อถูกยกเลิก',
    'คำสั่งซื้อ ' || v_order.order_number || case p_reason
      when 'payment_timeout' then ': ไม่ได้ชำระเงินภายในเวลาที่กำหนด'
      when 'ship_overdue' then ': ผู้ขายไม่ได้จัดส่งภายในเวลาที่กำหนด'
      when 'sold_to_other' then ': มีผู้ซื้อรายอื่นชำระเงินก่อน สินค้านี้ขายแล้ว'
      when 'listing_unavailable' then ': ผู้ขายปิดการขายสินค้านี้'
      when 'price_changed' then ': ผู้ขายเปลี่ยนราคา กรุณาสั่งซื้อใหม่หากยังสนใจ'
      when 'issue_refund' then ': ทีมงานตรวจสอบปัญหาที่แจ้งแล้วและตัดสินคืนเงินให้ผู้ซื้อ'
      else ': ยกเลิกโดย' || case p_by when 'buyer' then 'ผู้ซื้อ' when 'seller' then 'ผู้ขาย'
                                    when 'staff' then 'ทีมงาน' else 'ระบบ' end end ||
    case when v_paid and v_details.payment_method = 'wallet' and v_cash > 0
         then ' คืนเงินเข้ากระเป๋าผู้ซื้อแล้ว' else '' end ||
    case when x.profile = v_order.buyer_id and v_paid and v_details.points_used > 0
         then ' คืน ' || v_details.points_used || ' พอยท์แล้ว' else '' end)
    from (values (v_order.buyer_id), (case when v_paid then v_order.seller_id end)) x(profile)
   where x.profile is not null and x.profile is distinct from p_actor;
end $$;

-- Same as R32, plus how the buyer paid: points used, their baht value, and the cash part. The seller side does
-- not see these; the seller is paid the same either way.
create or replace function secondhand.order_json_r22(p_order_id uuid, p_viewer uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id,
    'order_number', o.order_number,
    'role', case when p_viewer = o.buyer_id then 'buyer' else 'seller' end,
    'status', o.order_status,
    'payment_method', d.payment_method,
    'price', o.product_price,
    'shipping_fee', o.shipping_fee,
    'total', o.total_amount,
    'marketplace_fee', case when p_viewer <> o.buyer_id then o.marketplace_fee end,
    'points_used', case when p_viewer = o.buyer_id then d.points_used end,
    'points_discount', case when p_viewer = o.buyer_id then coalesce(o.discount_amount, 0) end,
    'paid_cash', case when p_viewer = o.buyer_id then o.total_amount - coalesce(o.discount_amount, 0) end,
    'created_at', o.created_at,
    'paid_at', o.paid_at,
    'shipped_at', o.shipped_at,
    'completed_at', o.completed_at,
    'cancelled_at', o.cancelled_at,
    'cancelled_by', d.cancelled_by,
    'cancel_reason', o.cancel_reason,
    'pay_by', d.pay_by,
    'ship_by', d.ship_by,
    'receive_by', d.receive_by,
    'carrier', o.shipping_company,
    'tracking_number', o.tracking_number,
    'offer_applied', d.offer_id is not null,
    'shop_id', o.shop_id,
    'product', jsonb_build_object(
      'id', p.id, 'title', p.title,
      'image_path', (select i.image_url from public.product_images i where i.product_id = p.id
                      order by i.is_cover desc, i.image_order limit 1)),
    'counterpart', jsonb_build_object(
      'display_name', case when p_viewer = o.buyer_id and sh.seller_identity_type = 'business' then sh.shop_name
                           else secondhand.member_name_r22(case when p_viewer = o.buyer_id then o.seller_id
                                                                else o.buyer_id end) end,
      'avatar_url', case when p_viewer = o.buyer_id and sh.seller_identity_type = 'business' then null
                         else m.avatar_url end,
      'shop_id', case when p_viewer = o.buyer_id then o.shop_id
                      else (select s.id from public.shops s where s.owner_id = o.buyer_id
                              and s.seller_identity_type = 'personal' and s.shop_status = 'active'
                            order by s.created_at limit 1) end),
    'address', case when p_viewer = o.buyer_id or o.order_status in ('paid', 'shipped', 'completed') then d.address end,
    'reviewed', exists (select 1 from secondhand.reviews r
                         where r.order_id = o.id
                           and r.reviewer_id = case when p_viewer = o.buyer_id then o.buyer_id else o.seller_id end),
    'unread_messages', coalesce((select case when p_viewer = c.buyer_id then c.buyer_unread_count
                                             else c.seller_unread_count end
                                   from public.chat_rooms c where c.order_id = o.id), 0),
    'issue', (select secondhand.order_issue_json_r26(x) from secondhand.order_issues x
               where x.order_id = o.id order by x.created_at desc limit 1),
    'can_cancel', secondhand.can_cancel_order_r26(o, d, p_viewer),
    'can_open_issue', secondhand.can_open_order_issue_r26(o, p_viewer),
    'can_manage', p_viewer <> o.buyer_id and secondhand.shop_can_r27(o.shop_id, 'orders', p_viewer),
    'can_chat', p_viewer = o.buyer_id or secondhand.shop_can_r27(o.shop_id, 'chat', p_viewer))
  from public.orders o
  join secondhand.order_details d on d.order_id = o.id
  join public.products p on p.id = o.product_id
  join public.shops sh on sh.id = o.shop_id
  left join secondhand.member_profiles m
    on m.profile_id = case when p_viewer = o.buyer_id then o.seller_id else o.buyer_id end
  where o.id = p_order_id
    and (p_viewer = o.buyer_id
         or (o.paid_at is not null
             and (secondhand.shop_can_r27(o.shop_id, 'orders', p_viewer)
                  or secondhand.shop_can_r27(o.shop_id, 'chat', p_viewer))))
$$;
