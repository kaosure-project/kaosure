-- R40: a sold listing is evidence. The database itself keeps it unchanged.
--
-- "Sold" means the product has an order past payment: any status except pending (unpaid) and cancelled.
--
--   * Every order that reaches payment gets a permanent copy of the listing as the buyer paid for it
--     (secondhand.order_listing_snapshots). The copy can never be changed or deleted, by anyone.
--   * While a product is sold, its row, photos and listing terms cannot be changed or deleted, whichever
--     function, role or console runs the statement. Only the counters (views, favorites), the moderation
--     switch is_active (hiding is the only takedown; nothing is erased) and the move to SOLD itself pass.
--   * A photo file in any copy, or on a sold product, can no longer be deleted from Storage.
--   * When a paid order is cancelled and refunded, the product unlocks and the seller may edit and relist
--     it as before (R22); the copy keeps what that buyer paid for, and update_listing no longer offers its
--     photos for deletion.
--   * orders(product_id) had two identical indexes; orders_product_r22 is dropped. A partial index serves the
--     sold check.

-- 1. The sold check -------------------------------------------------------------------------------------

drop index if exists public.orders_product_r22;

create index if not exists orders_product_sold_r40
  on public.orders (product_id)
  where order_status not in ('pending', 'cancelled');

create or replace function secondhand.product_sold_r40(p_product_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.orders o
                  where o.product_id = p_product_id
                    and o.order_status not in ('pending', 'cancelled'))
$$;

revoke all on function secondhand.product_sold_r40(uuid) from public, anon, authenticated;

-- 2. The copy taken at payment --------------------------------------------------------------------------

