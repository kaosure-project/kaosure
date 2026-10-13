-- R42: the shop page (Mercari / Yahoo! Flea Market style).
--   * public.followers was created outside the migrations; it is recorded here as it is live, and a member's own
--     follows get an index.
--   * Shop items come in two tabs, on sale and sold, paged with a keyset cursor and sorted on the server.
--   * A shop's rating counts the reviews that belong to it: everything the owner received as a buyer, and as a
--     seller only on this shop's orders. A business shop counts its own orders only. For a member without a
--     business shop the numbers do not change.
--   * Reviews can be filtered by the role the member was reviewed in, and business shops get a review page.
--   * Members report a shop once; staff handle reports in the Kao ID Admin Hub.
--   * A block either way stops following, and blocking ends the follows between the two members. The shop page
--     tells the viewer when they blocked the shop, so they can undo it.

-- ---------------------------------------------------------------------------
-- Followers, as they are live
-- ---------------------------------------------------------------------------
create table if not exists public.followers (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on update cascade on delete cascade,
  profile_id uuid not null references public.profiles(id) on update cascade on delete cascade,
  source text not null default 'web',
  created_at timestamptz not null default now(),
  constraint followers_shop_profile_unique unique (shop_id, profile_id)
);

alter table public.followers enable row level security;

create index if not exists followers_profile_r42 on public.followers (profile_id, created_at desc);

-- Called from the follow policy, so members may run it; it only answers yes or no.
create or replace function secondhand.shop_follow_open_r42(p_shop uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.shops s
     where s.id = p_shop
       and s.shop_status = 'active'
       and not secondhand.blocked_between_r21b((select auth.uid()), s.owner_id))
$$;

revoke all on function secondhand.shop_follow_open_r42(uuid) from public, anon, authenticated;
grant execute on function secondhand.shop_follow_open_r42(uuid) to authenticated;

drop policy if exists marketplace_owner_create_follows on public.followers;
create policy marketplace_owner_create_follows on public.followers
  for insert to authenticated
  with check ((select kaoid_private.account_active_r9f())
              and profile_id = (select auth.uid())
              and (select secondhand.member_contact_ready_r30())
              and secondhand.shop_follow_open_r42(shop_id));

-- ---------------------------------------------------------------------------
-- Shop items: two tabs, keyset pages
-- ---------------------------------------------------------------------------
create index if not exists products_shop_selling_new_r42
  on public.products (shop_id, created_at desc, id desc)
  where status = 'active' and is_active and stock > 0;
create index if not exists products_shop_selling_price_r42
  on public.products (shop_id, price, id)
  where status = 'active' and is_active and stock > 0;
create index if not exists products_shop_sold_r42
  on public.products (shop_id, updated_at desc, id desc)
  where status = 'sold' and is_active;

-- One card, in the shape list_shop_listings returns.
create or replace function secondhand.shop_item_json_r42(p_product uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', p.id,
    'shop_id', p.shop_id,
    'category_id', p.category_id,
    'title', p.title,
    'description', p.description,
    'condition_level', p.condition_level,
    'price', p.price,
    'stock', p.stock,
    'status', p.status,
    'view_count', p.view_count,
    'favorite_count', p.favorite_count,
    'created_at', p.created_at,
    'updated_at', p.updated_at,
    'shipping_method', p.shipping_method,
    'handling_time_days', p.handling_time_days,
    'shop_name', s.shop_name,
    'shop_slug', s.shop_slug,
    'province', s.province,
    'category_name', c.name,
    'image_paths', coalesce((select jsonb_agg(i.image_url order by i.is_cover desc, i.image_order)
                               from public.product_images i where i.product_id = p.id), '[]'::jsonb))
    from public.products p
    join public.shops s on s.id = p.shop_id
    left join public.categories c on c.id = p.category_id
   where p.id = p_product
$$;

revoke all on function secondhand.shop_item_json_r42(uuid) from public, anon, authenticated;

