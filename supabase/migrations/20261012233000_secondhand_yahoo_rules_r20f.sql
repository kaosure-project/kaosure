-- R20f: Yahoo! Flea Market style market rules.
--   * Two seller tiers: verified email + phone + bank account may list up to
--     market_settings.unverified_max_price per item; a Kao ID (identity
--     verified) seller lists up to max_price and shows "ยืนยันตัวตนแล้ว".
--   * Sold listings stay public (locked, shown in the shop with SOLD); closed
--     listings stay private to the seller.
--   * View count: once per viewer per listing per Thai calendar day, never the
--     owner.
--   * Listing questions and answers cannot be edited or removed once sent.
--   * Reviews are good / bad with preset comments; stars = good share x 5.

-- ---------------------------------------------------------------------------
-- Seller tiers
-- ---------------------------------------------------------------------------
alter table secondhand.market_settings
  add column unverified_max_price numeric(12,2) not null default 5000;
alter table secondhand.market_settings
  add constraint market_settings_unverified_max_price_r20f
  check (unverified_max_price between min_price and max_price);

-- What the member may list: email, phone and bank from Kao ID; "verified"
-- means an active personal Kao ID (identity checked) with a verified bank.
create or replace function secondhand.seller_status_r20f(p_profile_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_email boolean := false;
  v_phone boolean := false;
  v_bank boolean := false;
  v_kao_id boolean := false;
  v_verified boolean;
  v_can_list boolean;
  v_limit numeric(12,2);
begin
  if p_profile_id is not null then
    select u.email_confirmed_at is not null, u.phone_confirmed_at is not null
      into v_email, v_phone
      from auth.users u where u.id = p_profile_id;
    v_bank := exists (
      select 1
        from public.financial_verifications fv
        join public.bank_accounts ba on ba.id = fv.bank_account_id
       where fv.identity_type = 'personal' and fv.profile_id = p_profile_id and fv.organization_id is null
         and fv.status = 'approved' and fv.name_match_status = 'matched'
         and ba.profile_id = p_profile_id and ba.organization_id is null
         and ba.is_verified and ba.is_active and ba.deleted_at is null and ba.status = 'verified');
    v_kao_id := exists (
      select 1 from public.kao_id_identities k
       where k.profile_id = p_profile_id and k.organization_id is null
         and k.identity_type = 'personal' and k.status = 'active');
  end if;
  v_email := coalesce(v_email, false);
  v_phone := coalesce(v_phone, false);
  v_verified := v_kao_id and v_bank;
  v_can_list := v_verified or (v_email and v_phone and v_bank);
  if not v_verified then
    select s.unverified_max_price into v_limit from secondhand.market_settings s where s.id;
  end if;
  return jsonb_build_object(
    'email', v_email,
    'phone', v_phone,
    'bank', v_bank,
    'kao_id', v_kao_id,
    'verified', v_verified,
    'can_list', v_can_list,
    'price_limit', v_limit
  );
end $$;

revoke all on function secondhand.seller_status_r20f(uuid) from public, anon, authenticated;

create or replace function secondhand.get_seller_status()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  return secondhand.seller_status_r20f(auth.uid());
end $$;

-- max_price is what this seller may ask; market_max_price is the market cap.
create or replace function secondhand.get_listing_terms()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'currency', s.currency,
    'sales_fee_rate', s.sales_fee_rate,
    'first_sale_fee_rate', s.first_sale_fee_rate,
    'first_sale_available', s.first_sale_promo_enabled and auth.uid() is not null
      and not exists (select 1 from secondhand.first_sale_promotions f where f.profile_id = auth.uid()),
    'min_price', s.min_price,
    'max_price', least(s.max_price, coalesce((st.status->>'price_limit')::numeric, s.max_price)),
    'market_max_price', s.max_price,
    'price_limited', (st.status->>'price_limit') is not null,
    'max_photos', s.max_photos
  )
  from secondhand.market_settings s
  cross join lateral (select secondhand.seller_status_r20f(auth.uid()) as status) st
  where s.id
$$;

