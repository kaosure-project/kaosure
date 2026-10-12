-- R20a: Secondhand listing form (/items/new) for the Thai market.
--
-- Market settings (THB, 10% sales fee, first listing fee-free), Thai shipping
-- partners/options/rates shaped for a later shipping-aggregator or direct
-- carrier API, the 77 provinces, and secondhand.create_listing, which checks
-- the seller on the server and snapshots shipping and fee terms per listing.
-- Carrier API credentials never live in these tables.

-- ---------------------------------------------------------------------------
-- Market settings (single row)
-- ---------------------------------------------------------------------------
create table secondhand.market_settings (
  id boolean primary key default true check (id),
  currency text not null default 'THB' check (currency ~ '^[A-Z]{3}$'),
  sales_fee_rate numeric(5,4) not null default 0.10 check (sales_fee_rate between 0 and 0.5),
  first_sale_promo_enabled boolean not null default true,
  first_sale_fee_rate numeric(5,4) not null default 0 check (first_sale_fee_rate between 0 and 0.5),
  min_price numeric(12,2) not null default 20 check (min_price > 0),
  max_price numeric(12,2) not null default 1000000 check (max_price > 0),
  max_photos smallint not null default 20 check (max_photos between 1 and 20),
  updated_at timestamptz not null default now(),
  check (first_sale_fee_rate <= sales_fee_rate),
  check (min_price < max_price)
);
insert into secondhand.market_settings (id) values (true);

-- ---------------------------------------------------------------------------
-- Provinces (TIS 1099 codes)
-- ---------------------------------------------------------------------------
create table secondhand.thai_provinces (
  code smallint primary key check (code between 10 and 96),
  name_th text not null unique,
  name_en text not null unique,
  region text not null check (region in ('central', 'east', 'northeast', 'north', 'west', 'south')),
  is_bangkok_metro boolean not null default false
);

-- ---------------------------------------------------------------------------
-- Shipping partners, options and reference rates
-- ---------------------------------------------------------------------------
create table secondhand.shipping_partners (
  code text primary key check (code ~ '^[a-z][a-z0-9_]{1,31}$'),
  name_th text not null check (char_length(btrim(name_th)) between 1 and 80),
  name_en text not null check (char_length(btrim(name_en)) between 1 and 80),
  -- manual: seller ships and enters tracking; aggregator/direct_api: booked
  -- through provider_code by a server-side integration (credentials in Vault).
  integration_mode text not null default 'manual' check (integration_mode in ('manual', 'aggregator', 'direct_api')),
  provider_code text check (provider_code is null or provider_code ~ '^[a-z][a-z0-9_]{1,31}$'),
  tracking_url_template text check (tracking_url_template is null or tracking_url_template ~ '^https://[^\s]+\{tracking\}'),
  is_active boolean not null default true,
  sort_order smallint not null default 0,
  updated_at timestamptz not null default now(),
  check (integration_mode = 'manual' or provider_code is not null)
);

create table secondhand.shipping_options (
  code text primary key check (code ~ '^[a-z][a-z0-9_]{1,47}$'),
  partner_code text not null references secondhand.shipping_partners(code),
  name_th text not null check (char_length(btrim(name_th)) between 1 and 80),
  name_en text not null check (char_length(btrim(name_en)) between 1 and 80),
  service_type text not null check (service_type in ('express', 'ems', 'registered')),
  tracking_available boolean not null default true,
  cod_available boolean not null default false,
  provider_service_code text check (provider_service_code is null or char_length(provider_service_code) <= 64),
  estimated_days_min smallint not null check (estimated_days_min between 1 and 14),
  estimated_days_max smallint not null check (estimated_days_max between 1 and 14),
  is_active boolean not null default true,
  sort_order smallint not null default 0,
  updated_at timestamptz not null default now(),
  check (estimated_days_min <= estimated_days_max)
);
create index shipping_options_partner on secondhand.shipping_options(partner_code);

