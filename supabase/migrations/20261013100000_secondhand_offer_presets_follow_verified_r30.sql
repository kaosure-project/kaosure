-- R30:
--   * Price offer quick picks become 5, 7 and 9 percent off. 9 percent stays the most a buyer may ask
--     for, typed prices included (offer_floor_r29 is unchanged).
--   * Following a shop needs a confirmed email and phone, the same rule as buying and price offers
--     (buyer_ready_r20g). Unfollowing is always allowed, and existing follows are kept.

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
      from (select pct, ceil(p_price * (100 - pct) / 100.0) as price from unnest(array[5, 7, 9]) pct) x
     order by price, pct
  ) d
  where d.price >= secondhand.offer_floor_r29(p_price) and d.price < p_price
$$;

-- Whether the signed-in member has confirmed both email and phone. Only answers for the caller.
create or replace function secondhand.member_contact_ready_r30()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select secondhand.buyer_ready_r20g((select auth.uid()))
$$;

revoke all on function secondhand.member_contact_ready_r30() from public, anon;
grant execute on function secondhand.member_contact_ready_r30() to authenticated;

drop policy if exists marketplace_owner_create_follows on public.followers;
create policy marketplace_owner_create_follows on public.followers for insert to authenticated
  with check ((select kaoid_private.account_active_r9f()) and profile_id = (select auth.uid())
    and (select secondhand.member_contact_ready_r30())
    and exists(select 1 from public.shops s where s.id = followers.shop_id and s.shop_status = 'active'));