-- ---------------------------------------------------------------------------
-- Create a listing (R20b) with the seller tiers
-- ---------------------------------------------------------------------------
create or replace function secondhand.create_listing(
  p_category_id uuid,
  p_title text,
  p_description text,
  p_condition_level smallint,
  p_price numeric,
  p_image_paths text[],
  p_shipping_payer text,
  p_shipping_option text,
  p_package_max_weight_g integer,
  p_ship_from_province smallint,
  p_ship_within text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_seller jsonb;
  v_settings secondhand.market_settings;
  v_shop public.shops;
  v_shop_name text;
  v_product_id uuid := pg_catalog.gen_random_uuid();
  v_shipping_fee numeric(10,2);
  v_promo boolean := false;
  v_rate numeric(5,4);
  v_fee numeric(12,2);
  v_path text;
  v_order integer := 0;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  v_seller := secondhand.seller_status_r20f(v_uid);
  if not (v_seller->>'can_list')::boolean then
    raise exception 'Seller verification is required before listing products';
  end if;

  select * into strict v_settings from secondhand.market_settings where id;

  if not exists (select 1 from public.categories c where c.id = p_category_id and c.is_active) then
    raise exception 'Active category is required';
  end if;
  if p_title is null or char_length(btrim(p_title)) < 3 or char_length(p_title) > 100 then
    raise exception 'Product title must contain 3 to 100 characters';
  end if;
  if p_description is null or char_length(btrim(p_description)) < 10 or char_length(p_description) > 3000 then
    raise exception 'Product description must contain 10 to 3000 characters';
  end if;
  if p_condition_level is null or p_condition_level not between 1 and 6 then
    raise exception 'Product condition is invalid';
  end if;
  if p_price is null or p_price <> trunc(p_price) or p_price < v_settings.min_price or p_price > v_settings.max_price then
    raise exception 'Product price is invalid';
  end if;
  if p_price > coalesce((v_seller->>'price_limit')::numeric, v_settings.max_price) then
    raise exception 'Product price is above the unverified seller limit';
  end if;

  if p_image_paths is null or cardinality(p_image_paths) < 1 or cardinality(p_image_paths) > v_settings.max_photos then
    raise exception 'Product photo count is invalid';
  end if;
  if array_position(p_image_paths, null) is not null
     or cardinality(p_image_paths) <> (select count(distinct x) from unnest(p_image_paths) x) then
    raise exception 'Product photo paths must be unique and non-null';
  end if;
  foreach v_path in array p_image_paths loop
    if v_path !~ ('^' || v_uid::text || '/[A-Za-z0-9_-]+/(1?[0-9])\.(jpg|png|webp)$') then
      raise exception 'Invalid product photo path';
    end if;
    if not exists (
      select 1 from storage.objects o where o.bucket_id = 'marketplace-product-images' and o.name = v_path
    ) then
      raise exception 'Product photo upload was not found';
    end if;
  end loop;

  -- The seller always pays; the actual carrier charge is deducted after delivery.
  if p_shipping_payer is distinct from 'seller' then
    raise exception 'Shipping payer is invalid';
  end if;
  select r.fee into v_shipping_fee
    from secondhand.shipping_rates r
    join secondhand.shipping_options o on o.code = r.option_code and o.is_active
    join secondhand.shipping_partners p on p.code = o.partner_code and p.is_active
   where r.option_code = p_shipping_option and r.zone = 'upcountry' and r.max_weight_g = p_package_max_weight_g;
  if v_shipping_fee is null then
    raise exception 'Shipping option is invalid';
  end if;
  if not exists (select 1 from secondhand.thai_provinces t where t.code = p_ship_from_province) then
    raise exception 'Ship-from province is invalid';
  end if;
  if p_ship_within is null or p_ship_within not in ('1_2', '2_3', '4_7') then
    raise exception 'Shipping time is invalid';
  end if;

  -- One personal shop per account, named after the member's profile.
  select * into v_shop from public.shops s
   where s.owner_id = v_uid and s.seller_identity_type = 'personal'
   order by s.created_at
   limit 1
   for update;
  if not found then
    select left(btrim(regexp_replace(coalesce(
             nullif(btrim(m.display_name), ''),
             nullif(btrim(p.display_name), ''),
             nullif(btrim(concat_ws(' ', p.first_name, p.last_name)), ''),
             nullif(btrim(p.username), ''),
             ''), '[[:cntrl:]]', '', 'g')), 60)
      into v_shop_name
      from public.profiles p
      left join secondhand.member_profiles m on m.profile_id = p.id
     where p.id = v_uid;
    insert into public.shops (owner_id, organization_id, seller_identity_type, shop_name, shop_slug)
    values (v_uid, null, 'personal', coalesce(nullif(v_shop_name, ''), 'Member'),
            'member-' || replace(v_uid::text, '-', ''))
    returning * into v_shop;
  elsif v_shop.shop_status <> 'active' then
    raise exception 'Active personal seller shop is required';
  end if;

  insert into public.products (
    id, shop_id, category_id, title, slug, description, condition_level, price, stock,
    status, is_active, currency, handling_time_days
  ) values (
    v_product_id, v_shop.id, p_category_id, btrim(p_title), 'used-' || replace(v_product_id::text, '-', ''),
    btrim(p_description), p_condition_level, p_price, 1, 'active', true, v_settings.currency,
    case p_ship_within when '1_2' then 2 when '2_3' then 3 else 7 end
  );

  foreach v_path in array p_image_paths loop
    v_order := v_order + 1;
    insert into public.product_images (product_id, image_url, image_order, is_cover)
    values (v_product_id, v_path, v_order, v_order = 1);
  end loop;

  v_promo := v_settings.first_sale_promo_enabled
    and not exists (select 1 from secondhand.first_sale_promotions f where f.profile_id = v_uid);
  v_rate := case when v_promo then v_settings.first_sale_fee_rate else v_settings.sales_fee_rate end;
  v_fee := floor(p_price * v_rate);

  insert into secondhand.listings (
    product_id, seller_id, shipping_payer, shipping_option_code, package_max_weight_g, estimated_shipping_fee,
    ship_from_province, ship_within, currency, sales_fee_rate, first_sale_promo
  ) values (
    v_product_id, v_uid, 'seller', p_shipping_option, p_package_max_weight_g, v_shipping_fee,
    p_ship_from_province, p_ship_within, v_settings.currency, v_settings.sales_fee_rate, v_promo
  );

  -- Fee and net are what the seller would see if this sold now.
  return jsonb_build_object(
    'product_id', v_product_id,
    'shop_id', v_shop.id,
    'currency', v_settings.currency,
    'sales_fee_rate', v_rate,
    'sales_fee', v_fee,
    'net_amount', p_price - v_fee,
    'first_sale_promo', v_promo
  );
end $$;

-- ---------------------------------------------------------------------------
-- Close or reopen a listing (R20c) with the seller tiers; sold stays locked
-- ---------------------------------------------------------------------------
create or replace function secondhand.set_listing_open(p_product_id uuid, p_open boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_seller jsonb;
  v_product public.products;
  v_status text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  if p_open is null then
    raise exception 'Listing state is required';
  end if;

  select p.* into v_product
    from public.products p
    join public.shops s on s.id = p.shop_id
    join secondhand.listings l on l.product_id = p.id
   where p.id = p_product_id and s.owner_id = v_uid and l.seller_id = v_uid
   for update of p;
  if not found then
    raise exception 'Listing not found';
  end if;
  if exists (select 1 from public.orders o
              where o.product_id = p_product_id
                and o.order_status not in ('cancelled', 'completed', 'refunded')) then
    raise exception 'Listing has an order in progress';
  end if;

  if not p_open then
    if v_product.status <> 'active' then
      raise exception 'Listing is not on sale';
    end if;
    v_status := 'closed';
  else
    if v_product.status <> 'closed' then
      raise exception 'Listing is not closed';
    end if;
    v_seller := secondhand.seller_status_r20f(v_uid);
    if not (v_seller->>'can_list')::boolean then
      raise exception 'Seller verification is required before listing products';
    end if;
    if v_product.price > coalesce((v_seller->>'price_limit')::numeric, v_product.price) then
      raise exception 'Product price is above the unverified seller limit';
    end if;
    if not exists (select 1 from public.shops s where s.id = v_product.shop_id and s.shop_status = 'active') then
      raise exception 'Active personal seller shop is required';
    end if;
    if not exists (select 1 from public.categories c where c.id = v_product.category_id and c.is_active) then
      raise exception 'Active category is required';
    end if;
    if v_product.stock < 1 then
      raise exception 'Listing is out of stock';
    end if;
    v_status := 'active';
  end if;

  update public.products set status = v_status, updated_at = now() where id = p_product_id;
  return jsonb_build_object('product_id', p_product_id, 'status', v_status);
end $$;

-- ---------------------------------------------------------------------------
-- Edit a listing (R20c) with the seller tiers; on sale or closed only
-- ---------------------------------------------------------------------------
create or replace function secondhand.update_listing(
  p_product_id uuid,
  p_category_id uuid,
  p_title text,
  p_description text,
  p_condition_level smallint,
  p_price numeric,
  p_image_paths text[],
  p_shipping_option text,
  p_package_max_weight_g integer,
  p_ship_from_province smallint,
  p_ship_within text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_seller jsonb;
  v_settings secondhand.market_settings;
  v_product public.products;
  v_shipping_fee numeric(10,2);
  v_old text[];
  v_path text;
  v_order integer := 0;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  v_seller := secondhand.seller_status_r20f(v_uid);
  if not (v_seller->>'can_list')::boolean then
    raise exception 'Seller verification is required before listing products';
  end if;

  select p.* into v_product
    from public.products p
    join public.shops s on s.id = p.shop_id
    join secondhand.listings l on l.product_id = p.id
   where p.id = p_product_id and s.owner_id = v_uid and l.seller_id = v_uid
   for update of p;
  if not found then
    raise exception 'Listing not found';
  end if;
  if v_product.status not in ('active', 'closed') then
    raise exception 'Listing cannot be edited';
  end if;
  if not exists (select 1 from public.shops s where s.id = v_product.shop_id and s.shop_status = 'active') then
    raise exception 'Active personal seller shop is required';
  end if;
  if exists (select 1 from public.orders o
              where o.product_id = p_product_id
                and o.order_status not in ('cancelled', 'completed', 'refunded')) then
    raise exception 'Listing has an order in progress';
  end if;

  select * into strict v_settings from secondhand.market_settings where id;

  if not exists (select 1 from public.categories c where c.id = p_category_id and c.is_active) then
    raise exception 'Active category is required';
  end if;
  if p_title is null or char_length(btrim(p_title)) < 3 or char_length(p_title) > 100 then
    raise exception 'Product title must contain 3 to 100 characters';
  end if;
  if p_description is null or char_length(btrim(p_description)) < 10 or char_length(p_description) > 3000 then
    raise exception 'Product description must contain 10 to 3000 characters';
  end if;
  if p_condition_level is null or p_condition_level not between 1 and 6 then
    raise exception 'Product condition is invalid';
  end if;
  if p_price is null or p_price <> trunc(p_price) or p_price < v_settings.min_price or p_price > v_settings.max_price then
    raise exception 'Product price is invalid';
  end if;
  if p_price > coalesce((v_seller->>'price_limit')::numeric, v_settings.max_price) then
    raise exception 'Product price is above the unverified seller limit';
  end if;

  if p_image_paths is null or cardinality(p_image_paths) < 1 or cardinality(p_image_paths) > v_settings.max_photos then
    raise exception 'Product photo count is invalid';
  end if;
  if array_position(p_image_paths, null) is not null
     or cardinality(p_image_paths) <> (select count(distinct x) from unnest(p_image_paths) x) then
    raise exception 'Product photo paths must be unique and non-null';
  end if;
  foreach v_path in array p_image_paths loop
    if v_path !~ ('^' || v_uid::text || '/[A-Za-z0-9_-]+/(1?[0-9])\.(jpg|png|webp)$') then
      raise exception 'Invalid product photo path';
    end if;
    if not exists (
      select 1 from storage.objects o where o.bucket_id = 'marketplace-product-images' and o.name = v_path
    ) then
      raise exception 'Product photo upload was not found';
    end if;
  end loop;

  select r.fee into v_shipping_fee
    from secondhand.shipping_rates r
    join secondhand.shipping_options o on o.code = r.option_code and o.is_active
    join secondhand.shipping_partners p on p.code = o.partner_code and p.is_active
   where r.option_code = p_shipping_option and r.zone = 'upcountry' and r.max_weight_g = p_package_max_weight_g;
  if v_shipping_fee is null then
    raise exception 'Shipping option is invalid';
  end if;
  if not exists (select 1 from secondhand.thai_provinces t where t.code = p_ship_from_province) then
    raise exception 'Ship-from province is invalid';
  end if;
  if p_ship_within is null or p_ship_within not in ('1_2', '2_3', '4_7') then
    raise exception 'Shipping time is invalid';
  end if;

  v_old := array(select i.image_url from public.product_images i where i.product_id = p_product_id order by i.image_order);

  update public.products
     set category_id = p_category_id,
         title = btrim(p_title),
         description = btrim(p_description),
         condition_level = p_condition_level,
         price = p_price,
         handling_time_days = case p_ship_within when '1_2' then 2 when '2_3' then 3 else 7 end,
         updated_at = now()
   where id = p_product_id;

  delete from public.product_images where product_id = p_product_id;
  foreach v_path in array p_image_paths loop
    v_order := v_order + 1;
    insert into public.product_images (product_id, image_url, image_order, is_cover)
    values (p_product_id, v_path, v_order, v_order = 1);
  end loop;

  update secondhand.listings
     set shipping_option_code = p_shipping_option,
         package_max_weight_g = p_package_max_weight_g,
         estimated_shipping_fee = v_shipping_fee,
         ship_from_province = p_ship_from_province,
         ship_within = p_ship_within
   where product_id = p_product_id;

  return jsonb_build_object(
    'product_id', p_product_id,
    'removed_paths', to_jsonb(array(select x from unnest(v_old) x where x <> all (p_image_paths)))
  );
end $$;

-- ---------------------------------------------------------------------------
-- Reviews: good / bad with preset comments
-- ---------------------------------------------------------------------------
create table secondhand.review_presets (
  code text primary key check (code ~ '^[a-z][a-z0-9_]{1,47}$'),
  -- The reviewer's side: 'buyer' presets describe the seller and vice versa.
  reviewer_role text not null check (reviewer_role in ('buyer', 'seller')),
  verdict text not null check (verdict in ('good', 'bad')),
  label_th text not null check (char_length(btrim(label_th)) between 1 and 120),
  sort_order smallint not null default 0,
  is_active boolean not null default true
);

insert into secondhand.review_presets (code, reviewer_role, verdict, label_th, sort_order) values
  ('buyer_good_as_described', 'buyer', 'good', 'สินค้าตรงตามรายละเอียด', 10),
  ('buyer_good_fast_shipping', 'buyer', 'good', 'จัดส่งรวดเร็ว', 20),
  ('buyer_good_well_packed', 'buyer', 'good', 'แพ็กสินค้ามาอย่างดี', 30),
  ('buyer_good_friendly', 'buyer', 'good', 'ติดต่อง่าย สุภาพ', 40),
  ('buyer_bad_not_as_described', 'buyer', 'bad', 'สินค้าไม่ตรงตามรายละเอียด', 50),
  ('buyer_bad_slow_shipping', 'buyer', 'bad', 'จัดส่งล่าช้า', 60),
  ('buyer_bad_poor_packing', 'buyer', 'bad', 'แพ็กสินค้าไม่เรียบร้อย', 70),
  ('buyer_bad_unresponsive', 'buyer', 'bad', 'ติดต่อยาก ตอบช้า', 80),
  ('seller_good_fast_payment', 'seller', 'good', 'ชำระเงินรวดเร็ว', 10),
  ('seller_good_quick_receipt', 'seller', 'good', 'ยืนยันรับสินค้ารวดเร็ว', 20),
  ('seller_good_smooth_deal', 'seller', 'good', 'ซื้อขายราบรื่น', 30),
  ('seller_good_friendly', 'seller', 'good', 'ติดต่อง่าย สุภาพ', 40),
  ('seller_bad_late_receipt', 'seller', 'bad', 'ยืนยันรับสินค้าช้า', 50),
  ('seller_bad_unresponsive', 'seller', 'bad', 'ติดต่อยาก ตอบช้า', 60),
  ('seller_bad_rude', 'seller', 'bad', 'สื่อสารไม่สุภาพ', 70);

alter table secondhand.review_presets enable row level security;
revoke all on table secondhand.review_presets from public, anon, authenticated;
grant select on table secondhand.review_presets to anon, authenticated;
grant all on table secondhand.review_presets to service_role;
create policy review_presets_active_read on secondhand.review_presets for select to anon, authenticated
  using (is_active);

drop view secondhand.member_ratings;
drop function secondhand.submit_review(uuid, integer, text);
alter table secondhand.reviews drop column rating;
alter table secondhand.reviews
  add column verdict text not null check (verdict in ('good', 'bad')),
  add column preset_code text references secondhand.review_presets(code);

-- Stars are the share of good reviews out of five, e.g. 9 good and 1 bad = 4.5.
create view secondhand.member_ratings with (security_invoker = true) as
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
             / nullif(count(*) filter (where reviewer_role = 'seller'), 0), 1) as buyer_rating
  from secondhand.reviews
 where is_visible
 group by reviewee_id;

revoke all on secondhand.member_ratings from public, anon, authenticated;
grant select on secondhand.member_ratings to anon, authenticated;

-- One review per side of a completed order; editable for 30 days.
create or replace function secondhand.submit_review(
  p_order_id uuid,
  p_verdict text,
  p_preset_code text default null,
  p_comment text default null
)
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
  v_role := case when u = o.buyer_id then 'buyer' else 'seller' end;
  if p_verdict is null or p_verdict not in ('good', 'bad') or char_length(coalesce(v_comment, '')) > 1000 then
    raise exception 'invalid_review' using errcode = '22023';
  end if;
  if p_preset_code is not null and not exists (
    select 1 from secondhand.review_presets r
     where r.code = p_preset_code and r.is_active and r.reviewer_role = v_role and r.verdict = p_verdict
  ) then
    raise exception 'invalid_review' using errcode = '22023';
  end if;
  select * into v_existing from secondhand.reviews where order_id = p_order_id and reviewer_id = u;
  if found and v_existing.created_at < now() - interval '30 days' then
    raise exception 'review_locked' using errcode = '22023';
  end if;
  insert into secondhand.reviews(order_id, reviewer_id, reviewee_id, reviewer_role, verdict, preset_code, comment)
  values (p_order_id, u, case when v_role = 'buyer' then o.seller_id else o.buyer_id end, v_role,
          p_verdict, p_preset_code, v_comment)
  on conflict (order_id, reviewer_id) do update set verdict = excluded.verdict, preset_code = excluded.preset_code,
    comment = excluded.comment, updated_at = now()
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'created', v_existing.id is null, 'reviewer_role', v_role);
end $$;

revoke all on function secondhand.submit_review(uuid, text, text, text) from public, anon, authenticated;
grant execute on function secondhand.submit_review(uuid, text, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Seller card (R20d) with good / bad counts and the identity badge
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
    'good_count', coalesce(r.seller_good_count, 0),
    'bad_count', coalesce(r.seller_bad_count, 0),
    'is_verified', s.seller_identity_type = 'personal' and exists (
      select 1 from public.kao_id_identities k
       where k.profile_id = s.owner_id and k.organization_id is null
         and k.identity_type = 'personal' and k.status = 'active'),
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

-- ---------------------------------------------------------------------------
-- Sold listings stay public; closed ones stay with the seller
-- ---------------------------------------------------------------------------
create or replace function secondhand.listing_visible_r20f(p_product_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select secondhand.listing_public_r20d(p_product_id) or exists (
    select 1
      from public.products p
      join public.shops s on s.id = p.shop_id and s.shop_status = 'active'
     where p.id = p_product_id and p.status = 'sold' and p.is_active
  )
$$;

revoke all on function secondhand.listing_visible_r20f(uuid) from public, anon, authenticated;

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
  if v_owner is null or not (v_is_owner or secondhand.listing_visible_r20f(p_product_id)) then
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

-- A shop's public listings: on sale first, then sold, newest change first.
create or replace function secondhand.list_shop_listings(p_shop_id uuid, p_limit integer default 60)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(x.item order by x.sold, x.updated_at desc), '[]'::jsonb)
  from (
    select p.status = 'sold' as sold, p.updated_at, jsonb_build_object(
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
                                   from public.product_images i where i.product_id = p.id), '[]'::jsonb)
      ) as item
      from public.products p
      join public.shops s on s.id = p.shop_id and s.shop_status = 'active'
      left join public.categories c on c.id = p.category_id
     where p.shop_id = p_shop_id
       and p.is_active
       and ((p.status = 'active' and p.stock > 0 and c.is_active) or p.status = 'sold')
     order by p.status = 'sold', p.updated_at desc
     limit least(greatest(coalesce(p_limit, 60), 1), 120)
  ) x