-- Reference prices for the seller's estimate; the real charge comes from the
-- carrier (or aggregator quote) when the parcel is booked.
create table secondhand.shipping_rates (
  option_code text not null references secondhand.shipping_options(code) on delete cascade,
  zone text not null check (zone in ('bangkok_metro', 'upcountry')),
  max_weight_g integer not null check (max_weight_g between 1 and 30000),
  max_size_cm smallint check (max_size_cm is null or max_size_cm between 1 and 300),
  fee numeric(10,2) not null check (fee >= 0),
  reference_source text check (reference_source is null or char_length(reference_source) <= 300),
  updated_at timestamptz not null default now(),
  primary key (option_code, zone, max_weight_g)
);

-- ---------------------------------------------------------------------------
-- Listing terms (one per product) and the first-sale claim
-- ---------------------------------------------------------------------------
create table secondhand.listings (
  product_id uuid primary key references public.products(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  shipping_payer text not null check (shipping_payer in ('seller', 'buyer')),
  shipping_option_code text not null references secondhand.shipping_options(code),
  package_max_weight_g integer not null check (package_max_weight_g between 1 and 30000),
  estimated_shipping_fee numeric(10,2) not null check (estimated_shipping_fee >= 0),
  ship_from_province smallint not null references secondhand.thai_provinces(code),
  ship_within text not null check (ship_within in ('1_2', '2_3', '4_7')),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  sales_fee_rate numeric(5,4) not null check (sales_fee_rate between 0 and 0.5),
  first_sale_promo boolean not null default false,
  created_at timestamptz not null default now()
);
create index listings_seller on secondhand.listings(seller_id, created_at desc);

-- Kept when the product is deleted, so the promotion is used once per seller.
create table secondhand.first_sale_promotions (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  claimed_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Access
-- ---------------------------------------------------------------------------
alter table secondhand.market_settings enable row level security;
alter table secondhand.thai_provinces enable row level security;
alter table secondhand.shipping_partners enable row level security;
alter table secondhand.shipping_options enable row level security;
alter table secondhand.shipping_rates enable row level security;
alter table secondhand.listings enable row level security;
alter table secondhand.first_sale_promotions enable row level security;

create policy market_settings_reference_read on secondhand.market_settings for select to anon, authenticated using (id);
create policy thai_provinces_reference_read on secondhand.thai_provinces for select to anon, authenticated using (code is not null);
create policy shipping_partners_active_read on secondhand.shipping_partners for select to anon, authenticated using (is_active);
create policy shipping_options_active_read on secondhand.shipping_options for select to anon, authenticated
  using (is_active and exists (select 1 from secondhand.shipping_partners p where p.code = partner_code and p.is_active));
create policy shipping_rates_active_read on secondhand.shipping_rates for select to anon, authenticated
  using (exists (select 1 from secondhand.shipping_options o where o.code = option_code and o.is_active));
create policy listings_public_or_own_read on secondhand.listings for select to anon, authenticated
  using (
    seller_id = (select auth.uid())
    or exists (select 1 from public.products p where p.id = product_id and p.is_active and p.status = 'active')
  );
create policy first_sale_promotions_own_read on secondhand.first_sale_promotions for select to authenticated
  using (profile_id = (select auth.uid()));

revoke all on table secondhand.market_settings, secondhand.thai_provinces, secondhand.shipping_partners,
  secondhand.shipping_options, secondhand.shipping_rates, secondhand.listings, secondhand.first_sale_promotions
  from public, anon, authenticated;
grant select on table secondhand.market_settings, secondhand.thai_provinces, secondhand.shipping_partners,
  secondhand.shipping_options, secondhand.shipping_rates to anon, authenticated;
-- Fee terms stay with the seller (via get_listing_terms / create_listing).
grant select (product_id, shipping_payer, shipping_option_code, package_max_weight_g, ship_from_province, ship_within,
  created_at) on table secondhand.listings to anon, authenticated;
grant select on table secondhand.first_sale_promotions to authenticated;
grant all on table secondhand.market_settings, secondhand.thai_provinces, secondhand.shipping_partners,
  secondhand.shipping_options, secondhand.shipping_rates, secondhand.listings, secondhand.first_sale_promotions
  to service_role;

-- ---------------------------------------------------------------------------
-- Terms for the listing form
-- ---------------------------------------------------------------------------
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
    'max_price', s.max_price,
    'max_photos', s.max_photos
  )
  from secondhand.market_settings s
  where s.id
$$;

revoke all on function secondhand.get_listing_terms() from public, anon, authenticated;
grant execute on function secondhand.get_listing_terms() to authenticated;

-- ---------------------------------------------------------------------------
-- Create a listing
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
  v_shop_id uuid;
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

  select s.id into v_shop_id
    from public.shops s
   where s.owner_id = v_uid and s.seller_identity_type = 'personal' and s.shop_status = 'active'
   order by s.created_at
   limit 1;
  if v_shop_id is null then
    raise exception 'Active personal seller shop is required';
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

  if p_shipping_payer is null or p_shipping_payer not in ('seller', 'buyer') then
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

  insert into public.products (
    id, shop_id, category_id, title, slug, description, condition_level, price, stock,
    status, is_active, currency, handling_time_days
  ) values (
    v_product_id, v_shop_id, p_category_id, btrim(p_title), 'used-' || replace(v_product_id::text, '-', ''),
    btrim(p_description), p_condition_level, p_price, 1, 'active', true, v_settings.currency,
    case p_ship_within when '1_2' then 2 when '2_3' then 3 else 7 end
  );

  foreach v_path in array p_image_paths loop
    v_order := v_order + 1;
    insert into public.product_images (product_id, image_url, image_order, is_cover)
    values (v_product_id, v_path, v_order, v_order = 1);
  end loop;

  if v_settings.first_sale_promo_enabled then
    insert into secondhand.first_sale_promotions (profile_id, product_id)
    values (v_uid, v_product_id)
    on conflict (profile_id) do nothing;
    v_promo := found;
  end if;
  v_rate := case when v_promo then v_settings.first_sale_fee_rate else v_settings.sales_fee_rate end;
  v_fee := floor(p_price * v_rate);

  insert into secondhand.listings (
    product_id, seller_id, shipping_payer, shipping_option_code, package_max_weight_g, estimated_shipping_fee,
    ship_from_province, ship_within, currency, sales_fee_rate, first_sale_promo
  ) values (
    v_product_id, v_uid, p_shipping_payer, p_shipping_option, p_package_max_weight_g, v_shipping_fee,
    p_ship_from_province, p_ship_within, v_settings.currency, v_rate, v_promo
  );

  return jsonb_build_object(
    'product_id', v_product_id,
    'currency', v_settings.currency,
    'sales_fee_rate', v_rate,
    'sales_fee', v_fee,
    'estimated_shipping_fee', case when p_shipping_payer = 'seller' then v_shipping_fee else 0 end,
    'net_amount', p_price - v_fee - case when p_shipping_payer = 'seller' then v_shipping_fee else 0 end,
    'first_sale_promo', v_promo
  );
end $$;

revoke all on function secondhand.create_listing(uuid, text, text, smallint, numeric, text[], text, text, integer, smallint, text)
  from public, anon, authenticated;
grant execute on function secondhand.create_listing(uuid, text, text, smallint, numeric, text[], text, text, integer, smallint, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Secondhand token scope
-- ---------------------------------------------------------------------------
update kaoid_private.app_clients_r18
   set allowed_tables = array(select distinct t from unnest(allowed_tables || array[
         'secondhand.market_settings', 'secondhand.thai_provinces', 'secondhand.shipping_partners',
         'secondhand.shipping_options', 'secondhand.shipping_rates', 'secondhand.listings',
         'secondhand.first_sale_promotions']) t order by 1),
       allowed_rpcs = array(select distinct r from unnest(array_remove(allowed_rpcs, 'public.create_marketplace_listing') || array[
         'secondhand.get_listing_terms', 'secondhand.create_listing']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';

-- ===========================================================================
-- Reference data (reviewed before push)
-- ===========================================================================
insert into secondhand.thai_provinces (code, name_th, name_en, region, is_bangkok_metro) values
  (10, 'กรุงเทพมหานคร', 'Bangkok', 'central', true),
  (11, 'สมุทรปราการ', 'Samut Prakan', 'central', true),
  (12, 'นนทบุรี', 'Nonthaburi', 'central', true),
  (13, 'ปทุมธานี', 'Pathum Thani', 'central', true),
  (14, 'พระนครศรีอยุธยา', 'Phra Nakhon Si Ayutthaya', 'central', false),
  (15, 'อ่างทอง', 'Ang Thong', 'central', false),
  (16, 'ลพบุรี', 'Lopburi', 'central', false),
  (17, 'สิงห์บุรี', 'Sing Buri', 'central', false),
  (18, 'ชัยนาท', 'Chai Nat', 'central', false),
  (19, 'สระบุรี', 'Saraburi', 'central', false),
  (20, 'ชลบุรี', 'Chonburi', 'east', false),
  (21, 'ระยอง', 'Rayong', 'east', false),
  (22, 'จันทบุรี', 'Chanthaburi', 'east', false),
  (23, 'ตราด', 'Trat', 'east', false),
  (24, 'ฉะเชิงเทรา', 'Chachoengsao', 'east', false),
  (25, 'ปราจีนบุรี', 'Prachinburi', 'east', false),
  (26, 'นครนายก', 'Nakhon Nayok', 'central', false),
  (27, 'สระแก้ว', 'Sa Kaeo', 'east', false),
  (30, 'นครราชสีมา', 'Nakhon Ratchasima', 'northeast', false),
  (31, 'บุรีรัมย์', 'Buriram', 'northeast', false),
  (32, 'สุรินทร์', 'Surin', 'northeast', false),
  (33, 'ศรีสะเกษ', 'Sisaket', 'northeast', false),
  (34, 'อุบลราชธานี', 'Ubon Ratchathani', 'northeast', false),
  (35, 'ยโสธร', 'Yasothon', 'northeast', false),
  (36, 'ชัยภูมิ', 'Chaiyaphum', 'northeast', false),
  (37, 'อำนาจเจริญ', 'Amnat Charoen', 'northeast', false),
  (38, 'บึงกาฬ', 'Bueng Kan', 'northeast', false),
  (39, 'หนองบัวลำภู', 'Nong Bua Lamphu', 'northeast', false),
  (40, 'ขอนแก่น', 'Khon Kaen', 'northeast', false),
  (41, 'อุดรธานี', 'Udon Thani', 'northeast', false),
  (42, 'เลย', 'Loei', 'northeast', false),
  (43, 'หนองคาย', 'Nong Khai', 'northeast', false),
  (44, 'มหาสารคาม', 'Maha Sarakham', 'northeast', false),
  (45, 'ร้อยเอ็ด', 'Roi Et', 'northeast', false),
  (46, 'กาฬสินธุ์', 'Kalasin', 'northeast', false),
  (47, 'สกลนคร', 'Sakon Nakhon', 'northeast', false),
  (48, 'นครพนม', 'Nakhon Phanom', 'northeast', false),
  (49, 'มุกดาหาร', 'Mukdahan', 'northeast', false),
  (50, 'เชียงใหม่', 'Chiang Mai', 'north', false),
  (51, 'ลำพูน', 'Lamphun', 'north', false),
  (52, 'ลำปาง', 'Lampang', 'north', false),
  (53, 'อุตรดิตถ์', 'Uttaradit', 'north', false),
  (54, 'แพร่', 'Phrae', 'north', false),
  (55, 'น่าน', 'Nan', 'north', false),
  (56, 'พะเยา', 'Phayao', 'north', false),
  (57, 'เชียงราย', 'Chiang Rai', 'north', false),
  (58, 'แม่ฮ่องสอน', 'Mae Hong Son', 'north', false),
  (60, 'นครสวรรค์', 'Nakhon Sawan', 'north', false),
  (61, 'อุทัยธานี', 'Uthai Thani', 'north', false),
  (62, 'กำแพงเพชร', 'Kamphaeng Phet', 'north', false),
  (63, 'ตาก', 'Tak', 'west', false),
  (64, 'สุโขทัย', 'Sukhothai', 'north', false),
  (65, 'พิษณุโลก', 'Phitsanulok', 'north', false),
  (66, 'พิจิตร', 'Phichit', 'north', false),
  (67, 'เพชรบูรณ์', 'Phetchabun', 'north', false),
  (70, 'ราชบุรี', 'Ratchaburi', 'west', false),
  (71, 'กาญจนบุรี', 'Kanchanaburi', 'west', false),
  (72, 'สุพรรณบุรี', 'Suphan Buri', 'central', false),
  (73, 'นครปฐม', 'Nakhon Pathom', 'central', false),
  (74, 'สมุทรสาคร', 'Samut Sakhon', 'central', false),
  (75, 'สมุทรสงคราม', 'Samut Songkhram', 'central', false),
  (76, 'เพชรบุรี', 'Phetchaburi', 'west', false),
  (77, 'ประจวบคีรีขันธ์', 'Prachuap Khiri Khan', 'west', false),
  (80, 'นครศรีธรรมราช', 'Nakhon Si Thammarat', 'south', false),
  (81, 'กระบี่', 'Krabi', 'south', false),
  (82, 'พังงา', 'Phang Nga', 'south', false),
  (83, 'ภูเก็ต', 'Phuket', 'south', false),
  (84, 'สุราษฎร์ธานี', 'Surat Thani', 'south', false),
  (85, 'ระนอง', 'Ranong', 'south', false),
  (86, 'ชุมพร', 'Chumphon', 'south', false),
  (90, 'สงขลา', 'Songkhla', 'south', false),
  (91, 'สตูล', 'Satun', 'south', false),
  (92, 'ตรัง', 'Trang', 'south', false),
  (93, 'พัทลุง', 'Phatthalung', 'south', false),
  (94, 'ปัตตานี', 'Pattani', 'south', false),
  (95, 'ยะลา', 'Yala', 'south', false),
  (96, 'นราธิวาส', 'Narathiwat', 'south', false);

insert into secondhand.shipping_partners (code, name_th, name_en, sort_order) values
  ('flash', 'แฟลช เอ็กซ์เพรส', 'Flash Express', 10),
  ('thailand_post', 'ไปรษณีย์ไทย', 'Thailand Post', 20),
  ('kex', 'เคอรี่ (KEX)', 'KEX Express', 30),
  ('jt', 'เจแอนด์ที', 'J&T Express', 40);

insert into secondhand.shipping_options
  (code, partner_code, name_th, name_en, service_type, estimated_days_min, estimated_days_max, sort_order) values
  ('flash_standard', 'flash', 'Flash Express มาตรฐาน', 'Flash Express Standard', 'express', 1, 3, 10),
  ('thailand_post_ems', 'thailand_post', 'ไปรษณีย์ไทย EMS', 'Thailand Post EMS', 'ems', 1, 3, 20),
  ('thailand_post_registered', 'thailand_post', 'ไปรษณีย์ไทย ลงทะเบียน', 'Thailand Post Registered', 'registered', 3, 5, 30),
  ('kex_standard', 'kex', 'KEX มาตรฐาน', 'KEX Standard', 'express', 1, 3, 40),
  ('jt_standard', 'jt', 'J&T มาตรฐาน', 'J&T Standard', 'express', 2, 3, 50);

insert into secondhand.shipping_rates (option_code, zone, max_weight_g, max_size_cm, fee, reference_source) values
  -- Flash: published drop-off table + 3 THB fuel surcharge from 2026-04-01.
  ('flash_standard', 'bangkok_metro', 1000, 40, 28, 'Flash drop-off table + 3 THB (2026-04-01)'),
  ('flash_standard', 'upcountry', 1000, 40, 38, 'Flash drop-off table + 3 THB (2026-04-01)'),
  ('flash_standard', 'bangkok_metro', 3000, 60, 38, 'Flash drop-off table + 3 THB (2026-04-01)'),
  ('flash_standard', 'upcountry', 3000, 60, 48, 'Flash drop-off table + 3 THB (2026-04-01)'),
  ('flash_standard', 'bangkok_metro', 5000, 80, 58, 'Flash drop-off table + 3 THB (2026-04-01)'),
  ('flash_standard', 'upcountry', 5000, 80, 63, 'Flash drop-off table + 3 THB (2026-04-01)'),
  ('flash_standard', 'bangkok_metro', 10000, 105, 118, 'Flash drop-off table + 3 THB (2026-04-01)'),
  ('flash_standard', 'upcountry', 10000, 105, 118, 'Flash drop-off table + 3 THB (2026-04-01)'),
  -- Thailand Post EMS: official domestic table (nationwide), max 120 cm.
  ('thailand_post_ems', 'bangkok_metro', 250, 120, 42, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'upcountry', 250, 120, 42, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'bangkok_metro', 500, 120, 52, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'upcountry', 500, 120, 52, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'bangkok_metro', 1000, 120, 67, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'upcountry', 1000, 120, 67, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'bangkok_metro', 2000, 120, 97, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'upcountry', 2000, 120, 97, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'bangkok_metro', 3000, 120, 105, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'upcountry', 3000, 120, 105, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'bangkok_metro', 5000, 120, 120, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'upcountry', 5000, 120, 120, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'bangkok_metro', 10000, 120, 220, 'Thailand Post EMS domestic rate PDF'),
  ('thailand_post_ems', 'upcountry', 10000, 120, 220, 'Thailand Post EMS domestic rate PDF'),
  -- Thailand Post registered: published retail table (nationwide), up to 2 kg.
  ('thailand_post_registered', 'bangkok_metro', 250, null, 22, 'Thailand Post registered retail table'),
  ('thailand_post_registered', 'upcountry', 250, null, 22, 'Thailand Post registered retail table'),
  ('thailand_post_registered', 'bangkok_metro', 500, null, 28, 'Thailand Post registered retail table'),
  ('thailand_post_registered', 'upcountry', 500, null, 28, 'Thailand Post registered retail table'),
  ('thailand_post_registered', 'bangkok_metro', 1000, null, 38, 'Thailand Post registered retail table'),
  ('thailand_post_registered', 'upcountry', 1000, null, 38, 'Thailand Post registered retail table'),
  ('thailand_post_registered', 'bangkok_metro', 2000, null, 58, 'Thailand Post registered retail table'),
  ('thailand_post_registered', 'upcountry', 2000, null, 58, 'Thailand Post registered retail table'),
  -- KEX and J&T: indicative 2026 market ranges (metro = low, upcountry = high).
  ('kex_standard', 'bangkok_metro', 1000, null, 35, 'Indicative 2026 range; confirm with KEX'),
  ('kex_standard', 'upcountry', 1000, null, 45, 'Indicative 2026 range; confirm with KEX'),
  ('kex_standard', 'bangkok_metro', 3000, null, 45, 'Indicative 2026 range; confirm with KEX'),
  ('kex_standard', 'upcountry', 3000, null, 60, 'Indicative 2026 range; confirm with KEX'),
  ('kex_standard', 'bangkok_metro', 5000, null, 60, 'Indicative 2026 range; confirm with KEX'),
  ('kex_standard', 'upcountry', 5000, null, 85, 'Indicative 2026 range; confirm with KEX'),
  ('jt_standard', 'bangkok_metro', 1000, null, 29, 'Indicative 2026 range; confirm with J&T'),
  ('jt_standard', 'upcountry', 1000, null, 39, 'Indicative 2026 range; confirm with J&T'),
  ('jt_standard', 'bangkok_metro', 3000, null, 39, 'Indicative 2026 range; confirm with J&T'),
  ('jt_standard', 'upcountry', 3000, null, 55, 'Indicative 2026 range; confirm with J&T'),
  ('jt_standard', 'bangkok_metro', 5000, null, 55, 'Indicative 2026 range; confirm with J&T'),
  ('jt_standard', 'upcountry', 5000, null, 75, 'Indicative 2026 range; confirm with J&T');
