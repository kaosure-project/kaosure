-- R27b (2/3): seller-side RPCs act for a shop. A personal shop is run by its owner only; a business shop by the
-- organization's admins and the shop staff holding the matching permission (secondhand.shop_can_r27).
-- Listings and orders of a business shop keep seller_id = the shop owner's profile; money settles into the wallet
-- recorded on the order's escrow (the organization's wallet for a business shop).

-- Listings ---------------------------------------------------------------------------------------------------------

drop function secondhand.create_listing(uuid, text, text, smallint, numeric, text[], text, text, integer, smallint, text);
create function secondhand.create_listing(p_category_id uuid, p_title text, p_description text,
                                          p_condition_level smallint, p_price numeric, p_image_paths text[],
                                          p_shipping_payer text, p_shipping_option text,
                                          p_package_max_weight_g integer, p_ship_from_province smallint,
                                          p_ship_within text, p_shop_id uuid default null)
returns jsonb
language plpgsql
security definer
set search_path to ''
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

  if p_shop_id is null then
    v_seller := secondhand.seller_status_r20f(v_uid);
    if not (v_seller->>'can_list')::boolean then
      raise exception 'Seller verification is required before listing products';
    end if;
  else
    select * into v_shop from public.shops s where s.id = p_shop_id for update;
    if not found or not secondhand.shop_can_r27(p_shop_id, 'products', v_uid) then
      raise exception 'Shop not found';
    end if;
    if not (secondhand.shop_sell_status_r27(p_shop_id)->>'can_list')::boolean then
      raise exception 'Seller verification is required before listing products';
    end if;
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

  if p_shop_id is null then
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

  -- The first-sale discount is for individual sellers.
  v_promo := v_shop.seller_identity_type = 'personal' and v_settings.first_sale_promo_enabled
    and not exists (select 1 from secondhand.first_sale_promotions f where f.profile_id = v_shop.owner_id);
  v_rate := case when v_promo then v_settings.first_sale_fee_rate else v_settings.sales_fee_rate end;
  v_fee := floor(p_price * v_rate);

  insert into secondhand.listings (
    product_id, seller_id, shipping_payer, shipping_option_code, package_max_weight_g, estimated_shipping_fee,
    ship_from_province, ship_within, currency, sales_fee_rate, first_sale_promo
  ) values (
    v_product_id, v_shop.owner_id, 'seller', p_shipping_option, p_package_max_weight_g, v_shipping_fee,
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

create or replace function secondhand.update_listing(p_product_id uuid, p_category_id uuid, p_title text,
                                                     p_description text, p_condition_level smallint,
                                                     p_price numeric, p_image_paths text[],
                                                     p_shipping_option text, p_package_max_weight_g integer,
                                                     p_ship_from_province smallint, p_ship_within text)
returns jsonb
language plpgsql
security definer
set search_path to ''
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

create or replace function secondhand.set_listing_open(p_product_id uuid, p_open boolean)
returns jsonb
language plpgsql
security definer
set search_path to ''
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

drop function secondhand.my_listings();
create function secondhand.my_listings(p_shop_id uuid default null)
returns jsonb
language sql
stable security definer
set search_path to ''
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
    and case when p_shop_id is null
             then s.owner_id = auth.uid() and s.seller_identity_type = 'personal' and l.seller_id = auth.uid()
             else s.id = p_shop_id and secondhand.shop_can_r27(p_shop_id, 'products') end
$$;

create or replace function secondhand.answer_listing_question(p_question_id uuid, p_answer text)
returns jsonb
language plpgsql
security definer
set search_path to ''
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
  if not found or v_question.is_hidden
     or not secondhand.shop_can_r27((select p.shop_id from public.products p where p.id = v_question.product_id),
                                    'chat', v_uid) then
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

create or replace function secondhand.list_listing_questions(p_product_id uuid)
returns jsonb
language sql
stable security definer
set search_path to ''
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
         or secondhand.shop_can_r27((select p.shop_id from public.products p where p.id = p_product_id), 'products')
         or secondhand.shop_can_r27((select p.shop_id from public.products p where p.id = p_product_id), 'chat'))
$$;

create or replace function secondhand.get_listing_detail(p_product_id uuid)
returns jsonb
language plpgsql
stable security definer
set search_path to ''
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

create or replace function secondhand.get_price_offer_state(p_product_id uuid)
returns jsonb
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  v_uid uuid := auth.uid();
  v_owner uuid;
  v_price numeric(12,2);
  v_offer secondhand.price_offers;
  v_status text;
  v_on_sale boolean;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  v_owner := secondhand.listing_owner_r20d(p_product_id);
  if v_owner is not null
     and secondhand.shop_can_r27((select p.shop_id from public.products p where p.id = p_product_id), 'products', v_uid) then
    return jsonb_build_object(
      'role', 'seller',
      'offers', coalesce((
        select jsonb_agg(secondhand.offer_json_r20g(o)
                 order by secondhand.offer_status_r20g(o) <> 'pending', o.created_at desc)
          from secondhand.price_offers o
         where o.product_id = p_product_id
           and secondhand.offer_status_r20g(o) in ('pending', 'accepted')), '[]'::jsonb));
  end if;
  if v_owner is null or not secondhand.listing_visible_r20f(p_product_id) then
    return null;
  end if;

  select p.price into v_price from public.products p where p.id = p_product_id;
  v_on_sale := secondhand.listing_public_r20d(p_product_id);
  select * into v_offer from secondhand.price_offers o
   where o.product_id = p_product_id and o.buyer_id = v_uid
   order by o.created_at desc limit 1;
  v_status := case when v_offer.id is null then null else secondhand.offer_status_r20g(v_offer) end;
  return jsonb_build_object(
    'role', 'buyer',
    'offer', case when v_offer.id is null then null else secondhand.offer_json_r20g(v_offer) end,
    'can_offer', v_on_sale and coalesce(v_status not in ('pending', 'accepted'), true),
    'buyer_ready', secondhand.buyer_ready_r20g(v_uid),
    'options', case when v_on_sale then secondhand.offer_options_r20g(v_price) else '[]'::jsonb end,
    'special_price', case when v_status = 'accepted' then least(v_offer.offer_price, v_price) end
  );
