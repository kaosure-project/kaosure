-- R20g: price offers (値下げ交渉), after Yahoo! Flea Market.
--   * A buyer asks for 3, 5, 7 or 9 percent off; the server works out the baht
--     price (whole baht, never below market_settings.min_price).
--   * One open offer per buyer per listing. A new one is allowed once the last
--     was rejected, expired or cancelled.
--   * The seller has 24 hours to answer. An accepted offer lets that buyer buy
--     at the offer price for 24 hours; everyone else still sees the full price.
--   * Only the buyer and the seller see an offer. The table is RPC-only.
--   * Phase 4 checkout reads offer_checkout_price_r20g and marks the offer
--     used with use_price_offer_r20g before the listing becomes sold.

create table secondhand.price_offers (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  discount_percent smallint not null check (discount_percent in (3, 5, 7, 9)),
  listed_price numeric(12,2) not null check (listed_price > 0),
  offer_price numeric(12,2) not null check (offer_price > 0 and offer_price < listed_price),
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'expired', 'cancelled', 'used')),
  expires_at timestamptz not null,
  responded_at timestamptz,
  purchase_expires_at timestamptz,
  order_id uuid references public.orders(id),
  used_at timestamptz,
  cancel_reason text check (cancel_reason in ('price_changed', 'listing_unavailable', 'listing_sold')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (buyer_id <> seller_id),
  check (status not in ('accepted', 'used') or (responded_at is not null and purchase_expires_at is not null)),
  check (status <> 'used' or (order_id is not null and used_at is not null)),
  check (status <> 'cancelled' or cancel_reason is not null)
);

create unique index price_offers_one_open_r20g
  on secondhand.price_offers (product_id, buyer_id) where status in ('pending', 'accepted');
create index price_offers_product_r20g on secondhand.price_offers (product_id, status);
create index price_offers_buyer_r20g on secondhand.price_offers (buyer_id, created_at desc);
create index price_offers_seller_r20g on secondhand.price_offers (seller_id, status);
create index price_offers_due_r20g on secondhand.price_offers (expires_at) where status = 'pending';

alter table secondhand.price_offers enable row level security;
revoke all on table secondhand.price_offers from public, anon, authenticated;

-- Status as of now: a pending offer past 24 hours and an accepted offer past
-- its purchase window read as expired even before the sweep runs.
create or replace function secondhand.offer_status_r20g(o secondhand.price_offers)
returns text
language sql
stable
set search_path = ''
as $$
  select case
    when o.status = 'pending' and o.expires_at <= now() then 'expired'
    when o.status = 'accepted' and o.purchase_expires_at <= now() then 'expired'
    else o.status
  end
$$;

create or replace function secondhand.offer_json_r20g(o secondhand.price_offers)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id,
    'product_id', o.product_id,
    'discount_percent', o.discount_percent,
    'listed_price', o.listed_price,
    'offer_price', o.offer_price,
    'status', secondhand.offer_status_r20g(o),
    'cancel_reason', o.cancel_reason,
    'created_at', o.created_at,
    'expires_at', o.expires_at,
    'responded_at', o.responded_at,
    'purchase_expires_at', o.purchase_expires_at,
    'buyer_name', coalesce(nullif(btrim(m.display_name), ''), 'สมาชิก KaoSure'),
    'buyer_avatar_url', m.avatar_url
  )
  from (select 1) x
  left join secondhand.member_profiles m on m.profile_id = o.buyer_id
$$;

create or replace function secondhand.offer_baht_r20g(p_amount numeric)
returns text
language sql
immutable
set search_path = ''
as $$
  select '฿' || to_char(p_amount, 'FM999,999,999,990')
$$;

-- Same checks as the buy button: email and phone confirmed in Kao ID.
create or replace function secondhand.buyer_ready_r20g(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select u.email_confirmed_at is not null and u.phone_confirmed_at is not null
                     from auth.users u where u.id = p_profile_id), false)
$$;

-- The discounts a buyer can pick for this price.
create or replace function secondhand.offer_options_r20g(p_price numeric)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object('percent', d.pct, 'price', d.price) order by d.pct), '[]'::jsonb)
  from (
    select pct, round(p_price * (100 - pct) / 100.0, 0) as price
      from unnest(array[3, 5, 7, 9]) pct
  ) d
  cross join secondhand.market_settings s
  where s.id and d.price >= s.min_price and d.price < p_price
$$;