create table if not exists secondhand.order_listing_snapshots (
  order_id uuid primary key references public.orders(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete restrict,
  shop_id uuid not null,
  seller_id uuid,
  captured_at timestamptz not null default now(),
  title text not null,
  price numeric not null,
  currency text,
  category_id uuid,
  category_name text,
  image_paths text[] not null,
  product jsonb not null,
  listing jsonb
);

comment on table secondhand.order_listing_snapshots is
  'R40: the listing exactly as it was when the order was paid. Written once by a trigger on public.orders; never updated or deleted.';

create index if not exists order_listing_snapshots_product_r40 on secondhand.order_listing_snapshots (product_id);
create index if not exists order_listing_snapshots_images_r40 on secondhand.order_listing_snapshots using gin (image_paths);

alter table secondhand.order_listing_snapshots enable row level security;
revoke all on table secondhand.order_listing_snapshots from public, anon, authenticated;

create or replace function secondhand.capture_order_listing_r40()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into secondhand.order_listing_snapshots(order_id, product_id, shop_id, seller_id, title, price, currency,
                                                 category_id, category_name, image_paths, product, listing)
  select new.id, p.id, coalesce(new.shop_id, p.shop_id), new.seller_id, p.title, p.price, p.currency,
         p.category_id, c.name,
         array(select i.image_url from public.product_images i where i.product_id = p.id order by i.image_order),
         to_jsonb(p) - array['view_count', 'favorite_count'],
         (select to_jsonb(l) from secondhand.listings l where l.product_id = p.id)
    from public.products p
    left join public.categories c on c.id = p.category_id
   where p.id = new.product_id
  on conflict (order_id) do nothing;
  return null;
end $$;

drop trigger if exists orders_listing_snapshot_r40 on public.orders;
create trigger orders_listing_snapshot_r40
  after insert or update of order_status on public.orders
  for each row
  when (new.order_status not in ('pending', 'cancelled'))
  execute function secondhand.capture_order_listing_r40();

create or replace function secondhand.refuse_snapshot_change_r40()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'order_snapshot_immutable'
    using errcode = '42501', detail = 'An order''s listing copy is permanent evidence.';
end $$;

drop trigger if exists order_listing_snapshots_immutable_r40 on secondhand.order_listing_snapshots;
create trigger order_listing_snapshots_immutable_r40
  before update or delete on secondhand.order_listing_snapshots
  for each row execute function secondhand.refuse_snapshot_change_r40();

drop trigger if exists order_listing_snapshots_no_truncate_r40 on secondhand.order_listing_snapshots;
create trigger order_listing_snapshots_no_truncate_r40
  before truncate on secondhand.order_listing_snapshots
  for each statement execute function secondhand.refuse_snapshot_change_r40();

-- 3. The lock on a sold product -------------------------------------------------------------------------

create or replace function secondhand.guard_sold_product_r40()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_free constant text[] := array['view_count', 'favorite_count', 'is_active', 'updated_at', 'status'];
begin
  if not secondhand.product_sold_r40(old.id) then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  if tg_op = 'DELETE'
     or (to_jsonb(new) - v_free) is distinct from (to_jsonb(old) - v_free)
     or (new.status is distinct from old.status and new.status <> 'sold') then
    raise exception 'listing_sold_locked'
      using errcode = '42501', detail = 'A sold product is order evidence and cannot be changed or deleted.';
  end if;
  return new;
end $$;

drop trigger if exists products_sold_lock_r40 on public.products;
create trigger products_sold_lock_r40
  before update or delete on public.products
  for each row execute function secondhand.guard_sold_product_r40();

create or replace function secondhand.guard_sold_product_images_r40()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (tg_op <> 'INSERT' and secondhand.product_sold_r40(old.product_id))
     or (tg_op <> 'DELETE' and secondhand.product_sold_r40(new.product_id)) then
    raise exception 'listing_sold_locked'
      using errcode = '42501', detail = 'A sold product''s photos are order evidence.';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end $$;

drop trigger if exists product_images_sold_lock_r40 on public.product_images;
create trigger product_images_sold_lock_r40
  before insert or update or delete on public.product_images
  for each row execute function secondhand.guard_sold_product_images_r40();

create or replace function secondhand.guard_sold_listing_r40()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if secondhand.product_sold_r40(old.product_id) then
    raise exception 'listing_sold_locked'
      using errcode = '42501', detail = 'A sold listing''s terms are order evidence.';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end $$;

drop trigger if exists listings_sold_lock_r40 on secondhand.listings;
create trigger listings_sold_lock_r40
  before update or delete on secondhand.listings
  for each row execute function secondhand.guard_sold_listing_r40();

revoke all on function secondhand.capture_order_listing_r40() from public, anon, authenticated;
revoke all on function secondhand.refuse_snapshot_change_r40() from public, anon, authenticated;
revoke all on function secondhand.guard_sold_product_r40() from public, anon, authenticated;
revoke all on function secondhand.guard_sold_product_images_r40() from public, anon, authenticated;
revoke all on function secondhand.guard_sold_listing_r40() from public, anon, authenticated;

-- 4. Photo files that are evidence stay in Storage ------------------------------------------------------

create index if not exists product_images_url_r40 on public.product_images (image_url);

create or replace function secondhand.product_photo_kept_r40(p_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from secondhand.order_listing_snapshots s where s.image_paths @> array[p_path])
      or exists (select 1 from public.product_images i
                  where i.image_url = p_path and secondhand.product_sold_r40(i.product_id))
$$;

revoke all on function secondhand.product_photo_kept_r40(text) from public, anon;
grant execute on function secondhand.product_photo_kept_r40(text) to authenticated;

drop policy if exists "Secondhand product photos delete own folder" on storage.objects;
create policy "Secondhand product photos delete own folder"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'marketplace-product-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and not secondhand.product_photo_kept_r40(name)
  );

-- 5. update_listing: photos kept as evidence are not offered for deletion -------------------------------

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
    'removed_paths', to_jsonb(array(select x from unnest(v_old) x
                                     where x <> all (p_image_paths)
                                       and not secondhand.product_photo_kept_r40(x)))
  );
end $$;
