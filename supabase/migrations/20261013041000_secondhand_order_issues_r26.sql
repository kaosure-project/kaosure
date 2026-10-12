-- R26: cancelling an order and reporting a problem after shipping (Mercari).
--
-- Cancelling
--   * Buyer: an unpaid order any time; a paid order once the seller missed the
--     shipping deadline ("ขอยกเลิกคำสั่งซื้อ"). The full amount returns to the
--     buyer's wallet at once.
--   * Seller: any time before the buyer confirms receipt, also after shipping.
--     The buyer is refunded at once and the item turns closed (unlisted).
--   * Mock payments still move no money.
--
-- Problems after shipping
--   * The buyer reports "สินค้าไม่ถึงมือ", "สินค้าชำรุด/ไม่ตรงปก" or
--     "ขอยกเลิกคำสั่งซื้อ". Nothing is refunded yet: escrow is held (disputed),
--     auto-receipt stops and the seller is told. One open report per order.
--   * It ends when the buyer withdraws it or confirms receipt, the seller
--     cancels and refunds, or staff with marketplace.orders.resolve decide in
--     the Admin Hub (fresh MFA, activity log): refund the buyer, release the
--     money to the seller, or dismiss it so the order carries on.

-- ---------------------------------------------------------------------------
-- Permission
-- ---------------------------------------------------------------------------
insert into public.permissions
  (category, resource, action, code, name, description, scope, sort_order,
   is_active, is_dangerous, is_immutable, is_deprecated)
values
  ('Marketplace', 'orders', 'resolve', 'marketplace.orders.resolve', 'Marketplace Orders Resolve',
   'Review problems reported on orders and refund the buyer or release the money to the seller.', 'global', 340,
   true, true, false, false)
on conflict (code) do update
set is_active = true, is_deprecated = false, updated_at = now();

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
  from public.admin_roles r
 cross join public.permissions p
 where r.code in ('admin', 'super_admin') and r.is_active
   and p.code = 'marketplace.orders.resolve' and p.is_active
   and not exists (select 1 from public.role_permissions rp where rp.role_id = r.id and rp.permission_id = p.id);

-- ---------------------------------------------------------------------------
-- Problems reported on an order
-- ---------------------------------------------------------------------------
alter table secondhand.order_details drop constraint order_details_cancelled_by_check;
alter table secondhand.order_details add constraint order_details_cancelled_by_check
  check (cancelled_by in ('buyer', 'seller', 'system', 'staff'));

create table secondhand.order_issues (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  opened_by uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('not_arrived', 'not_as_described', 'cancel_request')),
  detail text check (char_length(detail) <= 1000),
  issue_status text not null default 'open'
    check (issue_status in ('open', 'withdrawn', 'refunded', 'released', 'dismissed')),
  resolution_note text check (char_length(resolution_note) <= 500),
  resolved_by uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  check ((issue_status = 'open') = (resolved_at is null))
);
create unique index order_issues_open_r26 on secondhand.order_issues(order_id) where issue_status = 'open';
create index order_issues_order_r26 on secondhand.order_issues(order_id, created_at desc);
create index order_issues_queue_r26 on secondhand.order_issues(created_at desc) where issue_status = 'open';

alter table secondhand.order_issues enable row level security;
revoke all on table secondhand.order_issues from public, anon, authenticated;
grant all on table secondhand.order_issues to service_role;