-- p_tab: 'selling' (sorted 'newest', 'price_asc' or 'price_desc') or 'sold' (newest change first).
-- p_cursor is the next_cursor of the page before; it is opaque to the app.
create or replace function secondhand.list_shop_items(
  p_shop_id uuid,
  p_tab text default 'selling',
  p_sort text default 'newest',
  p_cursor text default null,
  p_limit integer default 30
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_limit integer := least(greatest(coalesce(p_limit, 30), 1), 60);
  v_key text;
  v_id uuid;
  v_ids uuid[];
  v_keys text[];
  v_next text;
begin
  if coalesce(p_tab, '') not in ('selling', 'sold')
     or coalesce(p_sort, '') not in ('newest', 'price_asc', 'price_desc')
     or (p_tab = 'sold' and p_sort <> 'newest') then
    raise exception 'invalid_filter' using errcode = '22023';
  end if;
  if not exists (select 1 from public.shops s where s.id = p_shop_id and s.shop_status = 'active') then
    return jsonb_build_object('items', '[]'::jsonb, 'next_cursor', null);
  end if;

  if p_cursor is null then
    -- Sentinels that come before every row, so each query keeps one index-friendly comparison.
    v_key := case p_sort when 'price_asc' then '-1' when 'price_desc' then '1e18' else 'infinity' end;
    v_id := case p_sort when 'price_asc' then '00000000-0000-0000-0000-000000000000'::uuid
                        else 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid end;
  else
    begin
      v_key := split_part(p_cursor, '|', 1);
      v_id := split_part(p_cursor, '|', 2)::uuid;
      perform case when p_sort like 'price%' then v_key::numeric::text else v_key::timestamptz::text end;
    exception when others then
      raise exception 'invalid_cursor' using errcode = '22023';
    end;
  end if;

  if p_tab = 'sold' then
    select array_agg(x.id order by x.n), array_agg(x.k order by x.n) into v_ids, v_keys
      from (select p.id, p.updated_at::text as k,
                   row_number() over (order by p.updated_at desc, p.id desc) as n
              from public.products p
             where p.shop_id = p_shop_id and p.status = 'sold' and p.is_active
               and (p.updated_at, p.id) < (v_key::timestamptz, v_id)
             order by p.updated_at desc, p.id desc
             limit v_limit + 1) x;
  elsif p_sort = 'newest' then
    select array_agg(x.id order by x.n), array_agg(x.k order by x.n) into v_ids, v_keys
      from (select p.id, p.created_at::text as k,
                   row_number() over (order by p.created_at desc, p.id desc) as n
              from public.products p
              join public.categories c on c.id = p.category_id and c.is_active
             where p.shop_id = p_shop_id and p.status = 'active' and p.is_active and p.stock > 0
               and (p.created_at, p.id) < (v_key::timestamptz, v_id)
             order by p.created_at desc, p.id desc
             limit v_limit + 1) x;
  elsif p_sort = 'price_asc' then
    select array_agg(x.id order by x.n), array_agg(x.k order by x.n) into v_ids, v_keys
      from (select p.id, p.price::text as k,
                   row_number() over (order by p.price, p.id) as n
              from public.products p
              join public.categories c on c.id = p.category_id and c.is_active
             where p.shop_id = p_shop_id and p.status = 'active' and p.is_active and p.stock > 0
               and (p.price, p.id) > (v_key::numeric, v_id)
             order by p.price, p.id
             limit v_limit + 1) x;
  else
    select array_agg(x.id order by x.n), array_agg(x.k order by x.n) into v_ids, v_keys
      from (select p.id, p.price::text as k,
                   row_number() over (order by p.price desc, p.id desc) as n
              from public.products p
              join public.categories c on c.id = p.category_id and c.is_active
             where p.shop_id = p_shop_id and p.status = 'active' and p.is_active and p.stock > 0
               and (p.price, p.id) < (v_key::numeric, v_id)
             order by p.price desc, p.id desc
             limit v_limit + 1) x;
  end if;

  v_ids := coalesce(v_ids, '{}');
  if cardinality(v_ids) > v_limit then
    v_next := v_keys[v_limit] || '|' || v_ids[v_limit];
    v_ids := v_ids[1:v_limit];
  end if;

  return jsonb_build_object(
    'items', coalesce((select jsonb_agg(secondhand.shop_item_json_r42(t.id) order by t.n)
                         from unnest(v_ids) with ordinality t(id, n)), '[]'::jsonb),
    'next_cursor', v_next);
end $$;

revoke all on function secondhand.list_shop_items(uuid, text, text, text, integer) from public;
grant execute on function secondhand.list_shop_items(uuid, text, text, text, integer) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- A shop's reviews and rating
-- ---------------------------------------------------------------------------
-- reviewer_role 'buyer' means the owner was reviewed as the seller; 'seller' means as the buyer.
create or replace function secondhand.shop_reviews_r42(p_shop uuid)
returns setof secondhand.reviews
language sql
stable
security definer
set search_path = ''
as $$
  select r.*
    from public.shops s
    join secondhand.reviews r on r.reviewee_id = s.owner_id and r.is_visible
    left join public.orders o on o.id = r.order_id
   where s.id = p_shop
     and case when s.seller_identity_type = 'business'
              then r.reviewer_role = 'buyer' and o.shop_id = s.id
              else r.reviewer_role = 'seller' or o.shop_id = s.id end
$$;

revoke all on function secondhand.shop_reviews_r42(uuid) from public, anon, authenticated;

create or replace function secondhand.shop_rating_r42(p_shop uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'rating', round(5.0 * count(*) filter (where r.verdict = 'good') / nullif(count(*), 0), 1),
    'review_count', count(*),
    'good_count', count(*) filter (where r.verdict = 'good'),
    'bad_count', count(*) filter (where r.verdict = 'bad'))
    from secondhand.shop_reviews_r42(p_shop) r
$$;

revoke all on function secondhand.shop_rating_r42(uuid) from public, anon, authenticated;

-- A business shop shows the shop, not the owner's personal profile.
create or replace function secondhand.seller_card_r20d(p_shop_id uuid)
returns jsonb
language sql
stable security definer
set search_path to ''
as $$
  select jsonb_build_object(
    'shop_id', s.id,
    'shop_name', s.shop_name,
    'shop_slug', s.shop_slug,
    'shop_description', s.description,
    'province', s.province,
    'joined_at', s.created_at,
    'kind', s.seller_identity_type,
    'display_name', case when s.seller_identity_type = 'personal'
                         then coalesce(nullif(btrim(m.display_name), ''), s.shop_name) else s.shop_name end,
    'avatar_url', case when s.seller_identity_type = 'personal' then m.avatar_url end,
    'bio', case when s.seller_identity_type = 'personal' then m.bio else s.description end,
    'is_verified', case when s.seller_identity_type = 'personal'
                        then coalesce((secondhand.seller_status_r20f(s.owner_id)->>'verified')::boolean, false)
                        else coalesce((secondhand.shop_sell_status_r27(s.id)->>'can_list')::boolean, false) end,
    'follower_count', (select count(*) from public.followers f where f.shop_id = s.id),
    'sold_count', (select count(*) from public.orders o where o.shop_id = s.id and o.order_status = 'completed'),
    'on_sale_count', (select count(*) from public.products p
                       join public.categories c on c.id = p.category_id and c.is_active
                      where p.shop_id = s.id and p.status = 'active' and p.is_active and p.stock > 0)
  ) || secondhand.shop_rating_r42(s.id)
  from public.shops s
  left join secondhand.member_profiles m on m.profile_id = s.owner_id
  where s.id = p_shop_id
$$;

revoke all on function secondhand.seller_card_r20d(uuid) from public, anon, authenticated;

-- The shop's reviews, or the signed-in member's own when p_shop_id is null.
create or replace function secondhand.review_scope_r42(p_shop uuid, p_profile uuid)
returns setof secondhand.reviews
language sql
stable
security definer
set search_path = ''
as $$
  select r.* from secondhand.shop_reviews_r42(p_shop) r where p_shop is not null
  union all
  select r.* from secondhand.reviews r where p_shop is null and r.reviewee_id = p_profile and r.is_visible
$$;

revoke all on function secondhand.review_scope_r42(uuid, uuid) from public, anon, authenticated;

drop function if exists secondhand.list_member_reviews(uuid, text, timestamptz, integer);

-- p_role: 'seller' for reviews received as the seller, 'buyer' for those received as the buyer. The counts follow
-- p_role; seller_review_count and buyer_review_count are always over every review.
create function secondhand.list_member_reviews(
  p_shop_id uuid default null,
  p_verdict text default null,
  p_role text default null,
  p_before timestamptz default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := case when coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then null else auth.uid() end;
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_reviewer_role text := case p_role when 'seller' then 'buyer' when 'buyer' then 'seller' end;
  v_items jsonb;
  v_more boolean;
  v_counts jsonb;
begin
  if (p_verdict is not null and p_verdict not in ('good', 'bad'))
     or (p_role is not null and p_role not in ('seller', 'buyer')) then
    raise exception 'invalid_filter' using errcode = '22023';
  end if;
  if p_shop_id is null then
    if u is null then
      raise exception 'Authentication required' using errcode = '42501';
    end if;
  elsif not exists (select 1 from public.shops s where s.id = p_shop_id) then
    raise exception 'Shop not found' using errcode = '22023';
  end if;

  select coalesce(jsonb_agg(x.item order by x.created_at desc, x.id desc), '[]'::jsonb) into v_items
    from (
      select r.id, r.created_at, jsonb_build_object(
               'id', r.id,
               'verdict', r.verdict,
               'comment', r.comment,
               'preset_text', r.preset_text,
               'reviewer_role', r.reviewer_role,
               'created_at', r.created_at,
               'reported', u is not null and exists (select 1 from secondhand.review_reports rr
                                                      where rr.review_id = r.id and rr.reporter_id = u),
               'can_report', u is not null and u <> r.reviewer_id,
               'reviewer', jsonb_build_object(
                 'display_name', coalesce(nullif(btrim(m.display_name), ''), secondhand.kao_id_name_r21c(r.reviewer_id)),
                 'avatar_url', m.avatar_url,
                 'shop_id', (select s.id from public.shops s
                              where s.owner_id = r.reviewer_id and s.seller_identity_type = 'personal'
                                and s.shop_status = 'active'
                              order by s.created_at limit 1))) as item
        from secondhand.review_scope_r42(p_shop_id, u) r
        left join secondhand.member_profiles m on m.profile_id = r.reviewer_id
       where (p_verdict is null or r.verdict = p_verdict)
         and (v_reviewer_role is null or r.reviewer_role = v_reviewer_role)
         and (p_before is null or r.created_at < p_before)
       order by r.created_at desc, r.id desc
       limit v_limit + 1
    ) x;

  v_more := jsonb_array_length(v_items) > v_limit;
  if v_more then
    v_items := v_items - v_limit;
  end if;

  select jsonb_build_object(
           'review_count', count(*) filter (where v_reviewer_role is null or r.reviewer_role = v_reviewer_role),
           'good_count', count(*) filter (where (v_reviewer_role is null or r.reviewer_role = v_reviewer_role)
                                            and r.verdict = 'good'),
           'bad_count', count(*) filter (where (v_reviewer_role is null or r.reviewer_role = v_reviewer_role)
                                           and r.verdict = 'bad'),
           'rating', round(5.0 * count(*) filter (where r.verdict = 'good') / nullif(count(*), 0), 1),
           'seller_review_count', count(*) filter (where r.reviewer_role = 'buyer'),
           'buyer_review_count', count(*) filter (where r.reviewer_role = 'seller'))
    into v_counts
    from secondhand.review_scope_r42(p_shop_id, u) r;

  return v_counts || jsonb_build_object('reviews', v_items, 'has_more', v_more);
end $$;

revoke all on function secondhand.list_member_reviews(uuid, text, text, timestamptz, integer) from public;
grant execute on function secondhand.list_member_reviews(uuid, text, text, timestamptz, integer) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Shop reports (reviewed later from the Kao ID Admin Hub)
-- ---------------------------------------------------------------------------
create table if not exists secondhand.shop_reports (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (reason in (
    'fraud_suspected', 'counterfeit', 'prohibited_item', 'impersonation', 'inappropriate_content', 'spam', 'other')),
  detail text check (detail is null or char_length(detail) <= 1000),
  status text not null default 'pending' check (status in ('pending', 'reviewing', 'resolved', 'rejected')),
  handled_by uuid references public.profiles(id),
  handled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (shop_id, reporter_id)
);

create index if not exists shop_reports_status_r42 on secondhand.shop_reports (status, created_at);
create index if not exists shop_reports_reporter_r42 on secondhand.shop_reports (reporter_id);

alter table secondhand.shop_reports enable row level security;
revoke all on secondhand.shop_reports from public, anon, authenticated;

create or replace function secondhand.report_shop(p_shop_id uuid, p_reason text, p_detail text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
  v_detail text := nullif(btrim(coalesce(p_detail, '')), '');
  v_owner uuid;
  v_id uuid;
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  select s.owner_id into v_owner from public.shops s where s.id = p_shop_id and s.shop_status = 'active';
  if v_owner is null then
    raise exception 'Shop not found' using errcode = '22023';
  end if;
  if v_owner = u then
    raise exception 'Cannot report your own shop' using errcode = '22023';
  end if;
  if p_reason is null or p_reason not in (
    'fraud_suspected', 'counterfeit', 'prohibited_item', 'impersonation', 'inappropriate_content', 'spam', 'other') then
    raise exception 'Report reason is invalid' using errcode = '22023';
  end if;
  if p_reason = 'other' and v_detail is null then
    raise exception 'Report detail is required' using errcode = '22023';
  end if;
  if char_length(coalesce(v_detail, '')) > 1000 then
    raise exception 'Report detail is too long' using errcode = '22023';
  end if;

  insert into secondhand.shop_reports (shop_id, reporter_id, reason, detail)
  values (p_shop_id, u, p_reason, v_detail)
  on conflict (shop_id, reporter_id) do nothing
  returning id into v_id;
  return jsonb_build_object('already_reported', v_id is null);
end $$;

revoke all on function secondhand.report_shop(uuid, text, text) from public, anon, authenticated;
grant execute on function secondhand.report_shop(uuid, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- The shop page
-- ---------------------------------------------------------------------------
-- block_id: the viewer's own block of the owner, for "เลิกบล็อก". blocked: a block either way, so no following.
create or replace function secondhand.get_shop_profile(p_shop_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select secondhand.seller_card_r20d(s.id)
         || jsonb_build_object(
              'is_owner', v.u is not null and s.owner_id = v.u,
              'shipping', secondhand.shop_shipping_r36(s.id),
              'sold_items_count', (select count(*) from public.products p
                                    where p.shop_id = s.id and p.status = 'sold' and p.is_active),
              'block_id', (select b.id from public.user_blocks b
                            where b.blocker_profile_id = v.u and b.blocked_profile_id = s.owner_id and b.is_active
                              and (b.expires_at is null or b.expires_at > now())),
              'blocked', v.u is not null and secondhand.blocked_between_r21b(v.u, s.owner_id),
              'reported', v.u is not null and exists (select 1 from secondhand.shop_reports r
                                                        where r.shop_id = s.id and r.reporter_id = v.u)
            )
    from public.shops s
   cross join (select case when coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then null
                           else auth.uid() end as u) v
   where s.id = p_shop_id
     and (s.shop_status = 'active' or (v.u is not null and s.owner_id = v.u))
$$;

revoke all on function secondhand.get_shop_profile(uuid) from public;
grant execute on function secondhand.get_shop_profile(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Blocking also ends follows between the two members
-- ---------------------------------------------------------------------------
create or replace function secondhand.block_member(
  p_shop_id uuid default null,
  p_offer_id uuid default null,
  p_reason text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
  v_target uuid;
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
  v_id uuid;
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  if (p_shop_id is null) = (p_offer_id is null) then
    raise exception 'Choose one member to block';
  end if;

  if p_shop_id is not null then
    select s.owner_id into v_target from public.shops s where s.id = p_shop_id;
  else
    select o.buyer_id into v_target from secondhand.price_offers o where o.id = p_offer_id and o.seller_id = u;
  end if;
  if v_target is null then
    raise exception 'Member not found';
  end if;
  if v_target = u then
    raise exception 'You cannot block yourself';
  end if;
  if char_length(v_reason) > 200 then
    raise exception 'Reason must be at most 200 characters';
  end if;
  if not exists (select 1 from public.user_blocks b where b.blocker_profile_id = u and b.blocked_profile_id = v_target)
     and (select count(*) from public.user_blocks b where b.blocker_profile_id = u) >= 500 then
    raise exception 'block_limit_reached';
  end if;

  insert into public.user_blocks (blocker_profile_id, blocked_profile_id, reason)
  values (u, v_target, v_reason)
  on conflict (blocker_profile_id, blocked_profile_id)
  do update set is_active = true, expires_at = null, reason = excluded.reason
  returning id into v_id;

  update secondhand.price_offers o
     set status = 'cancelled', cancel_reason = 'blocked', updated_at = now()
   where o.status in ('pending', 'accepted')
     and ((o.buyer_id = u and o.seller_id = v_target) or (o.buyer_id = v_target and o.seller_id = u));

  delete from public.followers f
   using public.shops s
   where s.id = f.shop_id
     and ((f.profile_id = u and s.owner_id = v_target) or (f.profile_id = v_target and s.owner_id = u));

  return jsonb_build_object('id', v_id);
end $$;

revoke all on function secondhand.block_member(uuid, uuid, text) from public, anon, authenticated;
grant execute on function secondhand.block_member(uuid, uuid, text) to authenticated;

update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
         'secondhand.list_shop_items', 'secondhand.report_shop']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
