-- R20b: listing drafts, first-sale promotion settled on the first completed
-- sale, and the personal shop named after the member's profile.

-- ---------------------------------------------------------------------------
-- Listing drafts
-- ---------------------------------------------------------------------------
create table secondhand.listing_drafts (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  title text check (title is null or char_length(title) <= 100),
  description text check (description is null or char_length(description) <= 3000),
  category_id uuid references public.categories(id) on delete set null,
  condition_level smallint check (condition_level is null or condition_level between 1 and 6),
  price numeric(12,2) check (price is null or (price >= 0 and price = trunc(price))),
  shipping_option_code text references secondhand.shipping_options(code) on delete set null,
  package_max_weight_g integer check (package_max_weight_g is null or package_max_weight_g > 0),
  ship_from_province smallint references secondhand.thai_provinces(code),
  ship_within text not null default '1_2' check (ship_within in ('1_2', '2_3', '4_7')),
  image_paths text[] not null default '{}'
    check (cardinality(image_paths) <= 20 and array_position(image_paths, null) is null),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index listing_drafts_seller on secondhand.listing_drafts(seller_id, updated_at desc);

alter table secondhand.listing_drafts enable row level security;
create policy listing_drafts_own_read on secondhand.listing_drafts for select to authenticated
  using (seller_id = (select auth.uid()));
revoke all on table secondhand.listing_drafts from public, anon, authenticated;
grant select on table secondhand.listing_drafts to authenticated;
grant all on table secondhand.listing_drafts to service_role;

-- Inserts (p_id null) or updates one of the caller's drafts. Returns the saved
-- row plus the photo paths it no longer references, for the client to remove
-- from storage.
create or replace function secondhand.save_listing_draft(
  p_id uuid,
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
  v_paths text[] := coalesce(p_image_paths, '{}');
  v_old text[] := '{}';
  v_path text;
  v_row secondhand.listing_drafts;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.kao_id_identities k
     where k.profile_id = v_uid and k.organization_id is null
       and k.identity_type = 'personal' and k.status = 'active'
  ) then
    raise exception 'Active Personal Kao ID is required before listing products';
  end if;
  if not public.is_identity_financially_verified('personal', v_uid, null) then
    raise exception 'Personal identity and verified bank account are required before listing products';
  end if;

  if nullif(btrim(coalesce(p_title, '')), '') is null and nullif(btrim(coalesce(p_description, '')), '') is null
     and p_category_id is null and p_condition_level is null and p_price is null
     and cardinality(v_paths) = 0 and p_shipping_option is null and p_ship_from_province is null then
    raise exception 'Draft is empty';
  end if;
  if char_length(coalesce(p_title, '')) > 100 then
    raise exception 'Product title must contain 3 to 100 characters';
  end if;
  if char_length(coalesce(p_description, '')) > 3000 then
    raise exception 'Product description must contain 10 to 3000 characters';
  end if;
  if p_category_id is not null and not exists (select 1 from public.categories c where c.id = p_category_id and c.is_active) then
    raise exception 'Active category is required';
  end if;
  if p_condition_level is not null and p_condition_level not between 1 and 6 then
    raise exception 'Product condition is invalid';
  end if;
  if p_price is not null and (p_price <> trunc(p_price) or p_price < 0 or p_price > 99999999) then
    raise exception 'Product price is invalid';
  end if;

  if cardinality(v_paths) > (select s.max_photos from secondhand.market_settings s where s.id) then
    raise exception 'Product photo count is invalid';
  end if;
  if array_position(v_paths, null) is not null
     or cardinality(v_paths) <> (select count(distinct x) from unnest(v_paths) x) then
    raise exception 'Product photo paths must be unique and non-null';
  end if;
  foreach v_path in array v_paths loop
    if v_path !~ ('^' || v_uid::text || '/[A-Za-z0-9_-]+/(1?[0-9])\.(jpg|png|webp)$') then
      raise exception 'Invalid product photo path';
    end if;
    if not exists (
      select 1 from storage.objects o where o.bucket_id = 'marketplace-product-images' and o.name = v_path
    ) then
      raise exception 'Product photo upload was not found';
    end if;
  end loop;

  if p_shipping_option is not null and not exists (
    select 1 from secondhand.shipping_options o where o.code = p_shipping_option and o.is_active
  ) then
    raise exception 'Shipping option is invalid';
  end if;
  if p_package_max_weight_g is not null and not exists (
    select 1 from secondhand.shipping_rates r
     where r.option_code = p_shipping_option and r.max_weight_g = p_package_max_weight_g
  ) then
    raise exception 'Shipping option is invalid';
  end if;
  if p_ship_from_province is not null
     and not exists (select 1 from secondhand.thai_provinces t where t.code = p_ship_from_province) then
    raise exception 'Ship-from province is invalid';
  end if;
  if coalesce(p_ship_within, '1_2') not in ('1_2', '2_3', '4_7') then
    raise exception 'Shipping time is invalid';
  end if;

  if p_id is null then
    -- Serialise per seller so the draft cap holds under concurrent saves.
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('listing_drafts:' || v_uid::text, 0));
    if (select count(*) from secondhand.listing_drafts d where d.seller_id = v_uid) >= 50 then
      raise exception 'Draft limit reached';
    end if;
    insert into secondhand.listing_drafts (
      seller_id, title, description, category_id, condition_level, price, shipping_option_code,
      package_max_weight_g, ship_from_province, ship_within, image_paths
    ) values (
      v_uid, nullif(btrim(p_title), ''), nullif(btrim(p_description), ''), p_category_id, p_condition_level, p_price,
      p_shipping_option, p_package_max_weight_g, p_ship_from_province, coalesce(p_ship_within, '1_2'), v_paths
    )
    returning * into v_row;
  else
    select d.image_paths into v_old from secondhand.listing_drafts d
     where d.id = p_id and d.seller_id = v_uid
     for update;
    if not found then
      raise exception 'Draft not found';
    end if;
    update secondhand.listing_drafts d
       set title = nullif(btrim(p_title), ''),
           description = nullif(btrim(p_description), ''),
           category_id = p_category_id,
           condition_level = p_condition_level,
           price = p_price,
           shipping_option_code = p_shipping_option,
           package_max_weight_g = p_package_max_weight_g,
           ship_from_province = p_ship_from_province,
           ship_within = coalesce(p_ship_within, '1_2'),
           image_paths = v_paths,
           updated_at = now()
     where d.id = p_id
    returning * into v_row;
  end if;

  return jsonb_build_object(
    'draft', to_jsonb(v_row),
    'removed_paths', to_jsonb(array(select x from unnest(v_old) x where x <> all (v_paths)))
  );