create or replace function secondhand.order_issue_kind_th_r26(p_kind text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case p_kind when 'not_arrived' then 'สินค้าไม่ถึงมือ'
                     when 'not_as_described' then 'สินค้าชำรุด/ไม่ตรงปก'
                     else 'ขอยกเลิกคำสั่งซื้อ' end;
$$;

create or replace function secondhand.order_issue_json_r26(i secondhand.order_issues)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select jsonb_build_object('id', i.id, 'kind', i.kind, 'detail', i.detail, 'status', i.issue_status,
                            'resolution_note', i.resolution_note, 'created_at', i.created_at,
                            'resolved_at', i.resolved_at);
$$;

-- One notification per issue, status and member.
create or replace function secondhand.order_issue_notify_r26(
  p_profile uuid, i secondhand.order_issues, p_key text, p_values jsonb, p_title text, p_body text)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (p_profile,
          kaoid_private.content_message_r24(p_key, 'title', null, p_title),
          kaoid_private.content_message_r24(p_key, 'body', p_values, p_body),
          'order_issue', i.order_id, '/orders/' || i.order_id,
          'order_issue:' || i.id || ':' || i.issue_status || ':' || p_profile)
  on conflict (event_key) where event_key is not null do nothing;
$$;

-- Ends the hold: escrow goes back to holding and the buyer gets at least
-- 3 more days before the auto-receipt.
create or replace function secondhand.order_issue_unhold_r26(p_order_id uuid, p_receive_by timestamptz)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.escrow_transactions e
     set escrow_status = 'holding', updated_at = now()
    from secondhand.order_details d
   where d.order_id = p_order_id and e.id = d.escrow_id and e.escrow_status = 'disputed';
  update secondhand.order_details
     set receive_by = greatest(coalesce(receive_by, now()), p_receive_by), updated_at = now()
   where order_id = p_order_id;
$$;

-- Completing or cancelling an order settles its open report, whoever did it.
create or replace function secondhand.order_issues_settle_r26()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update secondhand.order_issues
     set issue_status = case when new.order_status = 'completed' then 'released' else 'refunded' end,
         resolved_by = auth.uid(), resolved_at = now()
   where order_id = new.id and issue_status = 'open';
  return null;
end $$;

create trigger orders_issues_r26
after update of order_status on public.orders
for each row
when (new.order_status in ('completed', 'cancelled') and old.order_status is distinct from new.order_status)
execute function secondhand.order_issues_settle_r26();

-- ---------------------------------------------------------------------------
-- Cancelling: also after shipping, until the buyer confirms receipt
-- ---------------------------------------------------------------------------
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
  if v_order.order_status not in ('pending', 'paid', 'shipped') then
    raise exception 'order_not_cancellable' using errcode = '22023';
  end if;
  v_paid := v_order.order_status in ('paid', 'shipped');

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

  -- A paid order had the item SOLD: close it, the seller decides when to reopen.
  if v_paid then
    update public.products set status = 'closed', updated_at = now()
     where id = v_order.product_id and status = 'sold';
  end if;

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
      when 'sold_to_other' then ': มีผู้ซื้อรายอื่นชำระเงินก่อน สินค้านี้ขายแล้ว'
      when 'listing_unavailable' then ': ผู้ขายปิดการขายสินค้านี้'
      when 'price_changed' then ': ผู้ขายเปลี่ยนราคา กรุณาสั่งซื้อใหม่หากยังสนใจ'
      when 'issue_refund' then ': ทีมงานตรวจสอบปัญหาที่แจ้งแล้วและตัดสินคืนเงินให้ผู้ซื้อ'
      else ': ยกเลิกโดย' || case p_by when 'buyer' then 'ผู้ซื้อ' when 'seller' then 'ผู้ขาย'
                                    when 'staff' then 'ทีมงาน' else 'ระบบ' end end ||
    case when v_paid and v_details.payment_method = 'wallet' then ' คืนเงินเข้ากระเป๋าผู้ซื้อแล้ว' else '' end)
    from (values (v_order.buyer_id), (case when v_paid then v_order.seller_id end)) x(profile)
   where x.profile is not null and x.profile is distinct from p_actor;
end $$;

