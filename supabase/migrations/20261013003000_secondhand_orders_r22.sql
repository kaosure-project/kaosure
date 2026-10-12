-- R22: orders, payment and escrow for Secondhand (no cart, Buy Now only).
--
--   * create_order() runs a triple check on the server every time:
--       1. the buyer: signed in, account active, email + phone confirmed in
--          Kao ID, not their own listing;
--       2. the relationship: neither side has blocked the other;
--       3. the item: locked row, still on sale, no open order, price from the
--          server (an accepted price offer if any), address owned by the buyer.
--     The listing shows SOLD at once and the buyer has 24 hours to pay.
--   * pay_order() takes the money into escrow, either from the buyer's
--     KaoSure Wallet (balance must cover the total) or through the mock
--     payment gateway used for testing. Mock money never reaches a wallet:
--     releasing or refunding a mock payment only records the step.
--   * The seller ships within the listing's handling time; the buyer confirms
--     receipt, or the order completes by itself 7 days after shipping and the
--     escrow is released to the seller minus the sales fee.
--   * Unpaid orders are cancelled after 24 hours and the item goes back on sale.

-- ---------------------------------------------------------------------------
-- Settings and the commission trigger
-- ---------------------------------------------------------------------------
alter table secondhand.market_settings
  add column payment_window_hours integer not null default 24 check (payment_window_hours between 1 and 168),
  add column receive_window_days integer not null default 7 check (receive_window_days between 1 and 30),
  add column mock_payment_enabled boolean not null default true;

comment on column secondhand.market_settings.mock_payment_enabled is
  'Test-only payment gateway. Turn off before real payments go live.';

-- The commission trigger records the first sale before the order row exists
-- when an order is inserted already completed.
alter table secondhand.first_sale_promotions
  alter constraint first_sale_promotions_order_id_fkey deferrable initially deferred;

