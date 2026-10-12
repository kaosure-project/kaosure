-- R19c: Secondhand shipping addresses and reviews, owned by the market app.
--
-- Addresses are private to their owner (an order will snapshot the address it
-- ships to). Reviews are public, one per side of a completed order, and are
-- written only through functions that check the order.

-- ---------------------------------------------------------------------------
-- Shipping addresses
-- ---------------------------------------------------------------------------
create table secondhand.shipping_addresses (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  label text check (label is null or char_length(label) <= 40),
  recipient_name text not null check (char_length(btrim(recipient_name)) between 1 and 100),
  phone text not null check (phone ~ '^[1-9][0-9]{7,14}$'),
  country_code text not null default 'TH' check (country_code ~ '^[A-Z]{2}$'),
  postal_code text not null check (postal_code ~ '^[A-Za-z0-9 -]{3,10}$'),
  province text not null check (char_length(btrim(province)) between 1 and 100),
  district text check (district is null or char_length(district) <= 100),
  subdistrict text check (subdistrict is null or char_length(subdistrict) <= 100),
  address_line1 text not null check (char_length(btrim(address_line1)) between 1 and 200),
  address_line2 text check (address_line2 is null or char_length(address_line2) <= 200),
  delivery_note text check (delivery_note is null or char_length(delivery_note) <= 200),
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index shipping_addresses_one_default on secondhand.shipping_addresses(profile_id) where is_default;
create index shipping_addresses_profile on secondhand.shipping_addresses(profile_id, created_at);

-- First address becomes the default, a new default replaces the old one, and a
-- member keeps at most 10 addresses.
create or replace function secondhand.shipping_address_rules() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    if (select count(*) from secondhand.shipping_addresses a where a.profile_id = new.profile_id) >= 10 then
      raise exception 'address_limit_reached' using errcode = '23514';
    end if;
    if not exists(select 1 from secondhand.shipping_addresses a where a.profile_id = new.profile_id) then
      new.is_default := true;
    end if;
  else
    new.updated_at := now();
  end if;
  if new.is_default then
    update secondhand.shipping_addresses a set is_default = false
     where a.profile_id = new.profile_id and a.id <> new.id and a.is_default;
  end if;
  return new;
end $$;

create trigger shipping_address_rules before insert or update on secondhand.shipping_addresses
  for each row execute function secondhand.shipping_address_rules();

alter table secondhand.shipping_addresses enable row level security;
revoke all on table secondhand.shipping_addresses from public, anon, authenticated;
grant select, delete on table secondhand.shipping_addresses to authenticated;
grant insert (label, recipient_name, phone, country_code, postal_code, province, district, subdistrict,
  address_line1, address_line2, delivery_note, is_default) on table secondhand.shipping_addresses to authenticated;
grant update (label, recipient_name, phone, country_code, postal_code, province, district, subdistrict,
  address_line1, address_line2, delivery_note, is_default) on table secondhand.shipping_addresses to authenticated;
grant all on table secondhand.shipping_addresses to service_role;

create policy shipping_addresses_own on secondhand.shipping_addresses for all to authenticated
  using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));
create policy account_closure_r10d on secondhand.shipping_addresses as restrictive for all to authenticated
  using ((select kaoid_private.data_access_r10d())) with check ((select kaoid_private.data_access_r10d()));

-- ---------------------------------------------------------------------------
-- Reviews
-- ---------------------------------------------------------------------------
create table secondhand.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id) on delete cascade,
  reviewee_id uuid not null references public.profiles(id) on delete cascade,
  -- The reviewer's side of the order: 'buyer' rates the seller, 'seller' rates the buyer.
  reviewer_role text not null check (reviewer_role in ('buyer', 'seller')),
  rating smallint not null check (rating between 1 and 5),
  comment text check (comment is null or char_length(comment) <= 1000),
  reply text check (reply is null or char_length(reply) <= 1000),
  replied_at timestamptz,
  is_visible boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (order_id, reviewer_id),
  check (reviewer_id <> reviewee_id)
);

create index reviews_reviewee on secondhand.reviews(reviewee_id, created_at desc);

