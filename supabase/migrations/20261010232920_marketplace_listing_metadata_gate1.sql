alter table public.products
  add column if not exists currency text not null default 'THB',
  add column if not exists handling_time_days smallint not null default 3,
  add column if not exists shipping_method text not null default 'standard_included';
do $$ begin
  if not exists (select 1 from pg_constraint where conname='products_currency_thb_check' and conrelid='public.products'::regclass) then alter table public.products add constraint products_currency_thb_check check (currency='THB'); end if;
  if not exists (select 1 from pg_constraint where conname='products_handling_time_days_check' and conrelid='public.products'::regclass) then alter table public.products add constraint products_handling_time_days_check check (handling_time_days between 1 and 14); end if;
  if not exists (select 1 from pg_constraint where conname='products_shipping_method_check' and conrelid='public.products'::regclass) then alter table public.products add constraint products_shipping_method_check check (shipping_method in ('standard_included','remote_surcharge','international_buyer')); end if;
end $$;
create index if not exists idx_marketplace_active_products_created on public.products (created_at desc) where status='active' and is_active=true and stock>0;
insert into public.categories (name,slug,icon,sort_order,is_active)
select seed.name,seed.slug,seed.icon,seed.sort_order,true
from (values
('โทรศัพท์และแท็บเล็ต','phones-tablets','smartphone',10),('คอมพิวเตอร์และอุปกรณ์','computers','computer',20),
('กล้องและอุปกรณ์ถ่ายภาพ','cameras','photo_camera',30),('เกมและของสะสม','games-collectibles','sports_esports',40),
('บ้านและเครื่องใช้ไฟฟ้า','home-appliances','chair',50),('แฟชั่นและเครื่องประดับ','fashion','checkroom',60),
('กีฬาและกิจกรรมกลางแจ้ง','sports-outdoor','hiking',70),('รถยนต์และมอเตอร์ไซค์','vehicles','directions_car',80),
('งานอดิเรกและของสะสม','hobbies-collectibles','interests',90),('อื่น ๆ','other','category',100)
) as seed(name,slug,icon,sort_order)
where not exists (select 1 from public.categories c where c.slug=seed.slug);
comment on column public.products.currency is 'Marketplace display currency. Gate 1 is THB only.';
comment on column public.products.handling_time_days is 'Seller preparation time before dispatch, 1-14 days.';
comment on column public.products.shipping_method is 'Marketplace shipping policy.';;
