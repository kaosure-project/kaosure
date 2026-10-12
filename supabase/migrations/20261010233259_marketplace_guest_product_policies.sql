drop policy if exists "Users can view products" on public.products;
drop policy if exists "Users can view product images" on public.product_images;
create policy marketplace_guest_read_active_products on public.products for select to anon using (
 status='active' and is_active=true and stock>0
 and exists(select 1 from public.shops s where s.id=products.shop_id and s.shop_status='active')
 and exists(select 1 from public.categories c where c.id=products.category_id and c.is_active=true));
create policy marketplace_member_read_active_or_own_products on public.products for select to authenticated using (
 (status='active' and is_active=true and stock>0
  and exists(select 1 from public.shops s where s.id=products.shop_id and s.shop_status='active')
  and exists(select 1 from public.categories c where c.id=products.category_id and c.is_active=true))
 or ((select kaoid_private.account_active_r9f()) and exists(
  select 1 from public.shops s where s.id=products.shop_id and s.owner_id=(select auth.uid()))));
create policy marketplace_guest_read_active_product_images on public.product_images for select to anon using (exists(
 select 1 from public.products p join public.shops s on s.id=p.shop_id join public.categories c on c.id=p.category_id
 where p.id=product_images.product_id and p.status='active' and p.is_active=true and p.stock>0
 and s.shop_status='active' and c.is_active=true));
create policy marketplace_member_read_active_or_own_product_images on public.product_images for select to authenticated using (
 exists(select 1 from public.products p join public.shops s on s.id=p.shop_id join public.categories c on c.id=p.category_id
  where p.id=product_images.product_id and p.status='active' and p.is_active=true and p.stock>0
  and s.shop_status='active' and c.is_active=true)
 or ((select kaoid_private.account_active_r9f()) and exists(
  select 1 from public.products p join public.shops s on s.id=p.shop_id
  where p.id=product_images.product_id and s.owner_id=(select auth.uid()))));
;
