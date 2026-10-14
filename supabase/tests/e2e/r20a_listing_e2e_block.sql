-- R20a checks. Appended after the migration inside one transaction that never commits.
do $$
declare
  seller uuid := '9044e32e-24e7-49e2-9aaf-500c48ecce7e';
  other uuid := '3bd1dcd3-6ab3-4af5-a83f-2c9883438629';
  seller_session uuid := gen_random_uuid();
  other_session uuid := gen_random_uuid();
  cid uuid := 'f56cdf5a-347a-4847-ad0d-f05b580b007c';
  category uuid := (select id from public.categories where is_active limit 1);
  shop uuid;
  photos text[] := '{}';
  first_product uuid;
  report text := '';
  j jsonb;
  n int;
  step text;
  steps text[] := array['terms_before', 'guard_create_rpc', 'guard_terms_rpc', 'guard_old_rpc', 'guard_listings_write',
    'guard_options_read', 'not_verified', 'stub', 'bad_price_decimal', 'bad_price_low', 'bad_province', 'bad_weight',
    'bad_path', 'too_many_photos', 'bad_payer', 'first', 'images', 'second', 'terms_after', 'anon_listing_read',
    'anon_fee_hidden', 'other_promo_rows', 'direct_insert', 'reference_counts'];
begin
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (seller_session, seller, now(), now(), 'aal1'), (other_session, other, now(), now(), 'aal1');
  select id into shop from public.shops
   where owner_id = seller and seller_identity_type = 'personal' and shop_status = 'active' limit 1;
  if shop is null then
    insert into public.shops(owner_id, seller_identity_type, shop_name, shop_slug)
    values (seller, 'personal', 'E2E shop', 'e2e-shop-r20a') returning id into shop;
  end if;
  for n in 0..20 loop
    insert into storage.objects(bucket_id, name, owner)
    values ('marketplace-product-images', seller || '/e2e-r20a/' || n || '.jpg', seller);
    photos := photos || (seller || '/e2e-r20a/' || n || '.jpg');
  end loop;

  foreach step in array steps loop
    begin
      report := concat(report, coalesce((step || ': ')::text, '<null>'));
      perform set_config('request.jwt.claims', json_build_object('sub', case when step = 'other_promo_rows' then other else seller end,
        'role', 'authenticated', 'session_id', case when step = 'other_promo_rows' then other_session else seller_session end,
        'aal', 'aal1', 'is_anonymous', false, 'client_id', cid)::text, true);
      perform set_config('request.headers', '{}', true);
      perform set_config('request.method', 'GET', true);
      perform set_config('role', 'authenticated', true);

      case step
        when 'terms_before' then
          report := concat(report, coalesce((secondhand.get_listing_terms()::text)::text, '<null>'));
        when 'guard_create_rpc' then
          perform set_config('request.path', '/rpc/create_listing', true);
          perform set_config('request.method', 'POST', true);
          perform set_config('request.headers', '{"content-profile":"secondhand"}', true);
          perform kaoid_private.pre_request_r10d();
          report := concat(report, coalesce(('allowed')::text, '<null>'));
        when 'guard_terms_rpc' then
          perform set_config('request.path', '/rpc/get_listing_terms', true);
          perform set_config('request.method', 'POST', true);
          perform set_config('request.headers', '{"content-profile":"secondhand"}', true);
          perform kaoid_private.pre_request_r10d();
          report := concat(report, coalesce(('allowed')::text, '<null>'));
        when 'guard_old_rpc' then
          perform set_config('request.path', '/rpc/create_marketplace_listing', true);
          perform set_config('request.method', 'POST', true);
          perform kaoid_private.pre_request_r10d();
          report := concat(report, coalesce(('UNEXPECTED_OK')::text, '<null>'));
        when 'guard_listings_write' then
          perform set_config('request.path', '/listings', true);
          perform set_config('request.method', 'POST', true);
          perform set_config('request.headers', '{"content-profile":"secondhand"}', true);
          perform kaoid_private.pre_request_r10d();
          report := concat(report, coalesce(('UNEXPECTED_OK')::text, '<null>'));
        when 'guard_options_read' then
          perform set_config('request.path', '/shipping_options', true);
          perform set_config('request.headers', '{"accept-profile":"secondhand"}', true);
          perform kaoid_private.pre_request_r10d();
          report := concat(report, coalesce(('allowed')::text, '<null>'));
        when 'not_verified' then
          j := secondhand.create_listing(category, 'E2E item', 'E2E description text', 3::smallint, 1000, photos[1:1],
            'seller', 'flash_standard', 1000, 10::smallint, '1_2');
          report := concat(report, coalesce(('UNEXPECTED_OK ' || j::text)::text, '<null>'));
        when 'stub' then
          perform set_config('role', 'postgres', true);
          execute $f$create or replace function public.is_identity_financially_verified(
            p_identity_type text, p_profile_id uuid default null, p_organization_id uuid default null) returns boolean
            language sql as 'select true'$f$;
          report := concat(report, coalesce(('verification stubbed in this transaction')::text, '<null>'));
        when 'bad_price_decimal' then
          perform secondhand.create_listing(category, 'E2E item', 'E2E description text', 3::smallint, 100.5, photos[1:1],
            'seller', 'flash_standard', 1000, 10::smallint, '1_2');
          report := concat(report, coalesce(('UNEXPECTED_OK')::text, '<null>'));
        when 'bad_price_low' then
          perform secondhand.create_listing(category, 'E2E item', 'E2E description text', 3::smallint, 19, photos[1:1],
            'seller', 'flash_standard', 1000, 10::smallint, '1_2');
          report := concat(report, coalesce(('UNEXPECTED_OK')::text, '<null>'));
        when 'bad_province' then
          perform secondhand.create_listing(category, 'E2E item', 'E2E description text', 3::smallint, 1000, photos[1:1],
            'seller', 'flash_standard', 1000, 28::smallint, '1_2');
          report := concat(report, coalesce(('UNEXPECTED_OK')::text, '<null>'));
        when 'bad_weight' then
          perform secondhand.create_listing(category, 'E2E item', 'E2E description text', 3::smallint, 1000, photos[1:1],
            'seller', 'flash_standard', 2000, 10::smallint, '1_2');
          report := concat(report, coalesce(('UNEXPECTED_OK')::text, '<null>'));
        when 'bad_path' then
          perform secondhand.create_listing(category, 'E2E item', 'E2E description text', 3::smallint, 1000, photos[21:21],
            'seller', 'flash_standard', 1000, 10::smallint, '1_2');
          report := concat(report, coalesce(('UNEXPECTED_OK')::text, '<null>'));
        when 'too_many_photos' then
          perform secondhand.create_listing(category, 'E2E item', 'E2E description text', 3::smallint, 1000,
            photos[1:20] || array[photos[1]], 'seller', 'flash_standard', 1000, 10::smallint, '1_2');
          report := concat(report, coalesce(('UNEXPECTED_OK')::text, '<null>'));
        when 'bad_payer' then
          perform secondhand.create_listing(category, 'E2E item', 'E2E description text', 3::smallint, 1000, photos[1:1],
            'nobody', 'flash_standard', 1000, 10::smallint, '1_2');
          report := concat(report, coalesce(('UNEXPECTED_OK')::text, '<null>'));
        when 'first' then
          j := secondhand.create_listing(category, 'E2E first item', 'E2E description text', 3::smallint, 1000, photos[1:20],
            'seller', 'flash_standard', 1000, 50::smallint, '2_3');
          first_product := (j->>'product_id')::uuid;
          report := concat(report, coalesce(((j - 'product_id')::text)::text, '<null>'));
        when 'images' then
          select jsonb_build_object('count', count(*), 'cover', bool_or(is_cover and image_order = 1),
              'covers', count(*) filter (where is_cover))
            into j from public.product_images where product_id = first_product;
          report := concat(report, coalesce((j::text || ' handling=' || (select handling_time_days from public.products where id = first_product))::text, '<null>'));
        when 'second' then
          j := secondhand.create_listing(category, 'E2E second item', 'E2E description text', 2::smallint, 1000, photos[1:1],
            'buyer', 'thailand_post_ems', 500, 10::smallint, '1_2');
          report := concat(report, coalesce(((j - 'product_id')::text)::text, '<null>'));
        when 'terms_after' then
          report := concat(report, coalesce(((secondhand.get_listing_terms()->>'first_sale_available'))::text, '<null>'));
        when 'anon_listing_read' then
          perform set_config('role', 'anon', true);
          select count(*) into n from secondhand.listings where product_id = first_product;
          report := concat(report, coalesce(('rows=' || n)::text, '<null>'));
        when 'anon_fee_hidden' then
          perform set_config('role', 'anon', true);
          select count(sales_fee_rate) into n from secondhand.listings;
          report := concat(report, coalesce(('UNEXPECTED_OK')::text, '<null>'));
        when 'other_promo_rows' then
          report := concat(report, coalesce(('rows=' || (select count(*) from secondhand.first_sale_promotions))::text, '<null>'));
        when 'direct_insert' then
          insert into secondhand.first_sale_promotions(profile_id) values (seller);
          report := concat(report, coalesce(('UNEXPECTED_OK')::text, '<null>'));
        when 'reference_counts' then
          perform set_config('role', 'anon', true);
          report := report || jsonb_build_object(
            'provinces', (select count(*) from secondhand.thai_provinces),
            'metro', (select count(*) from secondhand.thai_provinces where is_bangkok_metro),
            'partners', (select count(*) from secondhand.shipping_partners),
            'options', (select count(*) from secondhand.shipping_options),
            'rates', (select count(*) from secondhand.shipping_rates),
            'settings', (select row_to_json(s)::jsonb - 'updated_at' - 'id' from secondhand.market_settings s))::text;
      end case;
      perform set_config('role', 'postgres', true);
      report := concat(report, coalesce((' | ')::text, '<null>'));
    exception when others then
      perform set_config('role', 'postgres', true);
      report := concat(report, coalesce(('ERR ' || sqlerrm || ' | ')::text, '<null>'));
    end;
  end loop;
  raise exception 'E2E_REPORT %', report;
end $$;
