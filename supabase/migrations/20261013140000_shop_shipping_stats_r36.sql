-- R36: shipping performance on the shop page.
--
-- How the shop keeps its shipping promise, over every Secondhand order it has shipped since it opened:
--   * on time: shipped no later than order_details.ship_by (payment time + the listing's handling days);
--   * the average time from payment to shipping.
-- Only these totals are public; no single order is exposed. A shop with no shipped order gets shipped = 0.

create function secondhand.shop_shipping_r36(p_shop uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'shipped', count(*),
    'on_time', count(*) filter (where o.shipped_at <= d.ship_by),
    'avg_hours', round((extract(epoch from avg(o.shipped_at - o.paid_at)) / 3600)::numeric, 1)
  )
    from public.orders o
    join secondhand.order_details d on d.order_id = o.id
   where o.shop_id = p_shop
     and o.paid_at is not null
     and o.shipped_at is not null
$$;

revoke all on function secondhand.shop_shipping_r36(uuid) from public, anon, authenticated;

create or replace function secondhand.get_shop_profile(p_shop_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select secondhand.seller_card_r20d(s.id)
         || jsonb_build_object(
              'is_owner', auth.uid() is not null and s.owner_id = auth.uid(),
              'shipping', secondhand.shop_shipping_r36(s.id)
            )
    from public.shops s
   where s.id = p_shop_id
     and (s.shop_status = 'active' or (auth.uid() is not null and s.owner_id = auth.uid()))
$$;