alter table secondhand.reviews enable row level security;
revoke all on table secondhand.reviews from public, anon, authenticated;
grant select on table secondhand.reviews to anon, authenticated;
grant all on table secondhand.reviews to service_role;

create policy reviews_read on secondhand.reviews for select to anon, authenticated
  using (is_visible or reviewer_id = (select auth.uid()));
create policy account_closure_r10d on secondhand.reviews as restrictive for all to authenticated
  using ((select kaoid_private.data_access_r10d())) with check ((select kaoid_private.data_access_r10d()));

create view secondhand.member_ratings with (security_invoker = true) as
select reviewee_id as profile_id,
       count(*) filter (where reviewer_role = 'buyer') as seller_review_count,
       round(avg(rating) filter (where reviewer_role = 'buyer'), 2) as seller_rating,
       count(*) filter (where reviewer_role = 'seller') as buyer_review_count,
       round(avg(rating) filter (where reviewer_role = 'seller'), 2) as buyer_rating
  from secondhand.reviews
 where is_visible
 group by reviewee_id;

revoke all on secondhand.member_ratings from public, anon, authenticated;
grant select on secondhand.member_ratings to anon, authenticated;

-- One review per side of a completed order; editable for 30 days.
create or replace function secondhand.submit_review(p_order_id uuid, p_rating integer, p_comment text default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid();
  o public.orders;
  v_comment text := nullif(btrim(coalesce(p_comment, '')), '');
  v_role text;
  v_existing secondhand.reviews;
  v_id uuid;
begin
  if u is null then raise exception 'authentication_required' using errcode = '42501'; end if;
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
  if p_rating is null or p_rating not between 1 and 5 or char_length(coalesce(v_comment, '')) > 1000 then
    raise exception 'invalid_review' using errcode = '22023';
  end if;
  v_role := case when u = o.buyer_id then 'buyer' else 'seller' end;
  select * into v_existing from secondhand.reviews where order_id = p_order_id and reviewer_id = u;
  if found and v_existing.created_at < now() - interval '30 days' then
    raise exception 'review_locked' using errcode = '22023';
  end if;
  insert into secondhand.reviews(order_id, reviewer_id, reviewee_id, reviewer_role, rating, comment)
  values (p_order_id, u, case when v_role = 'buyer' then o.seller_id else o.buyer_id end, v_role, p_rating, v_comment)
  on conflict (order_id, reviewer_id) do update set rating = excluded.rating, comment = excluded.comment,
    updated_at = now()
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'created', v_existing.id is null, 'reviewer_role', v_role);
end $$;

-- The reviewed member may answer once and edit the answer for 30 days.
create or replace function secondhand.reply_review(p_review_id uuid, p_reply text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid();
  r secondhand.reviews;
  v_reply text := nullif(btrim(coalesce(p_reply, '')), '');
begin
  if u is null then raise exception 'authentication_required' using errcode = '42501'; end if;
  if coalesce(kaoid_private.account_access_r10d()->>'state', '') <> 'active' then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  select * into r from secondhand.reviews where id = p_review_id;
  if not found or r.reviewee_id <> u then raise exception 'review_not_found' using errcode = '22023'; end if;
  if v_reply is null or char_length(v_reply) > 1000 then raise exception 'invalid_review' using errcode = '22023'; end if;
  if r.replied_at is not null and r.replied_at < now() - interval '30 days' then
    raise exception 'review_locked' using errcode = '22023';
  end if;
  update secondhand.reviews set reply = v_reply, replied_at = coalesce(replied_at, now()), updated_at = now()
   where id = p_review_id;
end $$;

revoke all on function
  secondhand.shipping_address_rules(),
  secondhand.submit_review(uuid, integer, text),
  secondhand.reply_review(uuid, text)
from public, anon, authenticated;
grant execute on function secondhand.submit_review(uuid, integer, text), secondhand.reply_review(uuid, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Secondhand token scope
-- ---------------------------------------------------------------------------
update kaoid_private.app_clients_r18
   set allowed_tables = array(select distinct t from unnest(allowed_tables || array[
         'secondhand.shipping_addresses:write', 'secondhand.reviews', 'secondhand.member_ratings']) t order by 1),
       allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
         'secondhand.submit_review', 'secondhand.reply_review']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