-- Who may cancel now; order_json_r22 shows the same answer to the app.
create or replace function secondhand.can_cancel_order_r26(o public.orders, d secondhand.order_details, p_viewer uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select case
    when p_viewer = o.buyer_id then o.order_status = 'pending'
                                    or (o.order_status = 'paid' and d.ship_by is not null and d.ship_by < now())
    when p_viewer = o.seller_id then o.order_status in ('paid', 'shipped')
    else false end;
$$;

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
begin
  select * into v_order from public.orders o where o.id = p_order_id and u in (o.buyer_id, o.seller_id) for update;
  if not found or (u = v_order.seller_id and v_order.paid_at is null) then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  select * into strict v_details from secondhand.order_details d where d.order_id = p_order_id;
  v_by := case when u = v_order.buyer_id then 'buyer' else 'seller' end;
  if not secondhand.can_cancel_order_r26(v_order, v_details, u) then
    raise exception 'order_not_cancellable' using errcode = '22023';
  end if;

  perform secondhand.cancel_order_r22(p_order_id, u, v_by,
                                      case when v_by = 'buyer' and v_order.order_status = 'paid' then 'ship_overdue' end);
  return jsonb_build_object('order_id', p_order_id, 'status', 'cancelled');
end $$;

-- ---------------------------------------------------------------------------
-- Members: report a problem, or take the report back
-- ---------------------------------------------------------------------------
create or replace function secondhand.can_open_order_issue_r26(o public.orders, p_viewer uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_viewer = o.buyer_id and o.order_status = 'shipped'
     and not exists (select 1 from secondhand.order_issues i where i.order_id = o.id and i.issue_status = 'open')
     and (select count(*) from secondhand.order_issues i where i.order_id = o.id) < 3;
$$;

create or replace function secondhand.open_order_issue(p_order_id uuid, p_kind text, p_detail text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_detail text := nullif(btrim(coalesce(p_detail, '')), '');
  o public.orders;
  d secondhand.order_details;
  i secondhand.order_issues;
begin
  select * into o from public.orders where id = p_order_id and buyer_id = u for update;
  if not found then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  if p_kind is null or p_kind not in ('not_arrived', 'not_as_described', 'cancel_request')
     or char_length(coalesce(v_detail, '')) > 1000
     or (p_kind <> 'not_arrived' and char_length(coalesce(v_detail, '')) < 5) then
    raise exception 'invalid_issue' using errcode = '22023';
  end if;
  if o.order_status <> 'shipped' then
    raise exception 'order_issue_not_allowed' using errcode = '22023';
  end if;
  if exists (select 1 from secondhand.order_issues x where x.order_id = o.id and x.issue_status = 'open') then
    raise exception 'order_issue_open' using errcode = '23505';
  end if;
  if not secondhand.can_open_order_issue_r26(o, u) then
    raise exception 'order_issue_limit' using errcode = '22023';
  end if;
  select * into strict d from secondhand.order_details where order_id = o.id for update;

  insert into secondhand.order_issues(order_id, opened_by, kind, detail)
  values (o.id, u, p_kind, v_detail)
  returning * into i;
  update public.escrow_transactions
     set escrow_status = 'disputed', dispute_at = now(), updated_at = now()
   where id = d.escrow_id and escrow_status = 'holding';

  perform secondhand.order_log_r22(o.id, u, 'shipped', 'shipped', 'dispute_opened', p_kind);
  perform secondhand.order_issue_notify_r26(o.seller_id, i, 'secondhand.notice.order_issue_opened',
    jsonb_build_object('order', o.order_number, 'kind', secondhand.order_issue_kind_th_r26(p_kind)),
    'ผู้ซื้อแจ้งปัญหาคำสั่งซื้อ',
    'คำสั่งซื้อ {order}: ผู้ซื้อแจ้งว่า "{kind}" ระบบพักเงินไว้ก่อน กรุณาคุยกับผู้ซื้อในแชต หรือยกเลิกและคืนเงินหากตกลงกันได้');
  return secondhand.order_issue_json_r26(i);
end $$;

create or replace function secondhand.withdraw_order_issue(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  o public.orders;
  i secondhand.order_issues;
begin
  select * into o from public.orders where id = p_order_id and buyer_id = u for update;
  if not found then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  update secondhand.order_issues
     set issue_status = 'withdrawn', resolved_by = u, resolved_at = now()
   where order_id = o.id and issue_status = 'open'
  returning * into i;
  if i.id is null then
    raise exception 'order_issue_not_found' using errcode = '22023';
  end if;
  perform secondhand.order_issue_unhold_r26(o.id, now() + interval '3 days');
  perform secondhand.order_log_r22(o.id, u, 'shipped', 'shipped', 'dispute_closed', 'withdrawn');
  perform secondhand.order_issue_notify_r26(o.seller_id, i, 'secondhand.notice.order_issue_withdrawn',
    jsonb_build_object('order', o.order_number), 'ผู้ซื้อยกเลิกการแจ้งปัญหา',
    'คำสั่งซื้อ {order}: ผู้ซื้อยกเลิกการแจ้งปัญหาแล้ว คำสั่งซื้อดำเนินต่อตามปกติ');
  return secondhand.order_issue_json_r26(i);
end $$;

-- ---------------------------------------------------------------------------
-- Timers: an open report stops the auto-receipt
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
       and not exists (select 1 from secondhand.order_issues i where i.order_id = o.id and i.issue_status = 'open')
     order by d.receive_by
     for update of o skip locked
  loop
    perform secondhand.complete_order_r22(r.id, null);
    n := n + 1;
  end loop;
  return n;
end $$;

-- ---------------------------------------------------------------------------
-- Reads: the latest report and what the viewer may do
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
    'address', case when p_viewer = o.buyer_id or o.order_status in ('paid', 'shipped', 'completed') then d.address end,
    'reviewed', exists (select 1 from secondhand.reviews r where r.order_id = o.id and r.reviewer_id = p_viewer),
    'unread_messages', coalesce((select case when p_viewer = c.buyer_id then c.buyer_unread_count
                                             else c.seller_unread_count end
                                   from public.chat_rooms c where c.order_id = o.id), 0),
    'issue', (select secondhand.order_issue_json_r26(x) from secondhand.order_issues x
               where x.order_id = o.id order by x.created_at desc limit 1),
    'can_cancel', secondhand.can_cancel_order_r26(o, d, p_viewer),
    'can_open_issue', secondhand.can_open_order_issue_r26(o, p_viewer))
  from public.orders o
  join secondhand.order_details d on d.order_id = o.id
  join public.products p on p.id = o.product_id
  left join secondhand.member_profiles m
    on m.profile_id = case when p_viewer = o.buyer_id then o.seller_id else o.buyer_id end
  where o.id = p_order_id
    and (p_viewer = o.buyer_id or (p_viewer = o.seller_id and o.paid_at is not null))
$$;

-- My Page: sellers see reports waiting on them first.
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
               'code', 'answer_issues', 'count', count(*),
               'order_id', (array_agg(o.id order by i.created_at))[1],
               'since', min(i.created_at)) as item
        from secondhand.order_issues i join public.orders o on o.id = i.order_id
       where o.seller_id = u and i.issue_status = 'open'
      union all
      select 0, count(*), jsonb_build_object(
               'code', 'pay_orders', 'count', count(*),
               'order_id', (array_agg(o.id order by d.pay_by))[1],
               'due_at', min(d.pay_by))
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
                                'pending_release', secondhand.pending_release_r24(u),
                                'currency', w.currency, 'status', w.wallet_status)
        from public.wallets w where w.profile_id = u),
    'counts', jsonb_build_object(
      'on_sale', (select count(*) from public.products p join secondhand.listings l on l.product_id = p.id
                   where l.seller_id = u and p.status = 'active' and p.is_active and p.stock > 0),
      'closed', (select count(*) from public.products p join secondhand.listings l on l.product_id = p.id
                  where l.seller_id = u and p.status = 'closed'),
      'selling', (select count(*) from public.orders o where o.seller_id = u and o.paid_at is not null
                   and o.order_status not in ('cancelled', 'completed', 'refunded')),
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
-- Staff (Kao ID Admin Hub)
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.order_issue_staff_r26()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not kaoid_private.staff_permission_r24('marketplace.orders.resolve') then
    raise exception 'order_issue_access_denied' using errcode = '42501';
  end if;
  return auth.uid();
end $$;

create or replace function kaoid_private.order_issue_staff_json_r26(i secondhand.order_issues)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select secondhand.order_issue_json_r26(i) || jsonb_build_object(
    'resolved_by_name', (select p.display_name from public.profiles p where p.id = i.resolved_by),
    'order', jsonb_build_object(
      'id', o.id, 'order_number', o.order_number, 'status', o.order_status, 'total', o.total_amount,
      'payment_method', d.payment_method, 'escrow_status', e.escrow_status,
      'paid_at', o.paid_at, 'shipped_at', o.shipped_at, 'receive_by', d.receive_by,
      'carrier', o.shipping_company, 'tracking_number', o.tracking_number, 'product_title', p.title),
    'buyer', kaoid_private.review_member_json_r25(o.buyer_id),
    'seller', kaoid_private.review_member_json_r25(o.seller_id))
    from public.orders o
    join secondhand.order_details d on d.order_id = o.id
    join public.products p on p.id = o.product_id
    left join public.escrow_transactions e on e.id = d.escrow_id
   where o.id = i.order_id;
$$;

-- open: newest report first; closed: newest decision first.
create or replace function kaoid_private.order_issue_queue_r26(p_filter text, p_before timestamptz)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform kaoid_private.order_issue_staff_r26();
  if p_filter is null or p_filter not in ('open', 'closed') then
    raise exception 'invalid_filter' using errcode = '22023';
  end if;
  return (
    select coalesce(jsonb_agg(kaoid_private.order_issue_staff_json_r26(x.i) || jsonb_build_object('sort_at', x.sort_at)
                              order by x.sort_at desc, (x.i).id desc), '[]')
      from (select i, coalesce(i.resolved_at, i.created_at) as sort_at
              from secondhand.order_issues i
             where (p_filter = 'open') = (i.issue_status = 'open')
               and (p_before is null or coalesce(i.resolved_at, i.created_at) < p_before)
             order by coalesce(i.resolved_at, i.created_at) desc, i.id desc
             limit 30) x);
end $$;

create or replace function kaoid_private.order_issue_detail_r26(p_issue_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  i secondhand.order_issues;
begin
  perform kaoid_private.order_issue_staff_r26();
  select * into i from secondhand.order_issues where id = p_issue_id;
  if not found then
    raise exception 'order_issue_not_found' using errcode = '22023';
  end if;
  return kaoid_private.order_issue_staff_json_r26(i) || jsonb_build_object(
    'events', (select coalesce(jsonb_agg(jsonb_build_object(
                 'event', ev.event_type, 'note', ev.description, 'created_at', ev.created_at)
                 order by ev.created_at), '[]')
                 from public.order_events ev where ev.order_id = i.order_id),
    'history', (select coalesce(jsonb_agg(secondhand.order_issue_json_r26(x) order by x.created_at desc), '[]')
                  from secondhand.order_issues x where x.order_id = i.order_id and x.id <> i.id));
end $$;

-- refund: cancel and return the money to the buyer; release: complete and pay
-- the seller; dismiss: no fault found, the order carries on.
create or replace function kaoid_private.order_issue_resolve_r26(p_issue_id uuid, p_decision text, p_note text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := kaoid_private.order_issue_staff_r26();
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
  i secondhand.order_issues;
  o public.orders;
  v_days integer;
  v_values jsonb;
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if p_decision is null or p_decision not in ('refund', 'release', 'dismiss')
     or char_length(coalesce(v_note, '')) > 500 then
    raise exception 'invalid_decision' using errcode = '22023';
  end if;
  if char_length(coalesce(v_note, '')) < 3 then
    raise exception 'note_required' using errcode = '22023';
  end if;
  select * into i from secondhand.order_issues where id = p_issue_id for update;
  if not found then
    raise exception 'order_issue_not_found' using errcode = '22023';
  end if;
  select * into strict o from public.orders where id = i.order_id for update;
  if u in (o.buyer_id, o.seller_id) then
    raise exception 'own_order' using errcode = '42501';
  end if;
  if i.issue_status <> 'open' or o.order_status <> 'shipped' then
    raise exception 'order_issue_closed' using errcode = '22023';
  end if;

  update secondhand.order_issues
     set issue_status = case p_decision when 'refund' then 'refunded' when 'release' then 'released'
                                        else 'dismissed' end,
         resolution_note = v_note, resolved_by = u, resolved_at = now()
   where id = i.id
  returning * into i;

  if p_decision = 'refund' then
    perform secondhand.cancel_order_r22(o.id, u, 'staff', 'issue_refund');
  elsif p_decision = 'release' then
    perform secondhand.complete_order_r22(o.id, u);
  else
    select s.receive_window_days into strict v_days from secondhand.market_settings s where s.id;
    perform secondhand.order_issue_unhold_r26(o.id, now() + make_interval(days => v_days));
  end if;
  perform secondhand.order_log_r22(o.id, u, null, null, 'dispute_closed', p_decision || ': ' || v_note);

  select s.receive_window_days into v_days from secondhand.market_settings s where s.id;
  v_values := jsonb_build_object('order', o.order_number, 'note', v_note, 'days', v_days);
  perform secondhand.order_issue_notify_r26(x.profile, i, 'secondhand.notice.order_issue_' || i.issue_status, v_values,
    case p_decision when 'refund' then 'ทีมงานตัดสินคืนเงินให้ผู้ซื้อ'
                    when 'release' then 'ทีมงานตัดสินปล่อยเงินให้ผู้ขาย'
                    else 'ทีมงานตรวจสอบปัญหาแล้ว' end,
    case p_decision
      when 'refund' then 'คำสั่งซื้อ {order}: ทีมงานตรวจสอบแล้ว คืนเงินเต็มจำนวนให้ผู้ซื้อและยกเลิกคำสั่งซื้อ หมายเหตุ: {note}'
      when 'release' then 'คำสั่งซื้อ {order}: ทีมงานตรวจสอบแล้ว ปล่อยเงินให้ผู้ขายและปิดคำสั่งซื้อ หมายเหตุ: {note}'
      else 'คำสั่งซื้อ {order}: ทีมงานตรวจสอบแล้ว คำสั่งซื้อดำเนินต่อตามปกติ ผู้ซื้อยืนยันรับสินค้าได้ภายใน {days} วัน หมายเหตุ: {note}'
    end)
    from (values (o.buyer_id), (o.seller_id)) x(profile);

  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'marketplace.order_issue.' || p_decision, 'order_issues', i.id, o.order_number || ': ' || v_note);
  return kaoid_private.order_issue_staff_json_r26(i);
end $$;

-- Which Admin Hub tools the signed-in staff member can open.
create or replace function kaoid_private.staff_tools_r24()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_withdrawals boolean := kaoid_private.staff_permission_r24('wallet.withdraw.approve');
  v_contents boolean := kaoid_private.staff_permission_r24('content.system.manage');
  v_reviews boolean := kaoid_private.staff_permission_r24('marketplace.reviews.moderate');
  v_issues boolean := kaoid_private.staff_permission_r24('marketplace.orders.resolve');
begin
  return jsonb_build_object(
    'withdrawals', v_withdrawals,
    'contents', v_contents,
    'reviews', v_reviews,
    'order_issues', v_issues,
    'pending_withdrawals', case when v_withdrawals then
      (select count(*) from public.withdraw_requests r where r.withdraw_status = 'pending') end,
    'pending_review_reports', case when v_reviews then
      (select count(distinct rr.review_id) from secondhand.review_reports rr where rr.report_status = 'pending') end,
    'open_order_issues', case when v_issues then
      (select count(*) from secondhand.order_issues i where i.issue_status = 'open') end);
end $$;

create or replace function public.order_issue_queue_r26(p_filter text default 'open', p_before timestamptz default null)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.order_issue_queue_r26(p_filter, p_before); $$;
create or replace function public.order_issue_detail_r26(p_issue_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.order_issue_detail_r26(p_issue_id); $$;
create or replace function public.order_issue_resolve_r26(p_issue_id uuid, p_decision text, p_note text)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.order_issue_resolve_r26(p_issue_id, p_decision, p_note); $$;

-- ---------------------------------------------------------------------------
-- Seed contents (Thai and English). Staff edit them from the Admin Hub.
-- ---------------------------------------------------------------------------
insert into public.system_contents(content_key, app_code, category, title, body, meta, sort_order) values
  ('secondhand.order.cancel_rules', 'secondhand', 'rule',
   jsonb_build_object('th', $c$กติกาการยกเลิกคำสั่งซื้อ$c$, 'en', $c$Cancelling an order$c$),
   jsonb_build_object('th', $c$ผู้ซื้อยกเลิกคำสั่งซื้อที่ยังไม่ชำระเงินได้ทุกเมื่อ
ถ้าผู้ขายไม่จัดส่งภายในกำหนด ผู้ซื้อกด "ขอยกเลิกคำสั่งซื้อ" ได้ และได้รับเงินคืนเต็มจำนวนเข้า KaoSure Wallet ทันที
ผู้ขายยกเลิกได้จนกว่าผู้ซื้อจะยืนยันรับสินค้า ผู้ซื้อได้รับเงินคืนทันที และสินค้าจะถูกปิดการขาย
หลังจัดส่งแล้ว ถ้ามีปัญหา ผู้ซื้อแจ้งปัญหาได้จากหน้าคำสั่งซื้อ ระบบจะพักเงินไว้จนกว่าจะตกลงกันได้หรือทีมงานตัดสิน$c$,
                      'en', $c$Buyers can cancel an unpaid order at any time.
If the seller doesn't ship by the deadline, the buyer can tap "Cancel order" and gets the full amount back in their KaoSure Wallet at once.
Sellers can cancel until the buyer confirms receipt. The buyer is refunded at once and the item is taken off sale.
After shipping, the buyer can report a problem from the order page. The money stays on hold until both sides agree or the KaoSure team decides.$c$),
   '{"icon": "gavel"}', 340),
  ('secondhand.order.issue_guide', 'secondhand', 'guide',
   jsonb_build_object('th', $c$แจ้งปัญหาคำสั่งซื้อ$c$, 'en', $c$Report a problem$c$),
   jsonb_build_object('th', $c$การแจ้งปัญหาจะยังไม่คืนเงินทันที ระบบจะพักเงินไว้และหยุดการยืนยันรับสินค้าอัตโนมัติ
ผู้ขายจะได้รับแจ้ง และคุยกันต่อได้ในแชตคำสั่งซื้อ ถ้าตกลงกันได้ ผู้ขายยกเลิกและคืนเงินได้ทันที
ถ้ายังตกลงกันไม่ได้ ทีมงาน KaoSure จะตรวจสอบและตัดสิน
ถ้าปัญหาคลี่คลายแล้ว กดยกเลิกการแจ้งปัญหา หรือกดได้รับสินค้าแล้วได้เลย$c$,
                      'en', $c$Reporting a problem doesn't refund you right away. The money is held and the automatic receipt stops.
The seller is told, and you can keep talking in the order chat. If you agree, the seller can cancel and refund you at once.
If you can't agree, the KaoSure team checks and decides.
If the problem is solved, withdraw the report or confirm receipt.$c$),
   '{"icon": "support"}', 350),

  ('secondhand.notice.order_issue_opened', 'secondhand', 'notice',
   jsonb_build_object('th', $c$ผู้ซื้อแจ้งปัญหาคำสั่งซื้อ$c$, 'en', $c$The buyer reported a problem$c$),
   jsonb_build_object('th', $c$คำสั่งซื้อ {order}: ผู้ซื้อแจ้งว่า "{kind}" ระบบพักเงินไว้ก่อน กรุณาคุยกับผู้ซื้อในแชต หรือยกเลิกและคืนเงินหากตกลงกันได้$c$,
                      'en', $c$Order {order}: the buyer reported "{kind}". The money is on hold. Talk with the buyer in the order chat, or cancel and refund if you both agree.$c$),
   '{"placeholders": ["order", "kind"]}', 300),
  ('secondhand.notice.order_issue_withdrawn', 'secondhand', 'notice',
   jsonb_build_object('th', $c$ผู้ซื้อยกเลิกการแจ้งปัญหา$c$, 'en', $c$The buyer withdrew the report$c$),
   jsonb_build_object('th', $c$คำสั่งซื้อ {order}: ผู้ซื้อยกเลิกการแจ้งปัญหาแล้ว คำสั่งซื้อดำเนินต่อตามปกติ$c$,
                      'en', $c$Order {order}: the buyer withdrew the problem report. The order carries on as usual.$c$),
   '{"placeholders": ["order"]}', 310),
  ('secondhand.notice.order_issue_refunded', 'secondhand', 'notice',
   jsonb_build_object('th', $c$ทีมงานตัดสินคืนเงินให้ผู้ซื้อ$c$, 'en', $c$The team refunded the buyer$c$),
   jsonb_build_object('th', $c$คำสั่งซื้อ {order}: ทีมงานตรวจสอบแล้ว คืนเงินเต็มจำนวนให้ผู้ซื้อและยกเลิกคำสั่งซื้อ หมายเหตุ: {note}$c$,
                      'en', $c$Order {order}: after checking, the team refunded the buyer in full and cancelled the order. Note: {note}$c$),
   '{"placeholders": ["order", "note"]}', 320),
  ('secondhand.notice.order_issue_released', 'secondhand', 'notice',
   jsonb_build_object('th', $c$ทีมงานตัดสินปล่อยเงินให้ผู้ขาย$c$, 'en', $c$The team paid the seller$c$),
   jsonb_build_object('th', $c$คำสั่งซื้อ {order}: ทีมงานตรวจสอบแล้ว ปล่อยเงินให้ผู้ขายและปิดคำสั่งซื้อ หมายเหตุ: {note}$c$,
                      'en', $c$Order {order}: after checking, the team released the money to the seller and closed the order. Note: {note}$c$),
   '{"placeholders": ["order", "note"]}', 330),
  ('secondhand.notice.order_issue_dismissed', 'secondhand', 'notice',
   jsonb_build_object('th', $c$ทีมงานตรวจสอบปัญหาแล้ว$c$, 'en', $c$The team checked the problem$c$),
   jsonb_build_object('th', $c$คำสั่งซื้อ {order}: ทีมงานตรวจสอบแล้ว คำสั่งซื้อดำเนินต่อตามปกติ ผู้ซื้อยืนยันรับสินค้าได้ภายใน {days} วัน หมายเหตุ: {note}$c$,
                      'en', $c$Order {order}: after checking, the order carries on as usual. The buyer has {days} days to confirm receipt. Note: {note}$c$),
   '{"placeholders": ["order", "note", "days"]}', 340)
on conflict (content_key) do nothing;

-- ---------------------------------------------------------------------------
-- Grants and app scope
-- ---------------------------------------------------------------------------
revoke all on function secondhand.order_issue_kind_th_r26(text) from public, anon, authenticated;
revoke all on function secondhand.order_issue_json_r26(secondhand.order_issues) from public, anon, authenticated;
revoke all on function secondhand.order_issue_notify_r26(uuid, secondhand.order_issues, text, jsonb, text, text)
  from public, anon, authenticated;
revoke all on function secondhand.order_issue_unhold_r26(uuid, timestamptz) from public, anon, authenticated;
revoke all on function secondhand.order_issues_settle_r26() from public, anon, authenticated;
revoke all on function secondhand.can_cancel_order_r26(public.orders, secondhand.order_details, uuid)
  from public, anon, authenticated;
revoke all on function secondhand.can_open_order_issue_r26(public.orders, uuid) from public, anon, authenticated;
revoke all on function kaoid_private.order_issue_staff_r26() from public, anon, authenticated;
revoke all on function kaoid_private.order_issue_staff_json_r26(secondhand.order_issues) from public, anon, authenticated;

revoke all on function secondhand.open_order_issue(uuid, text, text) from public, anon, authenticated;
revoke all on function secondhand.withdraw_order_issue(uuid) from public, anon, authenticated;
grant execute on function secondhand.open_order_issue(uuid, text, text) to authenticated;
grant execute on function secondhand.withdraw_order_issue(uuid) to authenticated;

revoke all on function kaoid_private.order_issue_queue_r26(text, timestamptz), kaoid_private.order_issue_detail_r26(uuid),
  kaoid_private.order_issue_resolve_r26(uuid, text, text),
  public.order_issue_queue_r26(text, timestamptz), public.order_issue_detail_r26(uuid),
  public.order_issue_resolve_r26(uuid, text, text)
  from public, anon;
grant execute on function kaoid_private.order_issue_queue_r26(text, timestamptz), kaoid_private.order_issue_detail_r26(uuid),
  kaoid_private.order_issue_resolve_r26(uuid, text, text),
  public.order_issue_queue_r26(text, timestamptz), public.order_issue_detail_r26(uuid),
  public.order_issue_resolve_r26(uuid, text, text)
  to authenticated;

-- Secondhand reports problems with its app token; resolving stays first-party only.
update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
                              'secondhand.open_order_issue', 'secondhand.withdraw_order_issue']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
