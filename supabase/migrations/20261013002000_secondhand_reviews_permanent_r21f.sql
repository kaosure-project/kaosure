-- R21f: reviews follow Yahoo! Flea Market exactly.
--
--   * After a completed order each side rates the other "ดี" (good) or
--     "ไม่ดี" (bad) with an optional message. No preset comments, no replies.
--   * A review is permanent: it is sent once and can never be edited.
--   * Stars appear only on the profile header and come from all reviews the
--     member received: 5 x good / (good + bad), e.g. 9 good and 1 bad = 4.5.
--   * list_member_reviews() feeds the review page with tabs ทั้งหมด / ดี / ไม่ดี.

-- ---------------------------------------------------------------------------
-- Permanent good / bad reviews
-- ---------------------------------------------------------------------------
alter table secondhand.reviews
  add constraint reviews_no_preset_r21f check (preset_code is null),
  add constraint reviews_no_reply_r21f check (reply is null and replied_at is null);

-- Only moderation may change a review, and only whether it is shown.
create or replace function secondhand.review_permanent_r21f()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (new.order_id, new.reviewer_id, new.reviewee_id, new.reviewer_role, new.verdict, new.comment,
      new.preset_code, new.reply, new.replied_at, new.created_at)
     is distinct from
     (old.order_id, old.reviewer_id, old.reviewee_id, old.reviewer_role, old.verdict, old.comment,
      old.preset_code, old.reply, old.replied_at, old.created_at) then
    raise exception 'review_permanent' using errcode = '42501';
  end if;
  return new;
end $$;

revoke all on function secondhand.review_permanent_r21f() from public, anon, authenticated;

create trigger reviews_permanent_r21f
  before update on secondhand.reviews
  for each row execute function secondhand.review_permanent_r21f();

drop function secondhand.submit_review(uuid, text, text, text);

