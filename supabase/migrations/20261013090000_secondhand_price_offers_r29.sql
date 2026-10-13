-- R29: price offer rules (ขอต่อราคา).
--   * Quick picks of 5, 8 or 9 percent off, or any whole-baht price. Never more than 9 percent off: the
--     lowest offer is the listed price x 0.91 rounded up to the baht, and never below market_settings.min_price.
--   * The buyer may withdraw a pending offer, or give up an accepted price, at any time. The seller is told.
--   * At most 3 offers per buyer per listing in 24 hours (offers the seller's own changes cancelled don't
--     count), so offer / withdraw loops can't flood the seller.
--   * Shop staff can't make offers on their own shop's listings.
--   * Unchanged from R20g / R22b: 24 hours for the seller to answer; an accepted price is for that buyer only,
--     for 24 hours, while everyone else sees the full price; nothing is reserved and whoever pays first gets
--     the item.

alter table secondhand.price_offers drop constraint price_offers_discount_percent_check;
alter table secondhand.price_offers alter column discount_percent type numeric(4,1);
alter table secondhand.price_offers add constraint price_offers_discount_percent_check
  check (discount_percent > 0 and discount_percent <= 9);

alter table secondhand.price_offers
  drop constraint price_offers_cancel_reason_check,
  add constraint price_offers_cancel_reason_check
    check (cancel_reason in ('price_changed', 'listing_unavailable', 'listing_sold', 'blocked', 'buyer_cancelled'));

-- The lowest price a buyer may offer: 9 percent off rounded up, and never below the market minimum.
create or replace function secondhand.offer_floor_r29(p_price numeric)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select greatest(ceil(p_price * 91 / 100.0), s.min_price) from secondhand.market_settings s where s.id
$$;

-- The owner or anyone on the shop team.
create or replace function secondhand.offer_team_r29(p_product_id uuid, p_uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select secondhand.listing_owner_r20d(p_product_id) = p_uid
      or coalesce((select bool_or(x.value::boolean)
                     from jsonb_each_text(secondhand.shop_perms_r27(
                            (select p.shop_id from public.products p where p.id = p_product_id), p_uid)) x), false)
$$;

-- Quick picks: 5, 8 and 9 percent off, rounded up to the baht so the discount never passes the pick.
create or replace function secondhand.offer_options_r20g(p_price numeric)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object('percent', d.pct, 'price', d.price) order by d.pct), '[]'::jsonb)
  from (
    select distinct on (price) pct, price
      from (select pct, ceil(p_price * (100 - pct) / 100.0) as price from unnest(array[5, 8, 9]) pct) x
     order by price, pct
  ) d
  where d.price >= secondhand.offer_floor_r29(p_price) and d.price < p_price
$$;

create or replace function secondhand.get_price_offer_state(p_product_id uuid)
returns jsonb
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  v_uid uuid := auth.uid();
  v_owner uuid;
  v_price numeric(12,2);
  v_floor numeric;
  v_offer secondhand.price_offers;
  v_status text;
  v_on_sale boolean;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  v_owner := secondhand.listing_owner_r20d(p_product_id);
  if v_owner is not null
     and secondhand.shop_can_r27((select p.shop_id from public.products p where p.id = p_product_id), 'products', v_uid) then
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
  v_floor := secondhand.offer_floor_r29(v_price);
  v_on_sale := secondhand.listing_public_r20d(p_product_id) and v_floor < v_price
               and not secondhand.offer_team_r29(p_product_id, v_uid);
  select * into v_offer from secondhand.price_offers o
   where o.product_id = p_product_id and o.buyer_id = v_uid
   order by o.created_at desc limit 1;
  v_status := case when v_offer.id is null then null else secondhand.offer_status_r20g(v_offer) end;
  return jsonb_build_object(
    'role', 'buyer',
    'offer', case when v_offer.id is null then null else secondhand.offer_json_r20g(v_offer) end,
    'can_offer', v_on_sale and coalesce(v_status not in ('pending', 'accepted'), true),
    'buyer_ready', secondhand.buyer_ready_r20g(v_uid),
    'listed_price', v_price,
    'min_price', case when v_on_sale then v_floor end,
    'max_discount_percent', 9,
    'options', case when v_on_sale then secondhand.offer_options_r20g(v_price) else '[]'::jsonb end,
    'special_price', case when v_status = 'accepted' then least(v_offer.offer_price, v_price) end
  );
end $$;

