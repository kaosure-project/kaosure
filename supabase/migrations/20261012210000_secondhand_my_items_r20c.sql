-- R20c: "สินค้าของฉัน" - the seller's own listings, closing / reopening a
-- listing and editing it. Product status: 'active' on sale, 'closed' closed by
-- the seller, 'sold' set by checkout (Phase 4).

-- ---------------------------------------------------------------------------
-- The seller's listings, newest first
-- ---------------------------------------------------------------------------
create or replace function secondhand.my_listings()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'product_id', p.id,
      'title', p.title,
      'description', p.description,
      'category_id', p.category_id,
      'category_name', c.name,
      'category_active', coalesce(c.is_active, false),
      'condition_level', p.condition_level,
      'price', p.price,
      'status', p.status,
      'is_active', p.is_active,
      'stock', p.stock,
      'favorite_count', p.favorite_count,
      'view_count', p.view_count,
      'created_at', p.created_at,
      'updated_at', p.updated_at,
      'image_paths', coalesce((select jsonb_agg(i.image_url order by i.image_order)
                                 from public.product_images i where i.product_id = p.id), '[]'::jsonb),
      'shipping_option_code', l.shipping_option_code,
      'package_max_weight_g', l.package_max_weight_g,
      'ship_from_province', l.ship_from_province,
      'ship_within', l.ship_within,
      'open_order', exists (select 1 from public.orders o
                             where o.product_id = p.id
                               and o.order_status not in ('cancelled', 'completed', 'refunded'))
    ) order by p.created_at desc), '[]'::jsonb)
  from public.products p
  join public.shops s on s.id = p.shop_id
  join secondhand.listings l on l.product_id = p.id
  left join public.categories c on c.id = p.category_id
  where auth.uid() is not null
    and kaoid_private.account_active_r9f()
    and s.owner_id = auth.uid()
    and s.seller_identity_type = 'personal'
    and l.seller_id = auth.uid()
$$;

-- ---------------------------------------------------------------------------
-- Close or reopen a listing
-- ---------------------------------------------------------------------------
create or replace function secondhand.set_listing_open(p_product_id uuid, p_open boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
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
-- Edit a listing (on sale or closed, with no order in progress)
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

revoke all on function secondhand.my_listings() from public, anon, authenticated;
grant execute on function secondhand.my_listings() to authenticated;
revoke all on function secondhand.set_listing_open(uuid, boolean) from public, anon, authenticated;
grant execute on function secondhand.set_listing_open(uuid, boolean) to authenticated;
revoke all on function secondhand.update_listing(uuid, uuid, text, text, smallint, numeric, text[], text, integer, smallint, text)
  from public, anon, authenticated;
grant execute on function secondhand.update_listing(uuid, uuid, text, text, smallint, numeric, text[], text, integer, smallint, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Secondhand token scope: the shop is opened by create_listing now
-- ---------------------------------------------------------------------------
update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(array_remove(allowed_rpcs, 'public.create_personal_shop') || array[
         'secondhand.my_listings', 'secondhand.set_listing_open', 'secondhand.update_listing']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
