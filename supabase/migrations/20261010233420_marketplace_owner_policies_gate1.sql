drop policy if exists "Users can update products" on public.products;
create policy marketplace_owner_update_products on public.products for update to authenticated
 using ((select kaoid_private.account_active_r9f()) and exists(
  select 1 from public.shops s where s.id=products.shop_id and s.owner_id=(select auth.uid())))
 with check ((select kaoid_private.account_active_r9f()) and exists(
  select 1 from public.shops s where s.id=products.shop_id and s.owner_id=(select auth.uid())));
drop policy if exists "Users can update own shop" on public.shops;
create policy marketplace_owner_update_shop on public.shops for update to authenticated
 using ((select kaoid_private.account_active_r9f()) and owner_id=(select auth.uid()))
 with check ((select kaoid_private.account_active_r9f()) and owner_id=(select auth.uid()));
drop policy if exists "Users can upload product images" on public.product_images;
create policy marketplace_owner_insert_product_images on public.product_images for insert to authenticated
 with check ((select kaoid_private.account_active_r9f()) and exists(
  select 1 from public.products p join public.shops s on s.id=p.shop_id
  where p.id=product_images.product_id and s.owner_id=(select auth.uid())));
drop policy if exists "Users can update product images" on public.product_images;
create policy marketplace_owner_update_product_images on public.product_images for update to authenticated
 using ((select kaoid_private.account_active_r9f()) and exists(
  select 1 from public.products p join public.shops s on s.id=p.shop_id
  where p.id=product_images.product_id and s.owner_id=(select auth.uid())))
 with check ((select kaoid_private.account_active_r9f()) and exists(
  select 1 from public.products p join public.shops s on s.id=p.shop_id
  where p.id=product_images.product_id and s.owner_id=(select auth.uid())));

drop policy if exists "Users can create favorites" on public.favorites;
drop policy if exists "Users can delete favorites" on public.favorites;
drop policy if exists "Users can view favorites" on public.favorites;
create policy marketplace_owner_read_favorites on public.favorites for select to authenticated
 using ((select kaoid_private.account_active_r9f()) and profile_id=(select auth.uid()));
create policy marketplace_owner_create_favorites on public.favorites for insert to authenticated
 with check ((select kaoid_private.account_active_r9f()) and profile_id=(select auth.uid())
 and exists(select 1 from public.products p join public.shops s on s.id=p.shop_id
  where p.id=favorites.product_id and p.status='active' and p.is_active=true and p.stock>0 and s.shop_status='active'));
create policy marketplace_owner_delete_favorites on public.favorites for delete to authenticated
 using ((select kaoid_private.account_active_r9f()) and profile_id=(select auth.uid()));

drop policy if exists "Authenticated users can view own follows" on public.followers;
drop policy if exists "Users can follow shops" on public.followers;
drop policy if exists "Users can unfollow shops" on public.followers;
create policy marketplace_owner_read_follows on public.followers for select to authenticated
 using ((select kaoid_private.account_active_r9f()) and profile_id=(select auth.uid()));
create policy marketplace_owner_create_follows on public.followers for insert to authenticated
 with check ((select kaoid_private.account_active_r9f()) and profile_id=(select auth.uid())
 and exists(select 1 from public.shops s where s.id=followers.shop_id and s.shop_status='active'));
create policy marketplace_owner_delete_follows on public.followers for delete to authenticated
 using ((select kaoid_private.account_active_r9f()) and profile_id=(select auth.uid()));;