-- Sweeps offers whose 24 hours ran out and tells the buyer.
create or replace function secondhand.expire_price_offers_r20g(p_product_id uuid default null)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  with expired as (
    update secondhand.price_offers o
       set status = 'expired', updated_at = now()
     where (p_product_id is null or o.product_id = p_product_id)
       and ((o.status = 'pending' and o.expires_at <= now())
         or (o.status = 'accepted' and o.purchase_expires_at <= now()))
    returning o.id, o.buyer_id, o.product_id, o.responded_at
  ), notified as (
    insert into public.notifications (profile_id, title, message, notification_type, target_id, action_url, event_key)
    select e.buyer_id,
           case when e.responded_at is null then 'ข้อเสนอขอลดราคาหมดอายุ' else 'สิทธิ์ซื้อราคาพิเศษหมดอายุ' end,
           case when e.responded_at is null then 'ผู้ขายไม่ได้ตอบภายใน 24 ชั่วโมง คุณยื่นข้อเสนอใหม่ได้'
                else 'คุณไม่ได้ซื้อภายใน 24 ชั่วโมงหลังผู้ขายยอมรับ ราคากลับเป็นราคาปกติ' end,
           'price_offer_expired', e.product_id, '/items/' || e.product_id, 'price_offer_expired:' || e.id
      from expired e
    returning 1
  )
  select count(*) into v_count from expired;
  return v_count;
end $$;

-- ---------------------------------------------------------------------------
-- Buyer and seller RPCs
-- ---------------------------------------------------------------------------

