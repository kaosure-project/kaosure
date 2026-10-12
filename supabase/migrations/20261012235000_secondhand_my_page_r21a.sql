-- R21a: My Page (Yahoo! Flea Market style dashboard).
--   * Addresses are either 'shipping' (where purchases are sent) or 'return'
--     (where returned items go back to the seller); each type has its own
--     default. The type is fixed once the address is saved.
--   * get_my_page() returns the whole dashboard in one call: profile, badge,
--     ratings, wallet (read only), activity counts and the to-do list.

-- ---------------------------------------------------------------------------
-- Shipping and return addresses
-- ---------------------------------------------------------------------------
alter table secondhand.shipping_addresses
  add column address_type text not null default 'shipping'
  constraint shipping_addresses_type_r21a check (address_type in ('shipping', 'return'));

drop index secondhand.shipping_addresses_one_default;
create unique index shipping_addresses_one_default_r21a
  on secondhand.shipping_addresses (profile_id, address_type) where is_default;

-- The first address of each type becomes its default, a new default replaces
-- the old one of the same type, and a member keeps at most 10 addresses.
create or replace function secondhand.shipping_address_rules() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    if (select count(*) from secondhand.shipping_addresses a where a.profile_id = new.profile_id) >= 10 then
      raise exception 'address_limit_reached' using errcode = '23514';
    end if;
    if not exists(select 1 from secondhand.shipping_addresses a
                   where a.profile_id = new.profile_id and a.address_type = new.address_type) then
      new.is_default := true;
    end if;
  else
    new.address_type := old.address_type;
    new.updated_at := now();
  end if;
  if new.is_default then
    update secondhand.shipping_addresses a set is_default = false
     where a.profile_id = new.profile_id and a.address_type = new.address_type and a.id <> new.id and a.is_default;
  end if;
  return new;
end $$;

grant insert (address_type) on table secondhand.shipping_addresses to authenticated;

-- ---------------------------------------------------------------------------
-- My Page
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
      select 1 as ord, count(*) as n, jsonb_build_object(
               'code', 'answer_offers', 'count', count(*),
               'product_id', (array_agg(o.product_id order by o.expires_at))[1],
               'due_at', min(o.expires_at)) as item
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
        'seller_rating', r.seller_rating,
        'seller_review_count', coalesce(r.seller_review_count, 0),
        'seller_good_count', coalesce(r.seller_good_count, 0),
        'seller_bad_count', coalesce(r.seller_bad_count, 0),
        'buyer_rating', r.buyer_rating,
        'buyer_review_count', coalesce(r.buyer_review_count, 0))
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

revoke all on function secondhand.get_my_page() from public, anon, authenticated;
grant execute on function secondhand.get_my_page() to authenticated;

update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array['secondhand.get_my_page']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
