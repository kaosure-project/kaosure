-- R20d: product detail page and simple shop page.
-- One read RPC for the detail page and one for the shop card, listing
-- questions (ask / answer / remove) and listing reports. The two new tables
-- are reached only through these RPCs.

-- ---------------------------------------------------------------------------
-- Visibility: the same rule as the public products policy
-- ---------------------------------------------------------------------------
create or replace function secondhand.listing_public_r20d(p_product_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.products p
      join public.shops s on s.id = p.shop_id and s.shop_status = 'active'
      join public.categories c on c.id = p.category_id and c.is_active
     where p.id = p_product_id and p.status = 'active' and p.is_active and p.stock > 0
  )
$$;

create or replace function secondhand.listing_owner_r20d(p_product_id uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select s.owner_id from public.products p join public.shops s on s.id = p.shop_id where p.id = p_product_id
$$;

revoke all on function secondhand.listing_public_r20d(uuid) from public, anon, authenticated;
revoke all on function secondhand.listing_owner_r20d(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Seller card: shop, profile, ratings and counts
-- ---------------------------------------------------------------------------
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
    'rating', r.seller_rating,
    'review_count', coalesce(r.seller_review_count, 0),
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
-- Product detail: everything the page shows, in one call
-- ---------------------------------------------------------------------------
create or replace function secondhand.get_listing_detail(p_product_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_owner uuid := secondhand.listing_owner_r20d(p_product_id);
  v_is_owner boolean;
  v_result jsonb;
begin
  v_is_owner := v_uid is not null and v_owner = v_uid and kaoid_private.account_active_r9f();
  if v_owner is null or not (v_is_owner or secondhand.listing_public_r20d(p_product_id)) then
    return null;
  end if;

  select jsonb_build_object(
      'product_id', p.id,
      'title', p.title,
      'description', p.description,
      'price', p.price,
      'currency', p.currency,
      'condition_level', p.condition_level,
      'status', p.status,
      'is_active', p.is_active,
      'stock', p.stock,
      'favorite_count', p.favorite_count,
      'view_count', p.view_count,
      'created_at', p.created_at,
      'updated_at', p.updated_at,
      'image_paths', coalesce((select jsonb_agg(i.image_url order by i.image_order)
                                 from public.product_images i where i.product_id = p.id), '[]'::jsonb),
      'category', jsonb_build_object('id', c.id, 'name', c.name, 'active', c.is_active,
                                     'parent_id', pc.id, 'parent_name', pc.name),
      'shipping', case when l.product_id is null then null else jsonb_build_object(
          'payer', l.shipping_payer,
          'option_code', l.shipping_option_code,
          'option_name', so.name_th,
          'partner_name', sp.name_th,
          'days_min', so.estimated_days_min,
          'days_max', so.estimated_days_max,
          'package_max_weight_g', l.package_max_weight_g,
          'package_max_size_cm', (select r.max_size_cm from secondhand.shipping_rates r
                                   where r.option_code = l.shipping_option_code
                                     and r.max_weight_g = l.package_max_weight_g
                                   order by r.max_size_cm desc limit 1),
          'ship_from_province', l.ship_from_province,
          'ship_from_province_name', tp.name_th,
          'ship_within', l.ship_within) end,
      'handling_time_days', p.handling_time_days,
      'seller', secondhand.seller_card_r20d(p.shop_id),
      'is_owner', v_is_owner,
      'open_order', v_is_owner and exists (select 1 from public.orders o
                                             where o.product_id = p.id
                                               and o.order_status not in ('cancelled', 'completed', 'refunded')),
      'question_count', (select count(*) from secondhand.listing_questions q
                          where q.product_id = p.id and not q.is_hidden)
    )
    into v_result
    from public.products p
    left join public.categories c on c.id = p.category_id
    left join public.categories pc on pc.id = c.parent_id
    left join secondhand.listings l on l.product_id = p.id
    left join secondhand.shipping_options so on so.code = l.shipping_option_code
    left join secondhand.shipping_partners sp on sp.code = so.partner_code
    left join secondhand.thai_provinces tp on tp.code = l.ship_from_province
   where p.id = p_product_id;
  return v_result;
end $$;

-- Public shop card; a closed shop is only visible to its owner.
create or replace function secondhand.get_shop_profile(p_shop_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select secondhand.seller_card_r20d(s.id)
         || jsonb_build_object('is_owner', auth.uid() is not null and s.owner_id = auth.uid())
    from public.shops s
   where s.id = p_shop_id
     and (s.shop_status = 'active' or (auth.uid() is not null and s.owner_id = auth.uid()))
$$;

-- ---------------------------------------------------------------------------
-- Questions under a listing (Yahoo! Flea Market style comments)
-- ---------------------------------------------------------------------------
create table secondhand.listing_questions (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  asker_id uuid not null references public.profiles(id) on delete cascade,
  question text not null check (char_length(btrim(question)) between 1 and 500),
  answer text check (answer is null or char_length(btrim(answer)) between 1 and 1000),
  answered_at timestamptz,
  is_hidden boolean not null default false,
  hidden_reason text check (hidden_reason is null or hidden_reason in ('asker', 'seller', 'moderator')),
  hidden_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index listing_questions_product_r20d on secondhand.listing_questions (product_id, created_at);
create index listing_questions_asker_r20d on secondhand.listing_questions (asker_id, created_at desc);

alter table secondhand.listing_questions enable row level security;
revoke all on secondhand.listing_questions from public, anon, authenticated;

create or replace function secondhand.list_listing_questions(p_product_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', q.id,
      'question', q.question,
      'answer', q.answer,
      'answered_at', q.answered_at,
      'created_at', q.created_at,
      'asker_name', coalesce(nullif(btrim(m.display_name), ''), 'สมาชิก KaoSure'),
      'asker_avatar_url', m.avatar_url,
      'is_mine', auth.uid() is not null and q.asker_id = auth.uid()
    ) order by q.created_at), '[]'::jsonb)
  from secondhand.listing_questions q
  left join secondhand.member_profiles m on m.profile_id = q.asker_id
  where q.product_id = p_product_id
    and not q.is_hidden
    and (secondhand.listing_public_r20d(p_product_id)
         or (auth.uid() is not null and secondhand.listing_owner_r20d(p_product_id) = auth.uid()))
$$;

create or replace function secondhand.ask_listing_question(p_product_id uuid, p_question text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_owner uuid;
  v_text text := btrim(coalesce(p_question, ''));
  v_id uuid;
  v_title text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  if not secondhand.listing_public_r20d(p_product_id) then
    raise exception 'Listing not found';
  end if;
  v_owner := secondhand.listing_owner_r20d(p_product_id);
  if v_owner = v_uid then
    raise exception 'Sellers answer questions instead of asking';
  end if;
  if char_length(v_text) not between 1 and 500 then
    raise exception 'Question must contain 1 to 500 characters';
  end if;
  if (select count(*) from secondhand.listing_questions q
       where q.asker_id = v_uid and q.created_at > now() - interval '10 minutes') >= 5 then
    raise exception 'Too many questions, try again later';
  end if;

  insert into secondhand.listing_questions (product_id, asker_id, question)
  values (p_product_id, v_uid, v_text)
  returning id into v_id;

  select p.title into v_title from public.products p where p.id = p_product_id;
  insert into public.notifications (profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (v_owner, 'มีคำถามใหม่ในสินค้าของคุณ', left(v_title, 80) || ': ' || left(v_text, 120),
          'listing_question', p_product_id, '/items/' || p_product_id, 'listing_question:' || v_id);

  return jsonb_build_object('id', v_id);
end $$;

create or replace function secondhand.answer_listing_question(p_question_id uuid, p_answer text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_question secondhand.listing_questions;
  v_text text := btrim(coalesce(p_answer, ''));
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  select * into v_question from secondhand.listing_questions q where q.id = p_question_id for update;
  if not found or v_question.is_hidden or secondhand.listing_owner_r20d(v_question.product_id) is distinct from v_uid then
    raise exception 'Question not found';
  end if;
  if char_length(v_text) not between 1 and 1000 then
    raise exception 'Answer must contain 1 to 1000 characters';
  end if;

  update secondhand.listing_questions
     set answer = v_text, answered_at = now(), updated_at = now()
   where id = p_question_id;

  if v_question.answer is null then
    insert into public.notifications (profile_id, title, message, notification_type, target_id, action_url, event_key)
    values (v_question.asker_id, 'ผู้ขายตอบคำถามของคุณแล้ว', left(v_text, 160),
            'listing_answer', v_question.product_id, '/items/' || v_question.product_id,
            'listing_answer:' || p_question_id);
  end if;
  return jsonb_build_object('id', p_question_id);
end $$;

-- The asker removes their own question; the seller removes any on their listing.
create or replace function secondhand.delete_listing_question(p_question_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_question secondhand.listing_questions;
  v_reason text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  select * into v_question from secondhand.listing_questions q where q.id = p_question_id for update;
  if not found or v_question.is_hidden then
    raise exception 'Question not found';
  end if;
  v_reason := case
    when secondhand.listing_owner_r20d(v_question.product_id) = v_uid then 'seller'
    when v_question.asker_id = v_uid then 'asker'
  end;
  if v_reason is null then
    raise exception 'Question not found';
  end if;
  update secondhand.listing_questions
     set is_hidden = true, hidden_reason = v_reason, hidden_at = now(), updated_at = now()
   where id = p_question_id;
  return jsonb_build_object('id', p_question_id);
end $$;

-- ---------------------------------------------------------------------------
-- Listing reports (reviewed later from the Kao ID Admin Hub)
-- ---------------------------------------------------------------------------
create table secondhand.listing_reports (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (reason in (
    'prohibited_item', 'counterfeit', 'misleading', 'inappropriate_content', 'spam', 'fraud_suspected', 'other')),
  detail text check (detail is null or char_length(detail) <= 1000),
  status text not null default 'pending' check (status in ('pending', 'reviewing', 'resolved', 'rejected')),
  handled_by uuid references public.profiles(id),
  handled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (product_id, reporter_id)
);

create index listing_reports_status_r20d on secondhand.listing_reports (status, created_at);

alter table secondhand.listing_reports enable row level security;
revoke all on secondhand.listing_reports from public, anon, authenticated;

create or replace function secondhand.report_listing(p_product_id uuid, p_reason text, p_detail text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_detail text := nullif(btrim(coalesce(p_detail, '')), '');
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  if not secondhand.listing_public_r20d(p_product_id) then
    raise exception 'Listing not found';
  end if;
  if secondhand.listing_owner_r20d(p_product_id) = v_uid then
    raise exception 'Cannot report your own listing';
  end if;
  if p_reason is null or p_reason not in (
    'prohibited_item', 'counterfeit', 'misleading', 'inappropriate_content', 'spam', 'fraud_suspected', 'other') then
    raise exception 'Report reason is invalid';
  end if;
  if p_reason = 'other' and v_detail is null then
    raise exception 'Report detail is required';
  end if;
  if char_length(coalesce(v_detail, '')) > 1000 then
    raise exception 'Report detail is too long';
  end if;

  insert into secondhand.listing_reports (product_id, reporter_id, reason, detail)
  values (p_product_id, v_uid, p_reason, v_detail)
  on conflict (product_id, reporter_id) do nothing
  returning id into v_id;
  return jsonb_build_object('already_reported', v_id is null);
end $$;

-- ---------------------------------------------------------------------------
-- Grants and Secondhand token scope
-- ---------------------------------------------------------------------------
revoke all on function secondhand.get_listing_detail(uuid) from public;
grant execute on function secondhand.get_listing_detail(uuid) to anon, authenticated;
revoke all on function secondhand.get_shop_profile(uuid) from public;
grant execute on function secondhand.get_shop_profile(uuid) to anon, authenticated;
revoke all on function secondhand.list_listing_questions(uuid) from public;
grant execute on function secondhand.list_listing_questions(uuid) to anon, authenticated;
revoke all on function secondhand.ask_listing_question(uuid, text) from public, anon;
grant execute on function secondhand.ask_listing_question(uuid, text) to authenticated;
revoke all on function secondhand.answer_listing_question(uuid, text) from public, anon;
grant execute on function secondhand.answer_listing_question(uuid, text) to authenticated;
revoke all on function secondhand.delete_listing_question(uuid) from public, anon;
grant execute on function secondhand.delete_listing_question(uuid) to authenticated;
revoke all on function secondhand.report_listing(uuid, text, text) from public, anon;
grant execute on function secondhand.report_listing(uuid, text, text) to authenticated;

update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
         'secondhand.get_listing_detail', 'secondhand.get_shop_profile', 'secondhand.list_listing_questions',
         'secondhand.ask_listing_question', 'secondhand.answer_listing_question',
         'secondhand.delete_listing_question', 'secondhand.report_listing']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