-- The signed-in member's view of offers on one listing. The seller gets the
-- open offers; a buyer gets their latest offer and the discounts they can pick.
create or replace function secondhand.get_price_offer_state(p_product_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_owner uuid;
  v_price numeric(12,2);
  v_offer secondhand.price_offers;
  v_status text;
  v_on_sale boolean;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  v_owner := secondhand.listing_owner_r20d(p_product_id);
  if v_owner = v_uid then
    return jsonb_build_object(
      'role', 'seller',
      'offers', coalesce((
        select jsonb_agg(secondhand.offer_json_r20g(o)
                 order by secondhand.offer_status_r20g(o) <> 'pending', o.created_at desc)
          from secondhand.price_offers o
         where o.product_id = p_product_id
           and secondhand.offer_status_r20g(o) in ('pending', 'accepted')), '[]'::jsonb));
  end if;
  if v_owner is null or not secondhand.listing_visible_r20f(p_product_id) then
    return null;
  end if;

  select p.price into v_price from public.products p where p.id = p_product_id;
  v_on_sale := secondhand.listing_public_r20d(p_product_id);
  select * into v_offer from secondhand.price_offers o
   where o.product_id = p_product_id and o.buyer_id = v_uid
   order by o.created_at desc limit 1;
  v_status := case when v_offer.id is null then null else secondhand.offer_status_r20g(v_offer) end;
  return jsonb_build_object(
    'role', 'buyer',
    'offer', case when v_offer.id is null then null else secondhand.offer_json_r20g(v_offer) end,
    'can_offer', v_on_sale and coalesce(v_status not in ('pending', 'accepted'), true),
    'buyer_ready', secondhand.buyer_ready_r20g(v_uid),
    'options', case when v_on_sale then secondhand.offer_options_r20g(v_price) else '[]'::jsonb end,
    'special_price', case when v_status = 'accepted' then least(v_offer.offer_price, v_price) end
  );
end $$;

create or replace function secondhand.make_price_offer(p_product_id uuid, p_percent integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_owner uuid;
  v_price numeric(12,2);
  v_title text;
  v_offer_price numeric(12,2);
  v_min numeric(12,2);
  v_offer secondhand.price_offers;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  if p_percent is null or p_percent not in (3, 5, 7, 9) then
    raise exception 'Discount must be 3, 5, 7 or 9 percent';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_product_id::text || ':' || v_uid::text, 2047));
  if not secondhand.listing_public_r20d(p_product_id) then
    raise exception 'Listing is not available';
  end if;
  v_owner := secondhand.listing_owner_r20d(p_product_id);
  if v_owner = v_uid then
    raise exception 'Sellers cannot make offers on their own listing';
  end if;
  if not secondhand.buyer_ready_r20g(v_uid) then
    raise exception 'Buyer verification is required before making offers' using errcode = '42501';
  end if;

  perform secondhand.expire_price_offers_r20g(p_product_id);
  if exists (select 1 from secondhand.price_offers o
              where o.product_id = p_product_id and o.buyer_id = v_uid and o.status in ('pending', 'accepted')) then
    raise exception 'An offer is already open for this listing';
  end if;
  if (select count(*) from secondhand.price_offers o
       where o.buyer_id = v_uid and o.created_at > now() - interval '1 hour') >= 20 then
    raise exception 'Too many offers, try again later';
  end if;

  select p.price, p.title into v_price, v_title from public.products p where p.id = p_product_id;
  select s.min_price into v_min from secondhand.market_settings s where s.id;
  v_offer_price := round(v_price * (100 - p_percent) / 100.0, 0);
  if v_offer_price < v_min or v_offer_price >= v_price then
    raise exception 'Offer price is below the market minimum';
  end if;

  insert into secondhand.price_offers (product_id, buyer_id, seller_id, discount_percent, listed_price, offer_price,
                                       expires_at)
  values (p_product_id, v_uid, v_owner, p_percent, v_price, v_offer_price, now() + interval '24 hours')
  returning * into v_offer;

  insert into public.notifications (profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (v_owner, 'มีผู้ซื้อขอลดราคาสินค้าของคุณ',
          left(v_title, 80) || ': ขอลด ' || p_percent || '% เหลือ ' || secondhand.offer_baht_r20g(v_offer_price)
            || ' ตอบภายใน 24 ชั่วโมง',
          'price_offer', p_product_id, '/items/' || p_product_id, 'price_offer:' || v_offer.id);

  return secondhand.offer_json_r20g(v_offer);
end $$;

create or replace function secondhand.respond_price_offer(p_offer_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_offer secondhand.price_offers;
  v_title text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  if p_accept is null then
    raise exception 'Choose accept or reject';
  end if;
  select * into v_offer from secondhand.price_offers o where o.id = p_offer_id for update;
  if not found or v_offer.seller_id <> v_uid
     or secondhand.listing_owner_r20d(v_offer.product_id) is distinct from v_uid then
    raise exception 'Offer not found';
  end if;
  if secondhand.offer_status_r20g(v_offer) = 'expired' then
    raise exception 'Offer has expired';
  end if;
  if v_offer.status <> 'pending' then
    raise exception 'Offer already answered';
  end if;
  if p_accept and (not secondhand.listing_public_r20d(v_offer.product_id)
      or (select p.price from public.products p where p.id = v_offer.product_id) <> v_offer.listed_price) then
    raise exception 'Listing changed since the offer';
  end if;

  update secondhand.price_offers
     set status = case when p_accept then 'accepted' else 'rejected' end,
         responded_at = now(),
         purchase_expires_at = case when p_accept then now() + interval '24 hours' end,
         updated_at = now()
   where id = p_offer_id
  returning * into v_offer;

  select p.title into v_title from public.products p where p.id = v_offer.product_id;
  insert into public.notifications (profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (v_offer.buyer_id,
          case when p_accept then 'ผู้ขายยอมรับข้อเสนอของคุณ' else 'ผู้ขายปฏิเสธข้อเสนอของคุณ' end,
          case when p_accept
               then left(v_title, 80) || ': ซื้อได้ในราคา ' || secondhand.offer_baht_r20g(v_offer.offer_price)
                    || ' ภายใน 24 ชั่วโมง'
               else left(v_title, 80) || ': คุณยื่นข้อเสนอใหม่ได้' end,
          case when p_accept then 'price_offer_accepted' else 'price_offer_rejected' end,
          v_offer.product_id, '/items/' || v_offer.product_id, 'price_offer_answer:' || v_offer.id);

  return secondhand.offer_json_r20g(v_offer);
end $$;

-- ---------------------------------------------------------------------------
-- Listing changes: a new price or a listing off sale cancels pending offers;
-- a sale to someone else also cancels accepted ones.
-- ---------------------------------------------------------------------------
create or replace function secondhand.cancel_price_offers_r20g()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_price_changed boolean := new.price is distinct from old.price;
  v_off_sale boolean := new.status <> 'active' or not new.is_active or new.stock <= 0;
  v_sold boolean := new.status = 'sold';
begin
  if not (v_price_changed or v_off_sale) then
    return null;
  end if;
  with cancelled as (
    update secondhand.price_offers o
       set status = 'cancelled',
           cancel_reason = case when v_sold then 'listing_sold'
                                when v_price_changed and not v_off_sale then 'price_changed'
                                else 'listing_unavailable' end,
           updated_at = now()
     where o.product_id = new.id
       and (o.status = 'pending' or (v_sold and o.status = 'accepted'))
    returning o.id, o.buyer_id, o.cancel_reason
  )
  insert into public.notifications (profile_id, title, message, notification_type, target_id, action_url, event_key)
  select c.buyer_id, 'ข้อเสนอขอลดราคาถูกยกเลิก',
         left(new.title, 80) || case c.cancel_reason
           when 'price_changed' then ': ผู้ขายเปลี่ยนราคา คุณยื่นข้อเสนอใหม่ได้'
           when 'listing_sold' then ': สินค้าขายแล้ว'
           else ': สินค้าปิดการขายชั่วคราว' end,
         'price_offer_cancelled', new.id, '/items/' || new.id, 'price_offer_cancelled:' || c.id
    from cancelled c;
  return null;
end $$;

create trigger products_price_offers_r20g
after update of price, status, is_active, stock on public.products
for each row
when (old.price is distinct from new.price or old.status is distinct from new.status
      or old.is_active is distinct from new.is_active or old.stock is distinct from new.stock)
execute function secondhand.cancel_price_offers_r20g();

-- ---------------------------------------------------------------------------
-- Phase 4 checkout hooks (server-side only)
-- ---------------------------------------------------------------------------

-- The price this buyer pays now: an accepted offer inside its window (never
-- above the current price), else the listing price.
create or replace function secondhand.offer_checkout_price_r20g(p_product_id uuid, p_buyer_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'offer_id', o.id,
    'price', case when o.id is null then p.price else least(o.offer_price, p.price) end,
    'listed_price', p.price)
  from public.products p
  left join lateral (
    select x.id, x.offer_price from secondhand.price_offers x
     where x.product_id = p.id and x.buyer_id = p_buyer_id and x.status = 'accepted'
       and x.purchase_expires_at > now() and x.order_id is null
     limit 1
  ) o on true
  where p.id = p_product_id
$$;

-- Binds an accepted offer to the buyer's new order.
create or replace function secondhand.use_price_offer_r20g(p_offer_id uuid, p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update secondhand.price_offers o
     set status = 'used', order_id = p_order_id, used_at = now(), updated_at = now()
   where o.id = p_offer_id and o.status = 'accepted' and o.purchase_expires_at > now()
     and exists (select 1 from public.orders r
                  where r.id = p_order_id and r.buyer_id = o.buyer_id and r.product_id = o.product_id);
  if not found then
    raise exception 'Offer cannot be used for this order';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Grants, schedule and Secondhand token scope
-- ---------------------------------------------------------------------------
revoke all on function secondhand.offer_status_r20g(secondhand.price_offers) from public, anon, authenticated;
revoke all on function secondhand.offer_json_r20g(secondhand.price_offers) from public, anon, authenticated;
revoke all on function secondhand.offer_baht_r20g(numeric) from public, anon, authenticated;
revoke all on function secondhand.buyer_ready_r20g(uuid) from public, anon, authenticated;
revoke all on function secondhand.offer_options_r20g(numeric) from public, anon, authenticated;
revoke all on function secondhand.expire_price_offers_r20g(uuid) from public, anon, authenticated;
revoke all on function secondhand.cancel_price_offers_r20g() from public, anon, authenticated;
revoke all on function secondhand.offer_checkout_price_r20g(uuid, uuid) from public, anon, authenticated;
revoke all on function secondhand.use_price_offer_r20g(uuid, uuid) from public, anon, authenticated;

revoke all on function secondhand.get_price_offer_state(uuid) from public, anon;
grant execute on function secondhand.get_price_offer_state(uuid) to authenticated;
revoke all on function secondhand.make_price_offer(uuid, integer) from public, anon;
grant execute on function secondhand.make_price_offer(uuid, integer) to authenticated;
revoke all on function secondhand.respond_price_offer(uuid, boolean) from public, anon;
grant execute on function secondhand.respond_price_offer(uuid, boolean) to authenticated;

select cron.schedule('secondhand-price-offer-expiry-r20g', '*/10 * * * *',
                     'select secondhand.expire_price_offers_r20g();');

update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
         'secondhand.get_price_offer_state', 'secondhand.make_price_offer', 'secondhand.respond_price_offer']) r
         order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
