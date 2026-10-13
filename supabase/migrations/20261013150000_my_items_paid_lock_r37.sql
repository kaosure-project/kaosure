-- R37: "สินค้าของฉัน" and the listing lock.
--
-- Secondhand never reserves an item (R22b): whoever pays first gets it. So an unpaid order no longer locks the
-- listing; only a paid or shipped one does. The seller may edit, close or reopen while orders are unpaid; a price
-- change or closing cancels those unpaid orders through products_unpaid_orders_r22b, as before.
--
-- my_listings also returns the listing's latest paid order (id and status) so the seller can open it.

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
    join secondhand.listings l on l.product_id = p.id
   where p.id = p_product_id
   for update of p;
  if not found or not secondhand.shop_can_r27(v_product.shop_id, 'products', v_uid) then
    raise exception 'Listing not found';
  end if;
  if exists (select 1 from public.orders o
              where o.product_id = p_product_id
                and o.order_status in ('paid', 'shipped')) then
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
    if not (secondhand.shop_sell_status_r27(v_product.shop_id)->>'can_list')::boolean then
      if not exists (select 1 from public.shops s where s.id = v_product.shop_id and s.shop_status = 'active') then
        raise exception 'Active personal seller shop is required';
      end if;
      raise exception 'Seller verification is required before listing products';
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

  select p.* into v_product
    from public.products p
    join secondhand.listings l on l.product_id = p.id
   where p.id = p_product_id
   for update of p;
  if not found or not secondhand.shop_can_r27(v_product.shop_id, 'products', v_uid) then
    raise exception 'Listing not found';
  end if;
  if not (secondhand.shop_sell_status_r27(v_product.shop_id)->>'can_list')::boolean then
    if not exists (select 1 from public.shops s where s.id = v_product.shop_id and s.shop_status = 'active') then
      raise exception 'Active personal seller shop is required';
    end if;
    raise exception 'Seller verification is required before listing products';
  end if;
  if v_product.status not in ('active', 'closed') then
    raise exception 'Listing cannot be edited';
  end if;
  if exists (select 1 from public.orders o
              where o.product_id = p_product_id
                and o.order_status in ('paid', 'shipped')) then
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

  v_old := array(select i.image_url from public.product_images i where i.product_id = p_product_id order by i.image_order);
  if p_image_paths is null or cardinality(p_image_paths) < 1 or cardinality(p_image_paths) > v_settings.max_photos then
    raise exception 'Product photo count is invalid';
  end if;
  if array_position(p_image_paths, null) is not null
     or cardinality(p_image_paths) <> (select count(distinct x) from unnest(p_image_paths) x) then
    raise exception 'Product photo paths must be unique and non-null';
  end if;
  -- Photos already on the listing may have been uploaded by another team member.
  foreach v_path in array p_image_paths loop
    if v_path <> all (v_old) and v_path !~ ('^' || v_uid::text || '/[A-Za-z0-9_-]+/(1?[0-9])\.(jpg|png|webp)$') then
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
  v_is_owner := v_uid is not null and kaoid_private.account_active_r9f()
    and secondhand.shop_can_r27((select p.shop_id from public.products p where p.id = p_product_id), 'products', v_uid);
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
                                               and o.order_status in ('paid', 'shipped')),
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

create or replace function secondhand.my_listings(p_shop_id uuid default null)
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
                               and o.order_status in ('paid', 'shipped')),
      'order', (select jsonb_build_object('id', o.id, 'status', o.order_status)
                  from public.orders o
                 where o.product_id = p.id
                   and o.order_status in ('paid', 'shipped', 'completed')
                 order by o.created_at desc
                 limit 1)
    ) order by p.created_at desc), '[]'::jsonb)
  from public.products p
  join public.shops s on s.id = p.shop_id
  join secondhand.listings l on l.product_id = p.id
  left join public.categories c on c.id = p.category_id
  where auth.uid() is not null
    and kaoid_private.account_active_r9f()
    and case when p_shop_id is null
             then s.owner_id = auth.uid() and s.seller_identity_type = 'personal' and l.seller_id = auth.uid()
             else s.id = p_shop_id and secondhand.shop_can_r27(p_shop_id, 'products') end
$$;