end $$;

-- Deletes one of the caller's drafts and returns its photo paths.
create or replace function secondhand.delete_listing_draft(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_paths text[];
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  delete from secondhand.listing_drafts d
   where d.id = p_id and d.seller_id = v_uid
  returning d.image_paths into v_paths;
  if not found then
    raise exception 'Draft not found';
  end if;
  return jsonb_build_object('removed_paths', to_jsonb(v_paths));
end $$;

revoke all on function secondhand.save_listing_draft(uuid, uuid, text, text, smallint, numeric, text[], text, integer, smallint, text)
  from public, anon, authenticated;
grant execute on function secondhand.save_listing_draft(uuid, uuid, text, text, smallint, numeric, text[], text, integer, smallint, text)
  to authenticated;
revoke all on function secondhand.delete_listing_draft(uuid) from public, anon, authenticated;
grant execute on function secondhand.delete_listing_draft(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- First-sale promotion: claimed by the seller's first completed order
-- ---------------------------------------------------------------------------
alter table secondhand.first_sale_promotions
  add column order_id uuid references public.orders(id) on delete set null;

comment on column secondhand.listings.sales_fee_rate is
  'Standard commission rate when listed. The first completed sale per seller is charged first_sale_fee_rate instead.';
comment on column secondhand.listings.first_sale_promo is
  'The seller had not yet completed a first sale when this was listed.';

-- Sets the commission when an order completes. Until a seller's first sale
-- completes, every listing of theirs remains eligible for the promotion.
create or replace function secondhand.settle_order_commission_r20b()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_listing secondhand.listings;
  v_settings secondhand.market_settings;
  v_promo boolean := false;
begin
  if new.completed_at is null and new.order_status is distinct from 'completed' then
    return new;
  end if;
  if tg_op = 'UPDATE' and (old.completed_at is not null or old.order_status = 'completed') then
    return new;
  end if;

  select * into v_listing from secondhand.listings l where l.product_id = new.product_id;
  if not found then
    return new;
  end if;
  select * into strict v_settings from secondhand.market_settings s where s.id;

  if v_settings.first_sale_promo_enabled then
    insert into secondhand.first_sale_promotions (profile_id, product_id, order_id)
    values (v_listing.seller_id, new.product_id, new.id)
    on conflict (profile_id) do nothing;
    v_promo := found;
  end if;

  new.marketplace_fee := floor(new.product_price *
    case when v_promo then v_settings.first_sale_fee_rate else v_listing.sales_fee_rate end);
  return new;
end $$;

revoke all on function secondhand.settle_order_commission_r20b() from public, anon, authenticated;

create trigger orders_settle_commission_r20b
  before insert or update of order_status, completed_at on public.orders
  for each row execute function secondhand.settle_order_commission_r20b();

-- ---------------------------------------------------------------------------
-- Create a listing: shop named after the profile, promotion not claimed yet
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

  if not exists (
    select 1 from public.kao_id_identities k
     where k.profile_id = v_uid and k.organization_id is null
       and k.identity_type = 'personal' and k.status = 'active'
  ) then
    raise exception 'Active Personal Kao ID is required before listing products';
  end if;
  if not public.is_identity_financially_verified('personal', v_uid, null) then
    raise exception 'Personal identity and verified bank account are required before listing products';
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
-- Keep the personal shop name in step with the member's profile name
-- ---------------------------------------------------------------------------
create or replace function secondhand.sync_shop_name_r20b()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.shops s
     set shop_name = new.display_name, updated_at = now()
   where s.owner_id = new.profile_id and s.seller_identity_type = 'personal'
     and s.shop_name is distinct from new.display_name;
  return new;
end $$;

revoke all on function secondhand.sync_shop_name_r20b() from public, anon, authenticated;

create trigger member_profiles_sync_shop_name_r20b
  after update of display_name on secondhand.member_profiles
  for each row when (new.display_name is distinct from old.display_name)
  execute function secondhand.sync_shop_name_r20b();

-- ---------------------------------------------------------------------------
-- Secondhand token scope
-- ---------------------------------------------------------------------------
update kaoid_private.app_clients_r18
   set allowed_tables = array(select distinct t from unnest(allowed_tables || array[
         'secondhand.listing_drafts']) t order by 1),
       allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
         'secondhand.save_listing_draft', 'secondhand.delete_listing_draft']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