create or replace function secondhand.make_price_offer_r29(p_product_id uuid, p_price numeric)
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
  v_floor numeric;
  v_min numeric(12,2);
  v_percent numeric(4,1);
  v_offer secondhand.price_offers;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  if p_price is null or p_price <= 0 or p_price <> trunc(p_price) then
    raise exception 'offer_price_invalid' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_product_id::text || ':' || v_uid::text, 2047));
  if not secondhand.listing_public_r20d(p_product_id) then
    raise exception 'Listing is not available';
  end if;
  v_owner := secondhand.listing_owner_r20d(p_product_id);
  if secondhand.offer_team_r29(p_product_id, v_uid) then
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
  if (select count(*) from secondhand.price_offers o
       where o.product_id = p_product_id and o.buyer_id = v_uid and o.created_at > now() - interval '24 hours'
         and o.cancel_reason is distinct from 'price_changed'
         and o.cancel_reason is distinct from 'listing_unavailable') >= 3 then
    raise exception 'offer_limit_listing' using errcode = '22023';
  end if;

  select p.price, p.title into v_price, v_title from public.products p where p.id = p_product_id;
  select s.min_price into v_min from secondhand.market_settings s where s.id;
  v_floor := secondhand.offer_floor_r29(v_price);
  if p_price >= v_price then
    raise exception 'offer_not_lower' using errcode = '22023';
  end if;
  if p_price < v_min then
    raise exception 'Offer price is below the market minimum';
  end if;
  if p_price < v_floor then
    raise exception 'offer_discount_too_large' using errcode = '22023';
  end if;
  -- Rounded up to 0.1 so a 1-baht offer still shows a discount; it can't pass 9 because p_price >= v_floor.
  v_percent := ceil((v_price - p_price) * 1000 / v_price) / 10;

  insert into secondhand.price_offers (product_id, buyer_id, seller_id, discount_percent, listed_price, offer_price,
                                       expires_at)
  values (p_product_id, v_uid, v_owner, v_percent, v_price, p_price, now() + interval '24 hours')
  returning * into v_offer;

  insert into public.notifications (profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (v_owner, 'มีผู้ซื้อขอต่อราคาสินค้าของคุณ',
          left(v_title, 80) || ': ขอต่อราคาเหลือ ' || secondhand.offer_baht_r20g(p_price)
            || ' (ลด ' || trim_scale(v_percent) || '%) ตอบภายใน 24 ชั่วโมง',
          'price_offer', p_product_id, '/items/' || p_product_id, 'price_offer:' || v_offer.id);

  return secondhand.offer_json_r20g(v_offer);
end $$;

-- Apps released before R29 send a percent; it becomes the same rounded-up price.
create or replace function secondhand.make_price_offer(p_product_id uuid, p_percent integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_percent is null or p_percent not between 1 and 9 then
    raise exception 'offer_discount_too_large' using errcode = '22023';
  end if;
  return secondhand.make_price_offer_r29(
    p_product_id,
    (select ceil(p.price * (100 - p_percent) / 100.0) from public.products p where p.id = p_product_id));
end $$;

-- The buyer withdraws a pending offer or gives up an accepted price.
create or replace function secondhand.cancel_price_offer_r29(p_offer_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_offer secondhand.price_offers;
  v_was text;
  v_title text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  select * into v_offer from secondhand.price_offers o where o.id = p_offer_id for update;
  if not found or v_offer.buyer_id <> v_uid then
    raise exception 'Offer not found';
  end if;
  v_was := secondhand.offer_status_r20g(v_offer);
  if v_was not in ('pending', 'accepted') then
    raise exception 'offer_not_open' using errcode = '22023';
  end if;

  update secondhand.price_offers
     set status = 'cancelled', cancel_reason = 'buyer_cancelled', updated_at = now()
   where id = p_offer_id
  returning * into v_offer;

  select p.title into v_title from public.products p where p.id = v_offer.product_id;
  insert into public.notifications (profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (v_offer.seller_id,
          case when v_was = 'accepted' then 'ผู้ซื้อสละสิทธิ์ราคาพิเศษ' else 'ผู้ซื้อยกเลิกข้อเสนอต่อราคา' end,
          left(v_title, 80) || ': ข้อเสนอ ' || secondhand.offer_baht_r20g(v_offer.offer_price) || ' ถูกยกเลิกโดยผู้ซื้อ',
          'price_offer_withdrawn', v_offer.product_id, '/items/' || v_offer.product_id,
          'price_offer_withdrawn:' || v_offer.id);

  return secondhand.offer_json_r20g(v_offer);
end $$;

revoke all on function secondhand.offer_floor_r29(numeric) from public, anon, authenticated;
revoke all on function secondhand.offer_team_r29(uuid, uuid) from public, anon, authenticated;
revoke all on function secondhand.make_price_offer_r29(uuid, numeric) from public, anon;
grant execute on function secondhand.make_price_offer_r29(uuid, numeric) to authenticated;
revoke all on function secondhand.cancel_price_offer_r29(uuid) from public, anon;
grant execute on function secondhand.cancel_price_offer_r29(uuid) to authenticated;

update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
         'secondhand.make_price_offer_r29', 'secondhand.cancel_price_offer_r29']) r
         order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