create or replace function secondhand.submit_review(p_order_id uuid, p_verdict text, p_comment text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
  o public.orders;
  v_comment text := nullif(btrim(coalesce(p_comment, '')), '');
  v_role text;
  v_id uuid;
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if coalesce(kaoid_private.account_access_r10d()->>'state', '') <> 'active' then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  select * into o from public.orders where id = p_order_id;
  if not found or u not in (o.buyer_id, o.seller_id) then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  if o.completed_at is null and coalesce(o.order_status, '') <> 'completed' then
    raise exception 'order_not_completed' using errcode = '22023';
  end if;
  if p_verdict is null or p_verdict not in ('good', 'bad') or char_length(coalesce(v_comment, '')) > 1000 then
    raise exception 'invalid_review' using errcode = '22023';
  end if;
  v_role := case when u = o.buyer_id then 'buyer' else 'seller' end;

  insert into secondhand.reviews(order_id, reviewer_id, reviewee_id, reviewer_role, verdict, comment)
  values (p_order_id, u, case when v_role = 'buyer' then o.seller_id else o.buyer_id end, v_role, p_verdict, v_comment)
  on conflict (order_id, reviewer_id) do nothing
  returning id into v_id;
  if v_id is null then
    raise exception 'review_already_sent' using errcode = '23505';
  end if;
  return jsonb_build_object('id', v_id, 'reviewer_role', v_role, 'verdict', p_verdict);
end $$;

revoke all on function secondhand.submit_review(uuid, text, text) from public, anon, authenticated;
grant execute on function secondhand.submit_review(uuid, text, text) to authenticated;

-- Replies and preset comments are retired; the objects stay until the owner
-- approves removing them.
revoke all on function secondhand.reply_review(uuid, text) from public, anon, authenticated;
update secondhand.review_presets set is_active = false where is_active;
revoke all on table secondhand.review_presets from anon, authenticated;

-- ---------------------------------------------------------------------------
-- One score from every review received
-- ---------------------------------------------------------------------------
create or replace view secondhand.member_ratings with (security_invoker = true) as
select reviewee_id as profile_id,
       count(*) filter (where reviewer_role = 'buyer') as seller_review_count,
       count(*) filter (where reviewer_role = 'buyer' and verdict = 'good') as seller_good_count,
       count(*) filter (where reviewer_role = 'buyer' and verdict = 'bad') as seller_bad_count,
       round(5.0 * count(*) filter (where reviewer_role = 'buyer' and verdict = 'good')
             / nullif(count(*) filter (where reviewer_role = 'buyer'), 0), 1) as seller_rating,
       count(*) filter (where reviewer_role = 'seller') as buyer_review_count,
       count(*) filter (where reviewer_role = 'seller' and verdict = 'good') as buyer_good_count,
       count(*) filter (where reviewer_role = 'seller' and verdict = 'bad') as buyer_bad_count,
       round(5.0 * count(*) filter (where reviewer_role = 'seller' and verdict = 'good')
             / nullif(count(*) filter (where reviewer_role = 'seller'), 0), 1) as buyer_rating,
       count(*) as review_count,
       count(*) filter (where verdict = 'good') as good_count,
       count(*) filter (where verdict = 'bad') as bad_count,
       round(5.0 * count(*) filter (where verdict = 'good') / nullif(count(*), 0), 1) as rating
  from secondhand.reviews
 where is_visible
 group by reviewee_id;

revoke all on secondhand.member_ratings from public, anon, authenticated;
grant select on secondhand.member_ratings to anon, authenticated;

create or replace function secondhand.seller_card_r20d(p_shop_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'shop_id', s.id,
    'shop_name', s.shop_name,
    'shop_slug', s.shop_slug,
    'shop_description', s.description,
    'province', s.province,
    'joined_at', s.created_at,
    'display_name', coalesce(nullif(btrim(m.display_name), ''), s.shop_name),
    'avatar_url', m.avatar_url,
    'bio', m.bio,
    'rating', r.rating,
    'review_count', coalesce(r.review_count, 0),
    'good_count', coalesce(r.good_count, 0),
    'bad_count', coalesce(r.bad_count, 0),
    'is_verified', s.seller_identity_type = 'personal'
                   and coalesce((secondhand.seller_status_r20f(s.owner_id)->>'verified')::boolean, false),
    'follower_count', (select count(*) from public.followers f where f.shop_id = s.id),
    'sold_count', (select count(*) from public.orders o where o.shop_id = s.id and o.order_status = 'completed'),
    'on_sale_count', (select count(*) from public.products p
                       join public.categories c on c.id = p.category_id and c.is_active
                      where p.shop_id = s.id and p.status = 'active' and p.is_active and p.stock > 0)
  )
  from public.shops s
  left join secondhand.member_profiles m on m.profile_id = s.owner_id
  left join secondhand.member_ratings r on r.profile_id = s.owner_id
  where s.id = p_shop_id
$$;

revoke all on function secondhand.seller_card_r20d(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Review page: ทั้งหมด / ดี / ไม่ดี, newest first, without stars per review
-- ---------------------------------------------------------------------------
create or replace function secondhand.list_member_reviews(
  p_shop_id uuid default null,
  p_verdict text default null,
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
  v_profile uuid;
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_items jsonb;
  v_more boolean;
begin
  if p_verdict is not null and p_verdict not in ('good', 'bad') then
    raise exception 'invalid_filter' using errcode = '22023';
  end if;
  if p_shop_id is null then
    v_profile := auth.uid();
    if v_profile is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
      raise exception 'Authentication required' using errcode = '42501';
    end if;
  else
    select s.owner_id into v_profile
      from public.shops s
     where s.id = p_shop_id and s.seller_identity_type = 'personal';
    if v_profile is null then
      raise exception 'Shop not found' using errcode = '22023';
    end if;
  end if;

  select coalesce(jsonb_agg(x.item order by x.created_at desc, x.id desc), '[]'::jsonb) into v_items
    from (
      select r.id, r.created_at, jsonb_build_object(
               'id', r.id,
               'verdict', r.verdict,
               'comment', r.comment,
               'reviewer_role', r.reviewer_role,
               'created_at', r.created_at,
               'reviewer', jsonb_build_object(
                 'display_name', coalesce(nullif(btrim(m.display_name), ''), secondhand.kao_id_name_r21c(r.reviewer_id)),
                 'avatar_url', m.avatar_url,
                 'shop_id', (select s.id from public.shops s
                              where s.owner_id = r.reviewer_id and s.seller_identity_type = 'personal'
                                and s.shop_status = 'active'
                              order by s.created_at limit 1))) as item
        from secondhand.reviews r
        left join secondhand.member_profiles m on m.profile_id = r.reviewer_id
       where r.reviewee_id = v_profile and r.is_visible
         and (p_verdict is null or r.verdict = p_verdict)
         and (p_before is null or r.created_at < p_before)
       order by r.created_at desc, r.id desc
       limit v_limit + 1
    ) x;

  v_more := jsonb_array_length(v_items) > v_limit;
  if v_more then
    v_items := v_items - v_limit;
  end if;

  return (
    select jsonb_build_object(
      'review_count', coalesce(mr.review_count, 0),
      'good_count', coalesce(mr.good_count, 0),
      'bad_count', coalesce(mr.bad_count, 0),
      'rating', mr.rating,
      'reviews', v_items,
      'has_more', v_more)
      from (select 1) one
      left join secondhand.member_ratings mr on mr.profile_id = v_profile);
end $$;

revoke all on function secondhand.list_member_reviews(uuid, text, timestamptz, integer) from public;
grant execute on function secondhand.list_member_reviews(uuid, text, timestamptz, integer) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- My Page: the header score is the overall one
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

revoke all on function secondhand.get_my_page() from public, anon, authenticated;
grant execute on function secondhand.get_my_page() to authenticated;

-- ---------------------------------------------------------------------------
-- Secondhand token scope
-- ---------------------------------------------------------------------------
update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array['secondhand.list_member_reviews']) r
                             where r <> 'secondhand.reply_review' order by 1),
       allowed_tables = array(select distinct t from unnest(allowed_tables) t
                               where t <> 'secondhand.review_presets' order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
