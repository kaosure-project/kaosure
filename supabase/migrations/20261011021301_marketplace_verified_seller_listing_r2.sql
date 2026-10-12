-- Verified seller listing flow for one-off secondhand inventory.
-- Only narrowly scoped product photos are public; uploads stay owner-scoped.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'marketplace-product-images',
  'marketplace-product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

do $policy$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Secondhand product photos upload own folder'
  ) then
    create policy "Secondhand product photos upload own folder"
      on storage.objects for insert to authenticated
      with check (
        bucket_id = 'marketplace-product-images'
        and (storage.foldername(name))[1] = (select auth.uid())::text
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Secondhand product photos delete own folder'
  ) then
    create policy "Secondhand product photos delete own folder"
      on storage.objects for delete to authenticated
      using (
        bucket_id = 'marketplace-product-images'
        and (storage.foldername(name))[1] = (select auth.uid())::text
      );
  end if;
end;
$policy$;

-- The former draft RPC is no longer a supported public app path. Product
-- creation now goes through the image and eligibility-checked RPC below.
revoke execute on function public.create_marketplace_product(
  uuid, uuid, text, text, text, smallint, numeric, integer
) from public, anon, authenticated;

grant select (seller_identity_type) on public.shops to authenticated;

create or replace function public.get_my_seller_readiness()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_has_identity boolean;
  v_financially_verified boolean;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select exists (
    select 1 from public.kao_id_identities k
    where k.profile_id = auth.uid()
      and k.organization_id is null
      and k.identity_type = 'personal'
      and k.status = 'active'
  ) into v_has_identity;

  v_financially_verified := public.is_identity_financially_verified(
    'personal', auth.uid(), null
  );

  return jsonb_build_object(
    'authenticated', true,
    'hasIdentity', v_has_identity,
    'financiallyVerified', v_financially_verified
  );
end;
$function$;

revoke all on function public.get_my_seller_readiness() from public, anon;
grant execute on function public.get_my_seller_readiness() to authenticated;

create or replace function public.create_marketplace_listing(
  p_shop_id uuid,
  p_category_id uuid,
  p_title text,
  p_description text,
  p_condition_level smallint,
  p_price numeric,
  p_image_paths text[]
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_product_id uuid := pg_catalog.gen_random_uuid();
  v_path text;
  v_order integer := 0;
  v_shop_owner uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select s.owner_id into v_shop_owner
  from public.shops s
  where s.id = p_shop_id
    and s.owner_id = auth.uid()
    and s.seller_identity_type = 'personal'
    and s.shop_status = 'active';

  if v_shop_owner is null then
    raise exception 'Active personal seller shop is required';
  end if;

  if not exists (
    select 1 from public.kao_id_identities k
    where k.profile_id = auth.uid()
      and k.organization_id is null
      and k.identity_type = 'personal'
      and k.status = 'active'
  ) then
    raise exception 'Active Personal Kao ID is required before listing products';
  end if;

  if not public.is_identity_financially_verified('personal', auth.uid(), null) then
    raise exception 'Personal identity and verified bank account are required before listing products';
  end if;

  if not exists (
    select 1 from public.categories c
    where c.id = p_category_id and c.is_active = true
  ) then
    raise exception 'Active category is required';
  end if;

  if p_title is null or length(btrim(p_title)) < 3 or length(p_title) > 100 then
    raise exception 'Product title must contain 3 to 100 characters';
  end if;
  if p_description is null or length(btrim(p_description)) < 10 or length(p_description) > 3000 then
    raise exception 'Product description must contain 10 to 3000 characters';
  end if;
  if p_condition_level is null or p_condition_level < 1 or p_condition_level > 6 then
    raise exception 'Product condition is invalid';
  end if;
  if p_price is null or p_price <= 0 or p_price > 100000000 then
    raise exception 'Product price is invalid';
  end if;
  if p_image_paths is null or cardinality(p_image_paths) < 1 or cardinality(p_image_paths) > 8 then
    raise exception 'One to eight product photos are required';
  end if;
  if array_position(p_image_paths, null) is not null
     or cardinality(p_image_paths) <> (select count(distinct path) from unnest(p_image_paths) as photo(path)) then
    raise exception 'Product photo paths must be unique and non-null';
  end if;

  foreach v_path in array p_image_paths loop
    if v_path !~ ('^' || auth.uid()::text || '/[A-Za-z0-9_-]+/[0-7]\.(jpg|png|webp)$') then
      raise exception 'Invalid product photo path';
    end if;
    if not exists (
      select 1 from storage.objects o
      where o.bucket_id = 'marketplace-product-images'
        and o.name = v_path
    ) then
      raise exception 'Product photo upload was not found';
    end if;
  end loop;

  insert into public.products (
    id, shop_id, category_id, title, slug, description,
    condition_level, price, stock, status, is_active, currency
  ) values (
    v_product_id, p_shop_id, p_category_id, btrim(p_title),
    'used-' || replace(v_product_id::text, '-', ''), btrim(p_description),
    p_condition_level, p_price, 1, 'active', true, 'THB'
  );

  foreach v_path in array p_image_paths loop
    v_order := v_order + 1;
    insert into public.product_images (product_id, image_url, image_order, is_cover)
    values (v_product_id, v_path, v_order, v_order = 1);
  end loop;

  return v_product_id;
end;
$function$;

revoke all on function public.create_marketplace_listing(
  uuid, uuid, text, text, smallint, numeric, text[]
) from public, anon;
grant execute on function public.create_marketplace_listing(
  uuid, uuid, text, text, smallint, numeric, text[]
) to authenticated;
;