$$;

-- ---------------------------------------------------------------------------
-- View count: once per viewer per listing per Thai day, never the owner
-- ---------------------------------------------------------------------------
create table secondhand.listing_views (
  product_id uuid not null references public.products(id) on delete cascade,
  view_date date not null,
  -- 'm:<profile id>' for members, 'g:<md5 of client IP and user agent>' for guests.
  viewer_key text not null check (viewer_key ~ '^(m|g):[0-9a-f-]{32,36}$'),
  created_at timestamptz not null default now(),
  primary key (product_id, view_date, viewer_key)
);

create index listing_views_date_r20f on secondhand.listing_views (view_date);

alter table secondhand.listing_views enable row level security;
revoke all on secondhand.listing_views from public, anon, authenticated;

create or replace function secondhand.record_listing_view(p_product_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_today date := (now() at time zone 'Asia/Bangkok')::date;
  v_headers jsonb;
  v_ip text;
  v_key text;
  v_count integer;
begin
  if p_product_id is null or not secondhand.listing_visible_r20f(p_product_id) then
    return jsonb_build_object('counted', false);
  end if;

  if v_uid is not null and not coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    if secondhand.listing_owner_r20d(p_product_id) = v_uid then
      return jsonb_build_object('counted', false);
    end if;
    v_key := 'm:' || v_uid::text;
  else
    begin
      v_headers := nullif(current_setting('request.headers', true), '')::jsonb;
    exception when others then
      v_headers := null;
    end;
    -- Cloudflare sets cf-connecting-ip itself, so a client cannot pick it.
    v_ip := nullif(btrim(coalesce(v_headers->>'cf-connecting-ip',
                                  split_part(v_headers->>'x-forwarded-for', ',', 1),
                                  v_headers->>'x-real-ip')), '');
    if v_ip is null then
      return jsonb_build_object('counted', false);
    end if;
    v_key := 'g:' || md5(v_ip || '|' || coalesce(v_headers->>'user-agent', ''));
  end if;

  insert into secondhand.listing_views (product_id, view_date, viewer_key)
  values (p_product_id, v_today, v_key)
  on conflict do nothing;
  if not found then
    return jsonb_build_object('counted', false);
  end if;

  update public.products set view_count = view_count + 1 where id = p_product_id
  returning view_count into v_count;
  -- Only today's keys matter; older rows are trimmed now and then.
  if random() < 0.01 then
    delete from secondhand.listing_views where view_date < v_today - 1;
  end if;
  return jsonb_build_object('counted', true, 'view_count', v_count);
end $$;

-- ---------------------------------------------------------------------------
-- Questions: shown on sold listings too, answered once, never removed by users
-- ---------------------------------------------------------------------------
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
    and (secondhand.listing_visible_r20f(p_product_id)
         or (auth.uid() is not null and secondhand.listing_owner_r20d(p_product_id) = auth.uid()))
$$;

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
  if v_question.answer is not null then
    raise exception 'Question already answered';
  end if;
  if char_length(v_text) not between 1 and 1000 then
    raise exception 'Answer must contain 1 to 1000 characters';
  end if;

  update secondhand.listing_questions
     set answer = v_text, answered_at = now(), updated_at = now()
   where id = p_question_id;

  insert into public.notifications (profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (v_question.asker_id, 'ผู้ขายตอบคำถามของคุณแล้ว', left(v_text, 160),
          'listing_answer', v_question.product_id, '/items/' || v_question.product_id,
          'listing_answer:' || p_question_id);
  return jsonb_build_object('id', p_question_id);
end $$;

-- Hiding a question is left to moderators (Admin Hub).
drop function secondhand.delete_listing_question(uuid);

-- ---------------------------------------------------------------------------
-- Grants and Secondhand token scope
-- ---------------------------------------------------------------------------
revoke all on function secondhand.get_seller_status() from public, anon;
grant execute on function secondhand.get_seller_status() to authenticated;
revoke all on function secondhand.list_shop_listings(uuid, integer) from public;
grant execute on function secondhand.list_shop_listings(uuid, integer) to anon, authenticated;
revoke all on function secondhand.record_listing_view(uuid) from public;
grant execute on function secondhand.record_listing_view(uuid) to anon, authenticated;

update kaoid_private.app_clients_r18
   set allowed_tables = array(select distinct t from unnest(allowed_tables || array[
         'secondhand.review_presets']) t order by 1),
       allowed_rpcs = array(select distinct r from unnest(array_remove(allowed_rpcs, 'secondhand.delete_listing_question')
         || array['secondhand.get_seller_status', 'secondhand.list_shop_listings', 'secondhand.record_listing_view']) r
         order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
