grant select (id,name,slug,icon,image_url,description,sort_order,is_active)
  on public.categories to anon,authenticated;
grant select (id,shop_name,shop_slug,description,logo_url,banner_url,province,district,seller_level,
  trust_score,follower_count,product_count,is_verified,shop_status)
  on public.shops to anon,authenticated;
grant select (owner_id) on public.shops to authenticated;
grant select (id,shop_id,category_id,title,slug,description,condition_level,price,stock,status,is_active,
  view_count,favorite_count,created_at,updated_at,product_code,currency,handling_time_days,shipping_method)
  on public.products to anon,authenticated;
grant select (id,product_id,image_url,image_order,is_cover,created_at)
  on public.product_images to anon,authenticated;