end $$;

create or replace function secondhand.respond_price_offer(p_offer_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_uid uuid := auth.uid();
  v_offer secondhand.price_offers;
  v_title text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  if p_accept is null then
    raise exception 'Choose accept or reject';
  end if;
  select * into v_offer from secondhand.price_offers o where o.id = p_offer_id for update;
  if not found or secondhand.listing_owner_r20d(v_offer.product_id) is distinct from v_offer.seller_id
     or not secondhand.shop_can_r27((select p.shop_id from public.products p where p.id = v_offer.product_id),
                                    'products', v_uid) then
    raise exception 'Offer not found';
  end if;
  if secondhand.offer_status_r20g(v_offer) = 'expired' then
    raise exception 'Offer has expired';
  end if;
  if v_offer.status <> 'pending' then
    raise exception 'Offer already answered';
  end if;
  if p_accept and (not secondhand.listing_public_r20d(v_offer.product_id)
      or (select p.price from public.products p where p.id = v_offer.product_id) <> v_offer.listed_price) then
    raise exception 'Listing changed since the offer';
  end if;

  update secondhand.price_offers
     set status = case when p_accept then 'accepted' else 'rejected' end,
         responded_at = now(),
         purchase_expires_at = case when p_accept then now() + interval '24 hours' end,
         updated_at = now()
   where id = p_offer_id
  returning * into v_offer;

  select p.title into v_title from public.products p where p.id = v_offer.product_id;
  insert into public.notifications (profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (v_offer.buyer_id,
          case when p_accept then 'ผู้ขายยอมรับข้อเสนอของคุณ' else 'ผู้ขายปฏิเสธข้อเสนอของคุณ' end,
          case when p_accept
               then left(v_title, 80) || ': ซื้อได้ในราคา ' || secondhand.offer_baht_r20g(v_offer.offer_price)
                    || ' ภายใน 24 ชั่วโมง'
               else left(v_title, 80) || ': คุณยื่นข้อเสนอใหม่ได้' end,
          case when p_accept then 'price_offer_accepted' else 'price_offer_rejected' end,
          v_offer.product_id, '/items/' || v_offer.product_id, 'price_offer_answer:' || v_offer.id);

  return secondhand.offer_json_r20g(v_offer);
end $$;

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
    'rating', r.rating,
    'review_count', coalesce(r.review_count, 0),
    'good_count', coalesce(r.good_count, 0),
    'bad_count', coalesce(r.bad_count, 0),
    'is_verified', case when s.seller_identity_type = 'personal'
                        then coalesce((secondhand.seller_status_r20f(s.owner_id)->>'verified')::boolean, false)
                        else coalesce((secondhand.shop_sell_status_r27(s.id)->>'can_list')::boolean, false) end,
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

-- Orders -----------------------------------------------------------------------------------------------------------

create or replace function secondhand.checkout_problem_r22(p_buyer uuid, p_product_id uuid)
returns text
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  v_seller uuid;
  v_shop uuid;
begin
  select l.seller_id, p.shop_id into v_seller, v_shop
    from public.products p
    join secondhand.listings l on l.product_id = p.id
   where p.id = p_product_id;
  if v_seller is null then
    return 'not_on_sale';
  end if;
  if v_seller = p_buyer or secondhand.shop_can_r27(v_shop, 'products', p_buyer)
     or secondhand.shop_can_r27(v_shop, 'orders', p_buyer) then
    return 'own_listing';
  end if;
  if not secondhand.buyer_ready_r20g(p_buyer) then
    return 'buyer_not_ready';
  end if;
  if secondhand.blocked_between_r21b(p_buyer, v_seller) then
    return 'member_blocked';
  end if;
  if not secondhand.listing_public_r20d(p_product_id)
     or exists (select 1 from public.orders o
                 where o.product_id = p_product_id
                   and o.order_status not in ('pending', 'cancelled', 'completed', 'refunded')) then
    return 'not_on_sale';
  end if;
  return null;
end $$;

create or replace function secondhand.can_cancel_order_r26(o public.orders, d secondhand.order_details, p_viewer uuid)
returns boolean
language sql
stable
set search_path to ''
as $$
  select case
    when p_viewer = o.buyer_id then o.order_status = 'pending'
                                    or (o.order_status = 'paid' and d.ship_by is not null and d.ship_by < now())
    when secondhand.shop_can_r27(o.shop_id, 'orders', p_viewer) then o.order_status in ('paid', 'shipped')
    else false end;
$$;

create or replace function secondhand.cancel_order(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_order public.orders;
  v_details secondhand.order_details;
  v_by text;
begin
  select * into v_order from public.orders o where o.id = p_order_id for update;
  if not found
     or (u <> v_order.buyer_id
         and (v_order.paid_at is null or not secondhand.shop_can_r27(v_order.shop_id, 'orders', u))) then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  select * into strict v_details from secondhand.order_details d where d.order_id = p_order_id;
  v_by := case when u = v_order.buyer_id then 'buyer' else 'seller' end;
  if not secondhand.can_cancel_order_r26(v_order, v_details, u) then
    raise exception 'order_not_cancellable' using errcode = '22023';
  end if;

  perform secondhand.cancel_order_r22(p_order_id, u, v_by,
                                      case when v_by = 'buyer' and v_order.order_status = 'paid' then 'ship_overdue' end);
  return jsonb_build_object('order_id', p_order_id, 'status', 'cancelled');
end $$;

-- The seller side of an order is anyone on the shop team who handles orders or chat.
create or replace function secondhand.order_json_r22(p_order_id uuid, p_viewer uuid)
returns jsonb
language sql
stable security definer
set search_path to ''
as $$
  select jsonb_build_object(
    'id', o.id,
    'order_number', o.order_number,
    'role', case when p_viewer = o.buyer_id then 'buyer' else 'seller' end,
    'status', o.order_status,
    'payment_method', d.payment_method,
    'price', o.product_price,
    'shipping_fee', o.shipping_fee,
    'total', o.total_amount,
    'marketplace_fee', case when p_viewer <> o.buyer_id then o.marketplace_fee end,
    'created_at', o.created_at,
    'paid_at', o.paid_at,
    'shipped_at', o.shipped_at,
    'completed_at', o.completed_at,
    'cancelled_at', o.cancelled_at,
    'cancelled_by', d.cancelled_by,
    'cancel_reason', o.cancel_reason,
    'pay_by', d.pay_by,
    'ship_by', d.ship_by,
    'receive_by', d.receive_by,
    'carrier', o.shipping_company,
    'tracking_number', o.tracking_number,
    'offer_applied', d.offer_id is not null,
    'shop_id', o.shop_id,
    'product', jsonb_build_object(
      'id', p.id, 'title', p.title,
      'image_path', (select i.image_url from public.product_images i where i.product_id = p.id
                      order by i.is_cover desc, i.image_order limit 1)),
    'counterpart', jsonb_build_object(
      'display_name', case when p_viewer = o.buyer_id and sh.seller_identity_type = 'business' then sh.shop_name
                           else secondhand.member_name_r22(case when p_viewer = o.buyer_id then o.seller_id
                                                                else o.buyer_id end) end,
      'avatar_url', case when p_viewer = o.buyer_id and sh.seller_identity_type = 'business' then null
                         else m.avatar_url end,
      'shop_id', case when p_viewer = o.buyer_id then o.shop_id
                      else (select s.id from public.shops s where s.owner_id = o.buyer_id
                              and s.seller_identity_type = 'personal' and s.shop_status = 'active'
                            order by s.created_at limit 1) end),
    'address', case when p_viewer = o.buyer_id or o.order_status in ('paid', 'shipped', 'completed') then d.address end,
    'reviewed', exists (select 1 from secondhand.reviews r
                         where r.order_id = o.id
                           and r.reviewer_id = case when p_viewer = o.buyer_id then o.buyer_id else o.seller_id end),
    'unread_messages', coalesce((select case when p_viewer = c.buyer_id then c.buyer_unread_count
                                             else c.seller_unread_count end
                                   from public.chat_rooms c where c.order_id = o.id), 0),
    'issue', (select secondhand.order_issue_json_r26(x) from secondhand.order_issues x
               where x.order_id = o.id order by x.created_at desc limit 1),
    'can_cancel', secondhand.can_cancel_order_r26(o, d, p_viewer),
    'can_open_issue', secondhand.can_open_order_issue_r26(o, p_viewer))
  from public.orders o
  join secondhand.order_details d on d.order_id = o.id
  join public.products p on p.id = o.product_id
  join public.shops sh on sh.id = o.shop_id
  left join secondhand.member_profiles m
    on m.profile_id = case when p_viewer = o.buyer_id then o.seller_id else o.buyer_id end
  where o.id = p_order_id
    and (p_viewer = o.buyer_id
         or (o.paid_at is not null
             and (secondhand.shop_can_r27(o.shop_id, 'orders', p_viewer)
                  or secondhand.shop_can_r27(o.shop_id, 'chat', p_viewer))))
$$;

drop function secondhand.list_my_orders(text, timestamptz, integer);
create function secondhand.list_my_orders(p_role text, p_before timestamptz default null, p_limit integer default 20,
                                          p_shop_id uuid default null)
returns jsonb
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_items jsonb;
  v_more boolean;
begin
  if p_role is null or p_role not in ('buyer', 'seller') then
    raise exception 'invalid_filter' using errcode = '22023';
  end if;
  if p_shop_id is not null and (p_role <> 'seller'
     or not (secondhand.shop_can_r27(p_shop_id, 'orders', u) or secondhand.shop_can_r27(p_shop_id, 'chat', u))) then
    raise exception 'shop_not_found' using errcode = '22023';
  end if;
  select coalesce(jsonb_agg(secondhand.order_json_r22(x.id, u) order by x.created_at desc, x.id desc), '[]'::jsonb)
    into v_items
    from (select o.id, o.created_at from public.orders o
           where case when p_role = 'buyer' then o.buyer_id = u
                      when p_shop_id is null then o.seller_id = u
                        and exists (select 1 from public.shops s
                                     where s.id = o.shop_id and s.seller_identity_type = 'personal')
                      else o.shop_id = p_shop_id end
             and (p_role = 'buyer' or o.paid_at is not null)
             and exists (select 1 from secondhand.order_details d where d.order_id = o.id)
             and (p_before is null or o.created_at < p_before)
           order by o.created_at desc, o.id desc
           limit v_limit + 1) x;
  v_more := jsonb_array_length(v_items) > v_limit;
  if v_more then
    v_items := v_items - v_limit;
  end if;
  return jsonb_build_object('orders', v_items, 'has_more', v_more);
end $$;

create or replace function secondhand.mark_shipped(p_order_id uuid, p_carrier text, p_tracking text default null)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_order public.orders;
  v_carrier text := nullif(btrim(coalesce(p_carrier, '')), '');
  v_tracking text := nullif(btrim(coalesce(p_tracking, '')), '');
  v_settings secondhand.market_settings;
begin
  select * into v_order from public.orders o where o.id = p_order_id for update;
  if not found or not secondhand.shop_can_r27(v_order.shop_id, 'orders', u) then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  if v_order.order_status <> 'paid' then
    raise exception 'order_not_shippable' using errcode = '22023';
  end if;
  if v_carrier is null or char_length(v_carrier) > 60 or char_length(coalesce(v_tracking, '')) > 60 then
    raise exception 'invalid_shipment' using errcode = '22023';
  end if;
  select * into strict v_settings from secondhand.market_settings s where s.id;

  update public.orders
     set order_status = 'shipped', shipped_at = now(), shipping_company = v_carrier, tracking_number = v_tracking,
         updated_at = now()
   where id = p_order_id;
  update secondhand.order_details
     set receive_by = now() + make_interval(days => v_settings.receive_window_days), updated_at = now()
   where order_id = p_order_id;

  perform secondhand.order_log_r22(p_order_id, u, 'paid', 'shipped', 'shipped',
                                   v_carrier || coalesce(' ' || v_tracking, ''));
  perform secondhand.order_notify_r22(v_order.buyer_id, p_order_id, 'shipped', 'ผู้ขายจัดส่งสินค้าแล้ว',
    'คำสั่งซื้อ ' || v_order.order_number || ': ได้รับของแล้วกรุณากดยืนยัน ระบบจะยืนยันให้อัตโนมัติใน '
      || v_settings.receive_window_days || ' วัน');
  return jsonb_build_object('order_id', p_order_id, 'status', 'shipped');
end $$;

create or replace function secondhand.submit_review(p_order_id uuid, p_verdict text, p_comment text default null,
                                                    p_preset text default null)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := auth.uid();
  o public.orders;
  v_review secondhand.reviews;
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if coalesce(kaoid_private.account_access_r10d()->>'state', '') <> 'active' then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  select * into o from public.orders where id = p_order_id;
  if not found or (u <> o.buyer_id and u <> o.seller_id and not secondhand.shop_can_r27(o.shop_id, 'orders', u)) then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  if o.completed_at is null and coalesce(o.order_status, '') <> 'completed' then
    raise exception 'order_not_completed' using errcode = '22023';
  end if;
  -- A team member reviews the buyer on behalf of the shop.
  v_review := secondhand.write_review_r25(case when u = o.buyer_id then u else o.seller_id end,
                                          p_order_id, p_verdict, p_comment, p_preset);
  return jsonb_build_object('id', v_review.id, 'reviewer_role', v_review.reviewer_role, 'verdict', v_review.verdict);
end $$;

-- Order chat -------------------------------------------------------------------------------------------------------

create or replace function secondhand.order_chat_room_for_r23(p_order_id uuid, p_viewer uuid)
returns public.chat_rooms
language sql
stable security definer
set search_path to ''
as $$
  select r.* from public.chat_rooms r
    join public.orders o on o.id = r.order_id
    join secondhand.order_details d on d.order_id = o.id
   where r.order_id = p_order_id
     and (p_viewer = r.buyer_id or secondhand.shop_can_r27(o.shop_id, 'chat', p_viewer))
$$;

create or replace function secondhand.get_order_chat(p_order_id uuid, p_before bigint default null,
                                                     p_limit integer default 30)
returns jsonb
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_room public.chat_rooms;
  v_status text;
  v_limit integer := least(greatest(coalesce(p_limit, 30), 1), 100);
  v_items jsonb;
  v_more boolean;
  v_other uuid;
  v_buyer boolean;
begin
  v_room := secondhand.order_chat_room_for_r23(p_order_id, u);
  if v_room.id is null then
    if exists (select 1 from public.orders o where o.id = p_order_id and o.buyer_id = u) then
      return jsonb_build_object('open', false, 'can_send', false, 'closed_reason', 'not_paid',
                                'messages', '[]'::jsonb, 'has_more', false, 'unread', 0);
    end if;
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  v_buyer := u = v_room.buyer_id;
  v_other := case when v_buyer then v_room.seller_id else v_room.buyer_id end;
  select o.order_status into v_status from public.orders o where o.id = p_order_id;

  select coalesce(jsonb_agg(jsonb_build_object(
           'id', m.id,
           'seq', m.sequence_number,
           'mine', case when v_buyer then m.sender_id = u else m.sender_id <> v_room.buyer_id end,
           'body', case when m.is_hidden or m.is_recalled then null else m.message end,
           'hidden', m.is_hidden or m.is_recalled,
           'read', m.is_read,
           'created_at', m.created_at) order by m.sequence_number desc), '[]'::jsonb)
    into v_items
    from (select * from public.chat_messages x
           where x.room_id = v_room.id and (p_before is null or x.sequence_number < p_before)
           order by x.sequence_number desc
           limit v_limit + 1) m;
  v_more := jsonb_array_length(v_items) > v_limit;
  if v_more then
    v_items := v_items - v_limit;
  end if;

  return jsonb_build_object(
    'open', v_room.room_status <> 'closed' and v_status in ('paid', 'shipped'),
    'can_send', v_room.room_status <> 'closed' and v_status in ('paid', 'shipped')
                and not secondhand.blocked_between_r21b(u, v_other),
    'closed_reason', case
      when v_room.room_status = 'closed' or v_status not in ('paid', 'shipped') then 'order_closed'
      when secondhand.blocked_between_r21b(u, v_other) then 'member_blocked' end,
    'unread', case when v_buyer then v_room.buyer_unread_count else v_room.seller_unread_count end,
    'messages', v_items,
    'has_more', v_more);
end $$;

create or replace function secondhand.mark_order_chat_read(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_room public.chat_rooms;
  v_buyer boolean;
  n integer;
begin
  select r.* into v_room from public.chat_rooms r
   where r.id = (secondhand.order_chat_room_for_r23(p_order_id, u)).id
   for update;
  if v_room.id is null then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  v_buyer := u = v_room.buyer_id;
  update public.chat_messages
     set is_read = true, read_at = now(), updated_at = now()
   where room_id = v_room.id and not is_read
     and case when v_buyer then sender_id <> u else sender_id = v_room.buyer_id end;
  get diagnostics n = row_count;
  update public.chat_rooms
     set buyer_unread_count = case when v_buyer then 0 else buyer_unread_count end,
         seller_unread_count = case when v_buyer then seller_unread_count else 0 end,
         updated_at = now()
   where id = v_room.id;
  update public.notifications
     set is_read = true
   where profile_id = u and notification_type = 'order_message' and target_id = p_order_id
     and not coalesce(is_read, false);
  return jsonb_build_object('read', n);
end $$;

-- Money ------------------------------------------------------------------------------------------------------------

create or replace function secondhand.pay_order(p_order_id uuid, p_method text)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_product_id uuid;
  v_order public.orders;
  v_details secondhand.order_details;
  v_settings secondhand.market_settings;
  v_problem text;
  v_price jsonb;
  v_buyer_wallet public.wallets;
  v_seller_wallet uuid;
  v_escrow uuid;
  v_days integer;
begin
  select o.product_id into v_product_id from public.orders o where o.id = p_order_id and o.buyer_id = u;
  if v_product_id is null then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  -- The item first: buyers paying for the same item queue here, and the one
  -- who comes second finds the item sold and their order cancelled.
  perform 1 from public.products p where p.id = v_product_id for update;
  select * into strict v_order from public.orders o where o.id = p_order_id for update;
  select * into strict v_details from secondhand.order_details d where d.order_id = p_order_id for update;

  if v_order.order_status = 'cancelled' and v_order.cancel_reason = 'sold_to_other' then
    raise exception 'sold_to_other' using errcode = '22023';
  end if;
  if v_order.order_status <> 'pending' or v_details.pay_by <= now() then
    raise exception 'order_not_payable' using errcode = '22023';
  end if;
  v_problem := secondhand.checkout_problem_r22(u, v_order.product_id);
  if v_problem is not null then
    raise exception '%', v_problem using errcode = case when v_problem = 'not_on_sale' then '22023' else '42501' end;
  end if;
  -- The price may have moved since the order was placed (a new listing price,
  -- or this buyer's accepted offer expired or arrived).
  v_price := secondhand.offer_checkout_price_r20g(v_order.product_id, u);
  if (v_price->>'price')::numeric is distinct from v_order.total_amount then
    raise exception 'price_changed' using errcode = '22023';
  end if;
  if p_method is null or p_method not in ('wallet', 'mock') then
    raise exception 'invalid_payment_method' using errcode = '22023';
  end if;
  select * into strict v_settings from secondhand.market_settings s where s.id;
  if p_method = 'mock' and not v_settings.mock_payment_enabled then
    raise exception 'mock_payment_disabled' using errcode = '42501';
  end if;

  -- Escrow needs both wallets; they start empty. A business shop sells into its organization's wallet.
  insert into public.wallets(profile_id) values (v_order.buyer_id) on conflict (profile_id) do nothing;
  v_seller_wallet := secondhand.shop_wallet_r27(v_order.shop_id);
  select * into strict v_buyer_wallet from public.wallets w where w.profile_id = v_order.buyer_id for update;

  if p_method = 'wallet' then
    if v_buyer_wallet.wallet_status <> 'active' or v_buyer_wallet.balance < v_order.total_amount then
      raise exception 'insufficient_balance' using errcode = '22023';
    end if;
    update public.wallets set balance = balance - v_order.total_amount, updated_at = now()
     where id = v_buyer_wallet.id;
    insert into public.wallet_transactions(wallet_id, order_id, transaction_type, amount, balance_before,
                                           balance_after, description)
    values (v_buyer_wallet.id, v_order.id, 'payment', v_order.total_amount, v_buyer_wallet.balance,
            v_buyer_wallet.balance - v_order.total_amount, 'ชำระค่าสินค้า ' || v_order.order_number);
  end if;

  insert into public.escrow_transactions(order_id, buyer_wallet_id, seller_wallet_id, amount, escrow_status)
  values (v_order.id, v_buyer_wallet.id, v_seller_wallet, v_order.total_amount, 'holding')
  returning id into v_escrow;
  insert into public.payment_transactions(escrow_id, payer_wallet_id, transaction_type, amount, status,
                                          reference_no, note, processed_at)
  values (v_escrow, case when p_method = 'wallet' then v_buyer_wallet.id end, 'payment', v_order.total_amount,
          'completed', v_order.order_number, p_method, now());

  select coalesce(p.handling_time_days, 3) into v_days from public.products p where p.id = v_order.product_id;
  update public.orders
     set order_status = 'paid', payment_status = 'paid', escrow_status = 'holding', paid_at = now(), updated_at = now()
   where id = v_order.id;
  update secondhand.order_details
     set payment_method = p_method, escrow_id = v_escrow, offer_id = (v_price->>'offer_id')::uuid,
         ship_by = now() + make_interval(days => v_days), updated_at = now()
   where order_id = v_order.id;

  -- Use the offer before the item turns SOLD; SOLD cancels every other open
  -- offer and every other unpaid order for the item.
  if v_price->>'offer_id' is not null then
    perform secondhand.use_price_offer_r20g((v_price->>'offer_id')::uuid, v_order.id);
  end if;
  update public.products set status = 'sold', updated_at = now() where id = v_order.product_id;

  perform secondhand.order_log_r22(v_order.id, u, 'pending', 'paid', 'paid', p_method);
  perform secondhand.order_notify_r22(v_order.seller_id, v_order.id, 'paid', 'สินค้าของคุณขายได้แล้ว',
    'คำสั่งซื้อ ' || v_order.order_number || ': ผู้ซื้อชำระเงินแล้ว กรุณาจัดส่งภายใน ' || v_days || ' วัน');

  return jsonb_build_object('order_id', v_order.id, 'status', 'paid', 'payment_method', p_method);
end $$;

-- Proceeds go to the wallet the escrow was opened for.
create or replace function secondhand.complete_order_r22(p_order_id uuid, p_actor uuid)
returns void
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_order public.orders;
  v_details secondhand.order_details;
  v_wallet public.wallets;
  v_wallet_id uuid;
  v_net numeric;
  v_values jsonb;
  v_buyer_key text;
begin
  select * into strict v_order from public.orders o where o.id = p_order_id for update;
  select * into strict v_details from secondhand.order_details d where d.order_id = p_order_id for update;
  if v_order.order_status <> 'shipped' then
    raise exception 'order_not_receivable' using errcode = '22023';
  end if;

  -- The commission trigger sets marketplace_fee on completion.
  update public.orders
     set order_status = 'completed', escrow_status = 'released', delivered_at = coalesce(delivered_at, now()),
         completed_at = now(), updated_at = now()
   where id = p_order_id
  returning * into v_order;
  v_net := greatest(v_order.total_amount - v_order.marketplace_fee, 0);

  update public.escrow_transactions set escrow_status = 'released', released_at = now() where id = v_details.escrow_id
  returning seller_wallet_id into v_wallet_id;

  if v_details.payment_method = 'wallet' then
    select * into strict v_wallet from public.wallets w where w.id = v_wallet_id for update;
    update public.wallets set balance = balance + v_net, updated_at = now() where id = v_wallet.id;
    insert into public.wallet_transactions(wallet_id, order_id, transaction_type, amount, balance_before,
                                           balance_after, description)
    values (v_wallet.id, v_order.id, 'sale', v_net, v_wallet.balance, v_wallet.balance + v_net,
            'รายได้จากการขาย ' || v_order.order_number);
  end if;
  insert into public.payment_transactions(escrow_id, receiver_wallet_id, transaction_type, amount, status,
                                          reference_no, note, processed_at)
  select v_details.escrow_id,
         case when v_details.payment_method = 'wallet' then v_wallet_id end,
         x.kind, x.amount, 'completed', v_order.order_number,
         case when v_details.payment_method = 'mock' then 'mock: no money moved' else 'wallet' end, now()
    from (values ('release', v_net), ('fee', v_order.marketplace_fee)) x(kind, amount)
   where x.amount > 0 or x.kind = 'release';

  perform secondhand.order_log_r22(p_order_id, p_actor, 'shipped', 'completed', 'completed',
                                   case when p_actor is null then 'auto' end);
  perform secondhand.order_log_r22(p_order_id, p_actor, 'completed', 'completed', 'escrow_released',
                                   v_details.payment_method);

  v_values := jsonb_build_object('order', v_order.order_number,
                                 'net', to_char(v_net, 'FM999,999,990.00'),
                                 'fee', to_char(v_order.marketplace_fee, 'FM999,999,990.00'));
  perform secondhand.order_notify_r22(v_order.seller_id, p_order_id, 'completed',
    kaoid_private.content_message_r24('secondhand.notice.order_completed_seller', 'title', null,
                                      'การซื้อขายเสร็จสมบูรณ์'),
    case when v_details.payment_method = 'mock'
         then kaoid_private.content_message_r24('secondhand.notice.order_completed_seller_mock', 'body', v_values,
                'คำสั่งซื้อ {order}: ชำระแบบจำลอง จึงไม่มีเงินเข้ากระเป๋า กรุณาประเมินผู้ซื้อ')
         else kaoid_private.content_message_r24('secondhand.notice.order_completed_seller', 'body', v_values,
                'คำสั่งซื้อ {order}: โอนรายได้สุทธิ ฿{net} เข้ากระเป๋าแล้ว (หักค่าธรรมเนียม ฿{fee}) กรุณาประเมินผู้ซื้อ')
    end);
  v_buyer_key := case when exists (select 1 from secondhand.reviews r
                                    where r.order_id = p_order_id and r.reviewer_id = v_order.buyer_id)
                      then 'secondhand.notice.order_completed_buyer'
                      else 'secondhand.notice.order_auto_received_buyer' end;
  perform secondhand.order_notify_r22(v_order.buyer_id, p_order_id, 'completed',
    kaoid_private.content_message_r24(v_buyer_key, 'title', null, 'การซื้อขายเสร็จสมบูรณ์'),
    kaoid_private.content_message_r24(v_buyer_key, 'body', v_values,
      case when v_buyer_key = 'secondhand.notice.order_completed_buyer'
           then 'คำสั่งซื้อ {order} เสร็จสมบูรณ์ ขอบคุณที่ประเมินผู้ขาย'
           else 'คำสั่งซื้อ {order}: ระบบยืนยันรับสินค้าให้อัตโนมัติแล้ว อย่าลืมประเมินผู้ขาย' end));
end $$;

create or replace function secondhand.settle_order_commission_r20b()
returns trigger
language plpgsql
security definer
set search_path to ''
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

  if v_settings.first_sale_promo_enabled
     and exists (select 1 from public.shops s where s.id = new.shop_id and s.seller_identity_type = 'personal') then
    insert into secondhand.first_sale_promotions (profile_id, product_id, order_id)
    values (v_listing.seller_id, new.product_id, new.id)
    on conflict (profile_id) do nothing;
    v_promo := found;
  end if;

  new.marketplace_fee := floor(new.product_price *
    case when v_promo then v_settings.first_sale_fee_rate else v_listing.sales_fee_rate end);
  return new;
end $$;

-- Withdrawals ------------------------------------------------------------------------------------------------------

-- The bank a withdrawal must still be paid to: the member's own, or the organization's.
create or replace function secondhand.withdraw_bank_r27(r public.withdraw_requests)
returns uuid
language sql
stable security definer
set search_path to ''
as $$
  select case when r.organization_id is null then (secondhand.payout_bank_r24(r.profile_id)).id
              else (secondhand.org_payout_bank_r27(r.organization_id)).id end;
$$;

-- Without p_shop_id: the member's own wallet. With a business shop: its organization's wallet (owner/finance only).
drop function secondhand.get_withdrawal_info();
create function secondhand.get_withdrawal_info(p_shop_id uuid default null)
returns jsonb
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  s public.shops;
  w public.wallets;
  b public.bank_accounts;
  r public.withdraw_requests;
  v_min numeric(12,2);
  v_reason text;
begin
  if p_shop_id is null then
    select * into w from public.wallets where profile_id = u;
    b := secondhand.payout_bank_r24(u);
  else
    select * into s from public.shops where id = p_shop_id;
    if not found or s.seller_identity_type <> 'business' or not secondhand.shop_can_r27(p_shop_id, 'finance', u) then
      raise exception 'shop_not_found' using errcode = '22023';
    end if;
    select * into w from public.wallets where organization_id = s.organization_id;
    b := secondhand.org_payout_bank_r27(s.organization_id);
  end if;
  select s2.withdraw_min_amount into v_min from secondhand.market_settings s2 where s2.id;
  select * into r from public.withdraw_requests x where x.wallet_id = w.id and x.withdraw_status = 'pending';
  v_reason := case
    when b.id is null then 'bank_required'
    when w.id is not null and w.wallet_status <> 'active' then 'wallet_unavailable'
    when r.id is not null then 'request_pending'
    when coalesce(w.balance, 0) < v_min then 'balance_too_low'
  end;
  return jsonb_build_object(
    'balance', coalesce(w.balance, 0), 'hold_balance', coalesce(w.hold_balance, 0),
    'pending_release', coalesce(secondhand.wallet_pending_release_r27(w.id), 0),
    'currency', coalesce(w.currency, 'THB'),
    'min_amount', v_min, 'fee', 0,
    'shop_id', p_shop_id,
    'organization_name', (select o.name from public.organizations o where o.id = s.organization_id),
    'bank', case when b.id is not null then jsonb_build_object(
      'bank_name', b.bank_name, 'account_name', b.account_name, 'last4', right(b.account_number, 4)) end,
    'can_withdraw', v_reason is null, 'reason', v_reason,
    'pending', case when r.id is not null then secondhand.withdrawal_json_r24(r) end);
end $$;

drop function secondhand.request_withdrawal(numeric);
create function secondhand.request_withdrawal(p_amount numeric, p_shop_id uuid default null)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  s public.shops;
  w public.wallets;
  b public.bank_accounts;
  r public.withdraw_requests;
  v_min numeric(12,2);
  v_tx uuid;
  v_wallet_id uuid;
begin
  if p_shop_id is not null then
    select * into s from public.shops where id = p_shop_id;
    if not found or s.seller_identity_type <> 'business' or not secondhand.shop_can_r27(p_shop_id, 'finance', u) then
      raise exception 'shop_not_found' using errcode = '22023';
    end if;
  end if;
  select x.withdraw_min_amount into v_min from secondhand.market_settings x where x.id;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) or p_amount > 10000000 then
    raise exception 'invalid_amount' using errcode = '22023';
  end if;
  if p_amount < v_min then
    raise exception 'amount_below_minimum' using errcode = '22023';
  end if;
  b := case when p_shop_id is null then secondhand.payout_bank_r24(u)
            else secondhand.org_payout_bank_r27(s.organization_id) end;
  if b.id is null then
    raise exception 'bank_required' using errcode = '42501';
  end if;

  if p_shop_id is null then
    insert into public.wallets(profile_id) values (u) on conflict (profile_id) do nothing;
    select * into strict w from public.wallets where profile_id = u for update;
  else
    v_wallet_id := secondhand.shop_wallet_r27(p_shop_id);
    select * into strict w from public.wallets where id = v_wallet_id for update;
  end if;
  if w.wallet_status <> 'active' then
    raise exception 'wallet_unavailable' using errcode = '42501';
  end if;
  if exists (select 1 from public.withdraw_requests x where x.wallet_id = w.id and x.withdraw_status = 'pending') then
    raise exception 'withdrawal_pending' using errcode = '22023';
  end if;
  if w.balance < p_amount then
    raise exception 'insufficient_balance' using errcode = '22023';
  end if;

  update public.wallets
     set balance = balance - p_amount, hold_balance = hold_balance + p_amount, updated_at = now()
   where id = w.id;
  insert into public.wallet_transactions(wallet_id, transaction_type, amount, balance_before, balance_after,
                                         description, transaction_status)
  values (w.id, 'withdraw', p_amount, w.balance, w.balance - p_amount,
          'ถอนเงินเข้าบัญชี ' || b.bank_name || ' ••••' || right(b.account_number, 4), 'pending')
  returning id into v_tx;
  insert into public.withdraw_requests(wallet_id, profile_id, organization_id, amount, bank_name, account_name,
                                       account_number, bank_account_id, account_last4, wallet_transaction_id,
                                       source_app)
  values (w.id, u, s.organization_id, p_amount, b.bank_name, b.account_name, null, b.id, right(b.account_number, 4),
          v_tx, 'secondhand')
  returning * into r;
  return secondhand.withdrawal_json_r24(r);
end $$;

create or replace function secondhand.cancel_withdrawal(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  r public.withdraw_requests;
begin
  select * into r from public.withdraw_requests x where x.id = p_id for update;
  if not found
     or not (r.profile_id = u
             or (r.organization_id is not null
                 and exists (select 1 from public.shops s
                              where s.organization_id = r.organization_id and s.seller_identity_type = 'business'
                                and secondhand.shop_can_r27(s.id, 'finance', u)))) then
    raise exception 'withdrawal_not_found' using errcode = '22023';
  end if;
  if r.withdraw_status = 'cancelled' then
    return secondhand.withdrawal_json_r24(r);
  end if;
  r := secondhand.return_withdrawal_r24(r.id, 'cancelled', null, u);
  return secondhand.withdrawal_json_r24(r);
end $$;

revoke all on function secondhand.withdraw_bank_r27(public.withdraw_requests) from public, anon, authenticated;

revoke all on function
  secondhand.create_listing(uuid, text, text, smallint, numeric, text[], text, text, integer, smallint, text, uuid),
  secondhand.my_listings(uuid), secondhand.list_my_orders(text, timestamptz, integer, uuid),
  secondhand.get_withdrawal_info(uuid), secondhand.request_withdrawal(numeric, uuid)
  from public, anon, authenticated;
grant execute on function
  secondhand.create_listing(uuid, text, text, smallint, numeric, text[], text, text, integer, smallint, text, uuid),
  secondhand.my_listings(uuid), secondhand.list_my_orders(text, timestamptz, integer, uuid),
  secondhand.get_withdrawal_info(uuid), secondhand.request_withdrawal(numeric, uuid)
  to authenticated;