-- ---------------------------------------------------------------------------
-- Secondhand details of an order
-- ---------------------------------------------------------------------------
create table secondhand.order_details (
  order_id uuid primary key references public.orders(id) on delete cascade,
  offer_id uuid references secondhand.price_offers(id) on delete set null,
  address jsonb not null,
  payment_method text check (payment_method in ('wallet', 'mock')),
  escrow_id uuid references public.escrow_transactions(id) on delete set null,
  pay_by timestamptz not null,
  ship_by timestamptz,
  receive_by timestamptz,
  cancelled_by text check (cancelled_by in ('buyer', 'seller', 'system')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index order_details_pay_by on secondhand.order_details(pay_by);
create index order_details_receive_by on secondhand.order_details(receive_by) where receive_by is not null;
create index orders_buyer_created_r22 on public.orders(buyer_id, created_at desc);
create index orders_seller_created_r22 on public.orders(seller_id, created_at desc);
create index orders_product_r22 on public.orders(product_id);

alter table secondhand.order_details enable row level security;
revoke all on secondhand.order_details from public, anon, authenticated;

-- Defence in depth: no order between members who blocked each other, and
-- nobody buys from themselves, whoever inserts the row.
create or replace function secondhand.refuse_order_r22()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.buyer_id = new.seller_id then
    raise exception 'own_listing' using errcode = '42501';
  end if;
  if secondhand.blocked_between_r21b(new.buyer_id, new.seller_id) then
    raise exception 'member_blocked' using errcode = '42501';
  end if;
  return new;
end $$;

revoke all on function secondhand.refuse_order_r22() from public, anon, authenticated;

create trigger orders_refuse_r22
  before insert on public.orders
  for each row execute function secondhand.refuse_order_r22();

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------
create or replace function secondhand.order_log_r22(
  p_order_id uuid, p_actor uuid, p_old text, p_new text, p_event text, p_note text default null
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.order_status_history(order_id, changed_by, old_status, new_status, note)
  select p_order_id, p_actor, p_old, p_new, p_note where p_old is distinct from p_new;
  insert into public.order_events(order_id, profile_id, event_type, description)
  values (p_order_id, p_actor, p_event, p_note);
$$;

create or replace function secondhand.order_notify_r22(
  p_profile uuid, p_order_id uuid, p_event text, p_title text, p_message text
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (p_profile, p_title, p_message, 'order_' || p_event, p_order_id, '/orders/' || p_order_id,
          'order_' || p_event || ':' || p_order_id || ':' || p_profile);
$$;

create or replace function secondhand.member_name_r22(p_profile uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(nullif(btrim(m.display_name), ''), secondhand.kao_id_name_r21c(p_profile))
    from (select 1) one
    left join secondhand.member_profiles m on m.profile_id = p_profile
$$;

-- Why this buyer may not order this item now, or null. Shared by the
-- checkout page and create_order().
create or replace function secondhand.checkout_problem_r22(p_buyer uuid, p_product_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_seller uuid;
begin
  select l.seller_id into v_seller
    from public.products p
    join secondhand.listings l on l.product_id = p.id
   where p.id = p_product_id;
  if v_seller is null then
    return 'not_on_sale';
  end if;
  if v_seller = p_buyer then
    return 'own_listing';
  end if;
  if not secondhand.buyer_ready_r20g(p_buyer) then
    return 'buyer_not_ready';
  end if;
  if secondhand.blocked_between_r21b(p_buyer, v_seller) then
    return 'member_blocked';
  end if;
  if not secondhand.listing_public_r20d(p_product_id)
     or exists (select 1 from public.orders o
                 where o.product_id = p_product_id
                   and o.order_status not in ('cancelled', 'completed', 'refunded')) then
    return 'not_on_sale';
  end if;
  return null;
end $$;

create or replace function secondhand.order_actor_r22()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  return u;
end $$;

-- ---------------------------------------------------------------------------
-- Checkout page
-- ---------------------------------------------------------------------------
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
      'mock_payment_enabled', v_settings.mock_payment_enabled)
      from public.products p
      join secondhand.listings l on l.product_id = p.id
     where p.id = p_product_id and secondhand.listing_visible_r20f(p.id)
  );
end $$;

-- ---------------------------------------------------------------------------
-- Create an order (triple check)
-- ---------------------------------------------------------------------------
create or replace function secondhand.create_order(p_product_id uuid, p_address_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_product public.products;
  v_seller uuid;
  v_problem text;
  v_address jsonb;
  v_price jsonb;
  v_settings secondhand.market_settings;
  v_order public.orders;
begin
  -- 3. the item: lock first so two buyers cannot pass the checks together.
  select p.* into v_product from public.products p where p.id = p_product_id for update;
  if not found then
    raise exception 'not_on_sale' using errcode = '22023';
  end if;
  select l.seller_id into v_seller from secondhand.listings l where l.product_id = p_product_id;

  -- 1. the buyer and 2. the relationship, then the rest of 3.
  v_problem := secondhand.checkout_problem_r22(u, p_product_id);
  if v_problem is not null then
    raise exception '%', v_problem using errcode = case when v_problem = 'not_on_sale' then '22023' else '42501' end;
  end if;

  select jsonb_build_object(
           'recipient_name', a.recipient_name, 'phone', a.phone, 'postal_code', a.postal_code,
           'province', a.province, 'district', a.district, 'subdistrict', a.subdistrict,
           'address_line1', a.address_line1, 'address_line2', a.address_line2, 'delivery_note', a.delivery_note)
    into v_address
    from secondhand.shipping_addresses a
   where a.id = p_address_id and a.profile_id = u and a.address_type = 'shipping';
  if v_address is null then
    raise exception 'address_required' using errcode = '22023';
  end if;

  v_price := secondhand.offer_checkout_price_r20g(p_product_id, u);
  select * into strict v_settings from secondhand.market_settings s where s.id;

  insert into public.orders(order_number, product_id, buyer_id, seller_id, shop_id, product_price, shipping_fee,
                            discount_amount, marketplace_fee, total_amount, payment_status, order_status, escrow_status)
  values ('SH' || to_char(now() at time zone 'Asia/Bangkok', 'YYMMDD') || '-' ||
            upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
          p_product_id, u, v_seller, v_product.shop_id, (v_price->>'price')::numeric, 0,
          0, 0, (v_price->>'price')::numeric, 'pending', 'pending', 'none')
  returning * into v_order;

  insert into secondhand.order_details(order_id, offer_id, address, pay_by)
  values (v_order.id, (v_price->>'offer_id')::uuid, v_address,
          now() + make_interval(hours => v_settings.payment_window_hours));

  -- Use the offer before the item turns SOLD, which cancels open offers.
  if v_price->>'offer_id' is not null then
    perform secondhand.use_price_offer_r20g((v_price->>'offer_id')::uuid, v_order.id);
  end if;
  update public.products set status = 'sold', updated_at = now() where id = p_product_id;

  perform secondhand.order_log_r22(v_order.id, u, null, 'pending', 'created');
  perform secondhand.order_notify_r22(v_seller, v_order.id, 'created', 'มีคำสั่งซื้อใหม่',
    left(v_product.title, 80) || ': รอผู้ซื้อชำระเงินภายใน ' || v_settings.payment_window_hours || ' ชั่วโมง');

  return jsonb_build_object('order_id', v_order.id, 'order_number', v_order.order_number,
                            'total', v_order.total_amount,
                            'pay_by', now() + make_interval(hours => v_settings.payment_window_hours));
end $$;

-- ---------------------------------------------------------------------------
-- Pay into escrow: KaoSure Wallet or the mock gateway
-- ---------------------------------------------------------------------------
create or replace function secondhand.pay_order(p_order_id uuid, p_method text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_order public.orders;
  v_details secondhand.order_details;
  v_settings secondhand.market_settings;
  v_buyer_wallet public.wallets;
  v_seller_wallet uuid;
  v_escrow uuid;
  v_days integer;
begin
  select * into v_order from public.orders o where o.id = p_order_id and o.buyer_id = u for update;
  if not found then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  select * into strict v_details from secondhand.order_details d where d.order_id = p_order_id for update;
  if v_order.order_status <> 'pending' or v_details.pay_by <= now() then
    raise exception 'order_not_payable' using errcode = '22023';
  end if;
  if secondhand.blocked_between_r21b(v_order.buyer_id, v_order.seller_id) then
    raise exception 'member_blocked' using errcode = '42501';
  end if;
  if p_method is null or p_method not in ('wallet', 'mock') then
    raise exception 'invalid_payment_method' using errcode = '22023';
  end if;
  select * into strict v_settings from secondhand.market_settings s where s.id;
  if p_method = 'mock' and not v_settings.mock_payment_enabled then
    raise exception 'mock_payment_disabled' using errcode = '42501';
  end if;

  -- Escrow needs both wallets; they start empty.
  insert into public.wallets(profile_id) values (v_order.buyer_id), (v_order.seller_id)
  on conflict (profile_id) do nothing;
  select * into strict v_buyer_wallet from public.wallets w where w.profile_id = v_order.buyer_id for update;
  select w.id into strict v_seller_wallet from public.wallets w where w.profile_id = v_order.seller_id;

  if p_method = 'wallet' then
    if v_buyer_wallet.wallet_status <> 'active' or v_buyer_wallet.balance < v_order.total_amount then
      raise exception 'insufficient_balance' using errcode = '22023';
    end if;
    update public.wallets set balance = balance - v_order.total_amount, updated_at = now()
     where id = v_buyer_wallet.id;
    insert into public.wallet_transactions(wallet_id, order_id, transaction_type, amount, balance_before,
                                           balance_after, description)
    values (v_buyer_wallet.id, v_order.id, 'payment', v_order.total_amount, v_buyer_wallet.balance,
            v_buyer_wallet.balance - v_order.total_amount, 'ชำระค่าสินค้า ' || v_order.order_number);
  end if;

  insert into public.escrow_transactions(order_id, buyer_wallet_id, seller_wallet_id, amount, escrow_status)
  values (v_order.id, v_buyer_wallet.id, v_seller_wallet, v_order.total_amount, 'holding')
  returning id into v_escrow;
  insert into public.payment_transactions(escrow_id, payer_wallet_id, transaction_type, amount, status,
                                          reference_no, note, processed_at)
  values (v_escrow, case when p_method = 'wallet' then v_buyer_wallet.id end, 'payment', v_order.total_amount,
          'completed', v_order.order_number, p_method, now());

  select coalesce(p.handling_time_days, 3) into v_days from public.products p where p.id = v_order.product_id;
  update public.orders
     set order_status = 'paid', payment_status = 'paid', escrow_status = 'holding', paid_at = now(), updated_at = now()
   where id = v_order.id;
  update secondhand.order_details
     set payment_method = p_method, escrow_id = v_escrow, ship_by = now() + make_interval(days => v_days),
         updated_at = now()
   where order_id = v_order.id;

  perform secondhand.order_log_r22(v_order.id, u, 'pending', 'paid', 'paid', p_method);
  perform secondhand.order_notify_r22(v_order.seller_id, v_order.id, 'paid', 'ผู้ซื้อชำระเงินแล้ว',
    'คำสั่งซื้อ ' || v_order.order_number || ': กรุณาจัดส่งภายใน ' || v_days || ' วัน');

  return jsonb_build_object('order_id', v_order.id, 'status', 'paid', 'payment_method', p_method);
end $$;

-- ---------------------------------------------------------------------------
-- Completion and cancellation (internal; called by RPCs and the timer)
-- ---------------------------------------------------------------------------
create or replace function secondhand.complete_order_r22(p_order_id uuid, p_actor uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
  v_details secondhand.order_details;
  v_wallet public.wallets;
  v_net numeric;
begin
  select * into strict v_order from public.orders o where o.id = p_order_id for update;
  select * into strict v_details from secondhand.order_details d where d.order_id = p_order_id for update;
  if v_order.order_status <> 'shipped' then
    raise exception 'order_not_receivable' using errcode = '22023';
  end if;

  -- The commission trigger sets marketplace_fee on completion.
  update public.orders
     set order_status = 'completed', escrow_status = 'released', delivered_at = coalesce(delivered_at, now()),
         completed_at = now(), updated_at = now()
   where id = p_order_id
  returning * into v_order;
  v_net := greatest(v_order.total_amount - v_order.marketplace_fee, 0);

  update public.escrow_transactions set escrow_status = 'released', released_at = now() where id = v_details.escrow_id;

  if v_details.payment_method = 'wallet' then
    select * into strict v_wallet from public.wallets w where w.profile_id = v_order.seller_id for update;
    update public.wallets set balance = balance + v_net, updated_at = now() where id = v_wallet.id;
    insert into public.wallet_transactions(wallet_id, order_id, transaction_type, amount, balance_before,
                                           balance_after, description)
    values (v_wallet.id, v_order.id, 'sale', v_net, v_wallet.balance, v_wallet.balance + v_net,
            'รายได้จากการขาย ' || v_order.order_number);
  end if;
  insert into public.payment_transactions(escrow_id, receiver_wallet_id, transaction_type, amount, status,
                                          reference_no, note, processed_at)
  select v_details.escrow_id,
         case when v_details.payment_method = 'wallet'
              then (select w.id from public.wallets w where w.profile_id = v_order.seller_id) end,
         x.kind, x.amount, 'completed', v_order.order_number,
         case when v_details.payment_method = 'mock' then 'mock: no money moved' else 'wallet' end, now()
    from (values ('release', v_net), ('fee', v_order.marketplace_fee)) x(kind, amount)
   where x.amount > 0 or x.kind = 'release';

  perform secondhand.order_log_r22(p_order_id, p_actor, 'shipped', 'completed', 'completed',
                                   case when p_actor is null then 'auto' end);
  perform secondhand.order_log_r22(p_order_id, p_actor, 'completed', 'completed', 'escrow_released',
                                   v_details.payment_method);
  perform secondhand.order_notify_r22(v_order.seller_id, p_order_id, 'completed', 'การซื้อขายเสร็จสมบูรณ์',
    'คำสั่งซื้อ ' || v_order.order_number || ': ' ||
    case when v_details.payment_method = 'mock' then 'ชำระแบบจำลอง จึงไม่มีเงินเข้ากระเป๋า'
         else 'โอนรายได้เข้ากระเป๋าแล้ว' end || ' อย่าลืมประเมินผู้ซื้อ');
  perform secondhand.order_notify_r22(v_order.buyer_id, p_order_id, 'completed', 'การซื้อขายเสร็จสมบูรณ์',
    'คำสั่งซื้อ ' || v_order.order_number || ': อย่าลืมประเมินผู้ขาย');
end $$;

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
begin
  select * into strict v_order from public.orders o where o.id = p_order_id for update;
  select * into strict v_details from secondhand.order_details d where d.order_id = p_order_id for update;
  if v_order.order_status not in ('pending', 'paid') then
    raise exception 'order_not_cancellable' using errcode = '22023';
  end if;
  v_paid := v_order.order_status = 'paid';

  if v_paid then
    if v_details.payment_method = 'wallet' then
      select * into strict v_wallet from public.wallets w where w.profile_id = v_order.buyer_id for update;
      update public.wallets set balance = balance + v_order.total_amount, updated_at = now() where id = v_wallet.id;
      insert into public.wallet_transactions(wallet_id, order_id, transaction_type, amount, balance_before,
                                             balance_after, description)
      values (v_wallet.id, v_order.id, 'refund', v_order.total_amount, v_wallet.balance,
              v_wallet.balance + v_order.total_amount, 'คืนเงินคำสั่งซื้อ ' || v_order.order_number);
    end if;
    update public.escrow_transactions set escrow_status = 'refunded', refunded_at = now()
     where id = v_details.escrow_id;
    insert into public.payment_transactions(escrow_id, receiver_wallet_id, transaction_type, amount, status,
                                            reference_no, note, processed_at)
    values (v_details.escrow_id, v_wallet.id, 'refund', v_order.total_amount, 'completed', v_order.order_number,
            case when v_details.payment_method = 'mock' then 'mock: no money moved' else 'wallet' end, now());
  end if;

  update public.orders
     set order_status = 'cancelled',
         payment_status = case when v_paid then 'refunded' else 'cancelled' end,
         escrow_status = case when v_paid then 'refunded' else 'none' end,
         cancelled_at = now(), cancel_reason = p_reason, updated_at = now()
   where id = p_order_id;
  update secondhand.order_details set cancelled_by = p_by, updated_at = now() where order_id = p_order_id;

  -- Unpaid: back on sale. Paid: closed, the seller decides when to reopen.
  update public.products
     set status = case when v_paid then 'closed' else 'active' end, updated_at = now()
   where id = v_order.product_id and status = 'sold';

  perform secondhand.order_log_r22(p_order_id, p_actor, v_order.order_status, 'cancelled', 'cancelled',
                                   p_by || coalesce(': ' || p_reason, ''));
  if v_paid then
    perform secondhand.order_log_r22(p_order_id, p_actor, 'cancelled', 'cancelled', 'refunded',
                                     v_details.payment_method);
  end if;
  perform secondhand.order_notify_r22(x.profile, p_order_id, 'cancelled', 'คำสั่งซื้อถูกยกเลิก',
    'คำสั่งซื้อ ' || v_order.order_number || case p_reason
      when 'payment_timeout' then ': ไม่ได้ชำระเงินภายในเวลาที่กำหนด'
      when 'ship_overdue' then ': ผู้ขายไม่ได้จัดส่งภายในเวลาที่กำหนด'
      else ': ยกเลิกโดย' || case p_by when 'buyer' then 'ผู้ซื้อ' when 'seller' then 'ผู้ขาย' else 'ระบบ' end end ||
    case when v_paid and v_details.payment_method = 'wallet' then ' คืนเงินเข้ากระเป๋าผู้ซื้อแล้ว' else '' end)
    from (values (v_order.buyer_id), (v_order.seller_id)) x(profile)
   where x.profile is distinct from p_actor;
end $$;

-- ---------------------------------------------------------------------------
-- Member actions
-- ---------------------------------------------------------------------------
create or replace function secondhand.mark_shipped(p_order_id uuid, p_carrier text, p_tracking text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_order public.orders;
  v_carrier text := nullif(btrim(coalesce(p_carrier, '')), '');
  v_tracking text := nullif(btrim(coalesce(p_tracking, '')), '');
  v_settings secondhand.market_settings;
begin
  select * into v_order from public.orders o where o.id = p_order_id and o.seller_id = u for update;
  if not found then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  if v_order.order_status <> 'paid' then
    raise exception 'order_not_shippable' using errcode = '22023';
  end if;
  if v_carrier is null or char_length(v_carrier) > 60 or char_length(coalesce(v_tracking, '')) > 60 then
    raise exception 'invalid_shipment' using errcode = '22023';
  end if;
  select * into strict v_settings from secondhand.market_settings s where s.id;

  update public.orders
     set order_status = 'shipped', shipped_at = now(), shipping_company = v_carrier, tracking_number = v_tracking,
         updated_at = now()
   where id = p_order_id;
  update secondhand.order_details
     set receive_by = now() + make_interval(days => v_settings.receive_window_days), updated_at = now()
   where order_id = p_order_id;

  perform secondhand.order_log_r22(p_order_id, u, 'paid', 'shipped', 'shipped',
                                   v_carrier || coalesce(' ' || v_tracking, ''));
  perform secondhand.order_notify_r22(v_order.buyer_id, p_order_id, 'shipped', 'ผู้ขายจัดส่งสินค้าแล้ว',
    'คำสั่งซื้อ ' || v_order.order_number || ': ได้รับของแล้วกรุณากดยืนยัน ระบบจะยืนยันให้อัตโนมัติใน '
      || v_settings.receive_window_days || ' วัน');
  return jsonb_build_object('order_id', p_order_id, 'status', 'shipped');
end $$;

create or replace function secondhand.confirm_received(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
begin
  if not exists (select 1 from public.orders o where o.id = p_order_id and o.buyer_id = u) then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  perform secondhand.complete_order_r22(p_order_id, u);
  return jsonb_build_object('order_id', p_order_id, 'status', 'completed');
end $$;

create or replace function secondhand.cancel_order(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_order public.orders;
  v_details secondhand.order_details;
  v_by text;
  v_reason text;
begin
  select * into v_order from public.orders o where o.id = p_order_id and u in (o.buyer_id, o.seller_id) for update;
  if not found then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  select * into strict v_details from secondhand.order_details d where d.order_id = p_order_id;
  v_by := case when u = v_order.buyer_id then 'buyer' else 'seller' end;

  -- Before payment either side may cancel; after payment the seller may, and
  -- the buyer only once the shipping deadline has passed.
  if v_order.order_status = 'pending' then
    v_reason := null;
  elsif v_order.order_status = 'paid' and v_by = 'seller' then
    v_reason := null;
  elsif v_order.order_status = 'paid' and v_by = 'buyer' and v_details.ship_by < now() then
    v_reason := 'ship_overdue';
  else
    raise exception 'order_not_cancellable' using errcode = '22023';
  end if;

  perform secondhand.cancel_order_r22(p_order_id, u, v_by, v_reason);
  return jsonb_build_object('order_id', p_order_id, 'status', 'cancelled');
end $$;

-- ---------------------------------------------------------------------------
-- Timers: unpaid after 24 hours, auto-receipt 7 days after shipping
-- ---------------------------------------------------------------------------
create or replace function secondhand.run_order_timeouts_r22()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
  n integer := 0;
begin
  for r in
    select o.id from public.orders o join secondhand.order_details d on d.order_id = o.id
     where o.order_status = 'pending' and d.pay_by <= now()
     order by d.pay_by
     for update of o skip locked
  loop
    perform secondhand.cancel_order_r22(r.id, null, 'system', 'payment_timeout');
    n := n + 1;
  end loop;
  for r in
    select o.id from public.orders o join secondhand.order_details d on d.order_id = o.id
     where o.order_status = 'shipped' and d.receive_by <= now()
     order by d.receive_by
     for update of o skip locked
  loop
    perform secondhand.complete_order_r22(r.id, null);
    n := n + 1;
  end loop;
  return n;
end $$;

select cron.schedule('secondhand-order-timeouts-r22', '*/10 * * * *', 'select secondhand.run_order_timeouts_r22();');

-- ---------------------------------------------------------------------------
-- Reads
-- ---------------------------------------------------------------------------
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
    'marketplace_fee', case when p_viewer = o.seller_id then o.marketplace_fee end,
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
    'product', jsonb_build_object(
      'id', p.id, 'title', p.title,
      'image_path', (select i.image_url from public.product_images i where i.product_id = p.id
                      order by i.is_cover desc, i.image_order limit 1)),
    'counterpart', jsonb_build_object(
      'display_name', secondhand.member_name_r22(case when p_viewer = o.buyer_id then o.seller_id else o.buyer_id end),
      'avatar_url', m.avatar_url,
      'shop_id', case when p_viewer = o.buyer_id then o.shop_id
                      else (select s.id from public.shops s where s.owner_id = o.buyer_id
                              and s.seller_identity_type = 'personal' and s.shop_status = 'active'
                            order by s.created_at limit 1) end),
    -- The seller sees where to ship only once the buyer has paid.
    'address', case when p_viewer = o.buyer_id or o.order_status in ('paid', 'shipped', 'completed') then d.address end,
    'reviewed', exists (select 1 from secondhand.reviews r where r.order_id = o.id and r.reviewer_id = p_viewer))
  from public.orders o
  join secondhand.order_details d on d.order_id = o.id
  join public.products p on p.id = o.product_id
  left join secondhand.member_profiles m
    on m.profile_id = case when p_viewer = o.buyer_id then o.seller_id else o.buyer_id end
  where o.id = p_order_id and p_viewer in (o.buyer_id, o.seller_id)
$$;

create or replace function secondhand.get_order(p_order_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v jsonb := secondhand.order_json_r22(p_order_id, u);
  v_settings secondhand.market_settings;
begin
  if v is null then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  select * into strict v_settings from secondhand.market_settings s where s.id;
  return v || jsonb_build_object(
    'wallet_balance', case when v->>'role' = 'buyer' and v->>'status' = 'pending'
                           then (select w.balance from public.wallets w where w.profile_id = u and w.wallet_status = 'active') end,
    'mock_payment_enabled', v_settings.mock_payment_enabled,
    'history', (select coalesce(jsonb_agg(jsonb_build_object('status', h.new_status, 'at', h.created_at)
                                          order by h.created_at), '[]'::jsonb)
                  from public.order_status_history h where h.order_id = p_order_id));
end $$;

create or replace function secondhand.list_my_orders(
  p_role text, p_before timestamptz default null, p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_items jsonb;
  v_more boolean;
begin
  if p_role is null or p_role not in ('buyer', 'seller') then
    raise exception 'invalid_filter' using errcode = '22023';
  end if;
  select coalesce(jsonb_agg(secondhand.order_json_r22(x.id, u) order by x.created_at desc, x.id desc), '[]'::jsonb)
    into v_items
    from (select o.id, o.created_at from public.orders o
           where (case when p_role = 'buyer' then o.buyer_id else o.seller_id end) = u
             and exists (select 1 from secondhand.order_details d where d.order_id = o.id)
             and (p_before is null or o.created_at < p_before)
           order by o.created_at desc, o.id desc
           limit v_limit + 1) x;
  v_more := jsonb_array_length(v_items) > v_limit;
  if v_more then
    v_items := v_items - v_limit;
  end if;
  return jsonb_build_object('orders', v_items, 'has_more', v_more);
end $$;

-- ---------------------------------------------------------------------------
-- My Page to-do: pay, ship, confirm receipt
-- ---------------------------------------------------------------------------
create or replace function secondhand.get_my_page()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
  v_shop uuid;
  v_todo jsonb;
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.data_access_r10d() then
    raise exception 'Account unavailable' using errcode = '42501';
  end if;

  select s.id into v_shop
    from public.shops s
   where s.owner_id = u and s.seller_identity_type = 'personal'
   order by s.created_at
   limit 1;

  select coalesce(jsonb_agg(t.item order by t.ord), '[]'::jsonb) into v_todo
    from (
      select 0 as ord, count(*) as n, jsonb_build_object(
               'code', 'pay_orders', 'count', count(*),
               'order_id', (array_agg(o.id order by d.pay_by))[1],
               'due_at', min(d.pay_by)) as item
        from public.orders o join secondhand.order_details d on d.order_id = o.id
       where o.buyer_id = u and o.order_status = 'pending' and d.pay_by > now()
      union all
      select 0, count(*), jsonb_build_object(
               'code', 'ship_orders', 'count', count(*),
               'order_id', (array_agg(o.id order by d.ship_by))[1],
               'due_at', min(d.ship_by))
        from public.orders o join secondhand.order_details d on d.order_id = o.id
       where o.seller_id = u and o.order_status = 'paid'
      union all
      select 0, count(*), jsonb_build_object(
               'code', 'confirm_receipt', 'count', count(*),
               'order_id', (array_agg(o.id order by d.receive_by))[1],
               'due_at', min(d.receive_by))
        from public.orders o join secondhand.order_details d on d.order_id = o.id
       where o.buyer_id = u and o.order_status = 'shipped'
      union all
      select 1, count(*), jsonb_build_object(
               'code', 'answer_offers', 'count', count(*),
               'product_id', (array_agg(o.product_id order by o.expires_at))[1],
               'due_at', min(o.expires_at))
        from secondhand.price_offers o
       where o.seller_id = u and o.status = 'pending' and o.expires_at > now()
      union all
      select 2, count(*), jsonb_build_object(
               'code', 'buy_offer', 'count', count(*),
               'product_id', (array_agg(o.product_id order by o.purchase_expires_at))[1],
               'due_at', min(o.purchase_expires_at))
        from secondhand.price_offers o
       where o.buyer_id = u and o.status = 'accepted' and o.purchase_expires_at > now()
      union all
      select 3, count(*), jsonb_build_object(
               'code', 'answer_questions', 'count', count(*),
               'product_id', (array_agg(q.product_id order by q.created_at))[1],
               'since', min(q.created_at))
        from secondhand.listing_questions q
        join public.products p on p.id = q.product_id
        join secondhand.listings l on l.product_id = p.id
       where l.seller_id = u and q.answer is null and not q.is_hidden and p.status = 'active'
      union all
      select 4, count(*), jsonb_build_object(
               'code', 'write_reviews', 'count', count(*),
               'order_id', (array_agg(o.id order by coalesce(o.completed_at, o.created_at)))[1])
        from public.orders o
       where u in (o.buyer_id, o.seller_id)
         and (o.order_status = 'completed' or o.completed_at is not null)
         and not exists (select 1 from secondhand.reviews r where r.order_id = o.id and r.reviewer_id = u)
      union all
      select 5, count(*), jsonb_build_object('code', 'unread_notifications', 'count', count(*))
        from public.notifications n
       where n.profile_id = u and not coalesce(n.is_read, false) and not coalesce(n.is_deleted, false)
         and (n.expires_at is null or n.expires_at > now())
    ) t
   where t.n > 0;

  return jsonb_build_object(
    'profile', (
      select jsonb_build_object(
        'display_name', coalesce(nullif(btrim(m.display_name), ''), nullif(btrim(p.display_name), ''), 'สมาชิก KaoSure'),
        'avatar_url', m.avatar_url,
        'bio', m.bio,
        'joined_at', coalesce(m.created_at, p.created_at),
        'shop_id', v_shop)
        from public.profiles p
        left join secondhand.member_profiles m on m.profile_id = p.id
       where p.id = u),
    'account_active', kaoid_private.account_active_r9f(),
    'seller_status', secondhand.seller_status_r20f(u),
    'rating', (
      select jsonb_build_object(
        'rating', r.rating,
        'review_count', coalesce(r.review_count, 0),
        'good_count', coalesce(r.good_count, 0),
        'bad_count', coalesce(r.bad_count, 0))
        from (select 1) one
        left join secondhand.member_ratings r on r.profile_id = u),
    'wallet', (
      select jsonb_build_object('balance', w.balance, 'hold_balance', w.hold_balance,
                                'currency', w.currency, 'status', w.wallet_status)
        from public.wallets w where w.profile_id = u),
    'counts', jsonb_build_object(
      'on_sale', (select count(*) from public.products p join secondhand.listings l on l.product_id = p.id
                   where l.seller_id = u and p.status = 'active' and p.is_active and p.stock > 0),
      'closed', (select count(*) from public.products p join secondhand.listings l on l.product_id = p.id
                  where l.seller_id = u and p.status = 'closed'),
      'selling', (select count(*) from public.orders o where o.seller_id = u
                   and coalesce(o.order_status, 'pending') not in ('cancelled', 'completed', 'refunded')),
      'sold', (select count(*) from public.orders o where o.seller_id = u and o.order_status = 'completed'),
      'buying', (select count(*) from public.orders o where o.buyer_id = u
                  and coalesce(o.order_status, 'pending') not in ('cancelled', 'completed', 'refunded')),
      'purchased', (select count(*) from public.orders o where o.buyer_id = u and o.order_status = 'completed'),
      'favorites', (select count(*) from public.favorites f where f.profile_id = u),
      'following', (select count(*) from public.followers f where f.profile_id = u),
      'drafts', (select count(*) from secondhand.listing_drafts d where d.seller_id = u),
      'unread_notifications', (select count(*) from public.notifications n
                                where n.profile_id = u and not coalesce(n.is_read, false)
                                  and not coalesce(n.is_deleted, false)
                                  and (n.expires_at is null or n.expires_at > now())),
      'shipping_addresses', (select count(*) from secondhand.shipping_addresses a
                              where a.profile_id = u and a.address_type = 'shipping'),
      'return_addresses', (select count(*) from secondhand.shipping_addresses a
                            where a.profile_id = u and a.address_type = 'return'),
      'blocked_users', (select count(*) from public.user_blocks b
                         where b.blocker_profile_id = u and coalesce(b.is_active, true)
                           and (b.expires_at is null or b.expires_at > now()))),
    'todo', v_todo
  );
end $$;

-- ---------------------------------------------------------------------------
-- Grants and the Secondhand token scope
-- ---------------------------------------------------------------------------
revoke all on function secondhand.order_log_r22(uuid, uuid, text, text, text, text) from public, anon, authenticated;
revoke all on function secondhand.order_notify_r22(uuid, uuid, text, text, text) from public, anon, authenticated;
revoke all on function secondhand.member_name_r22(uuid) from public, anon, authenticated;
revoke all on function secondhand.checkout_problem_r22(uuid, uuid) from public, anon, authenticated;
revoke all on function secondhand.order_actor_r22() from public, anon, authenticated;
revoke all on function secondhand.complete_order_r22(uuid, uuid) from public, anon, authenticated;
revoke all on function secondhand.cancel_order_r22(uuid, uuid, text, text) from public, anon, authenticated;
revoke all on function secondhand.run_order_timeouts_r22() from public, anon, authenticated;
revoke all on function secondhand.order_json_r22(uuid, uuid) from public, anon, authenticated;

revoke all on function secondhand.get_checkout(uuid) from public, anon, authenticated;
revoke all on function secondhand.create_order(uuid, uuid) from public, anon, authenticated;
revoke all on function secondhand.pay_order(uuid, text) from public, anon, authenticated;
revoke all on function secondhand.mark_shipped(uuid, text, text) from public, anon, authenticated;
revoke all on function secondhand.confirm_received(uuid) from public, anon, authenticated;
revoke all on function secondhand.cancel_order(uuid) from public, anon, authenticated;
revoke all on function secondhand.get_order(uuid) from public, anon, authenticated;
revoke all on function secondhand.list_my_orders(text, timestamptz, integer) from public, anon, authenticated;
revoke all on function secondhand.get_my_page() from public, anon, authenticated;

grant execute on function secondhand.get_checkout(uuid) to authenticated;
grant execute on function secondhand.create_order(uuid, uuid) to authenticated;
grant execute on function secondhand.pay_order(uuid, text) to authenticated;
grant execute on function secondhand.mark_shipped(uuid, text, text) to authenticated;
grant execute on function secondhand.confirm_received(uuid) to authenticated;
grant execute on function secondhand.cancel_order(uuid) to authenticated;
grant execute on function secondhand.get_order(uuid) to authenticated;
grant execute on function secondhand.list_my_orders(text, timestamptz, integer) to authenticated;
grant execute on function secondhand.get_my_page() to authenticated;

update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
                              'secondhand.get_checkout', 'secondhand.create_order', 'secondhand.pay_order',
                              'secondhand.mark_shipped', 'secondhand.confirm_received', 'secondhand.cancel_order',
                              'secondhand.get_order', 'secondhand.list_my_orders']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
