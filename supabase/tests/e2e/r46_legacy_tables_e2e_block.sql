-- R46 checks. Appended after the migration inside one transaction that never commits.
do $$
declare
  shop uuid := (select id from public.shops where shop_status = 'active' order by created_at limit 1);
  member uuid := (select owner_id from public.shops where shop_status = 'active' order by created_at limit 1);
  member_session uuid := gen_random_uuid();
  dropped text[] := array[
    'carts', 'cart_items', 'variant_images', 'inventory_logs', 'product_attributes',
    'product_attribute_values', 'product_tags', 'product_tag_relations', 'tags', 'brands', 'price_history',
    'product_statistics', 'product_views', 'product_comments', 'comment_images', 'comment_likes', 'comment_reports',
    'product_reports', 'reviews', 'review_images', 'seller_levels', 'seller_statistics', 'sales_statistics',
    'shop_announcements', 'dispute_files', 'dispute_logs', 'dispute_messages', 'payment_logs', 'shipments',
    'shipment_tracking', 'shipping_methods', 'shipping_rates', 'shipping_addresses', 'coupons', 'coupon_usage',
    'promotions', 'promotion_products', 'flash_sales', 'currencies', 'announcements', 'faq', 'help_articles', 'pages',
    'page_views', 'media_files', 'media_folders', 'media_tags', 'notification_templates', 'support_tickets',
    'support_messages', 'ticket_files', 'system_settings', 'user_preferences', 'saved_searches', 'search_history',
    'search_keywords', 'popular_searches', 'analytics_events', 'audit_logs', 'login_history', 'webhooks', 'reports',
    'verification_history', 'chat_message_attachments', 'chat_read_logs', 'organization_role_permissions',
    'ai_embeddings', 'ai_logs', 'ai_prompts', 'ai_training'];
  kept text[] := array[
    'chat_quick_replies', 'devices', 'organization_roles', 'payment_methods', 'product_variants', 'api_keys', 'cancel_requests',
    'commission', 'invoice', 'order_items', 'organization_delegations', 'receipt', 'refund_requests',
    'return_requests', 'tax_records', 'disputes', 'orders', 'wallets', 'escrow_transactions', 'banners',
    'activity_logs', 'brain_projects', 'pudtan_memory'];
  report text := '';
  j jsonb;
  step text;
begin
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (member_session, member, now(), now(), 'aal1');

  foreach step in array array['dropped', 'kept', 'invalid_functions', 'closure_blockers', 'member_my_page',
      'member_orders', 'member_wallet', 'guest_shop_page', 'guest_listing', 'staff_tools'] loop
    begin
      report := report || step || ': ';
      perform set_config('request.jwt.claims', json_build_object('sub', member, 'role', 'authenticated',
        'session_id', member_session, 'aal', 'aal1', 'is_anonymous', false)::text, true);

      case step
        when 'dropped' then
          report := report || 'still_there=' || (select count(*) from unnest(dropped) t
            where to_regclass('public.' || t) is not null) || '/' || cardinality(dropped);
        when 'kept' then
          report := report || 'missing=' || coalesce((select string_agg(t, ',') from unnest(kept) t
            where to_regclass('public.' || t) is null), 'none');
        when 'invalid_functions' then
          report := report || 'functions_naming_dropped=' || (select count(*) from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            where n.nspname not in ('pg_catalog', 'information_schema')
              and exists (select 1 from unnest(dropped) t where p.prosrc ~* ('public\.' || t || '\M')));
        when 'closure_blockers' then
          j := kaoid_private.closure_blockers_r10d(member);
          report := report || 'ok blockers=' || jsonb_array_length(j);
        when 'member_my_page' then
          perform set_config('role', 'authenticated', true);
          report := report || 'ok=' || (secondhand.get_my_page() is not null);
        when 'member_orders' then
          perform set_config('role', 'authenticated', true);
          report := report || 'ok=' || (secondhand.list_my_orders('buyer', null, 10, null) is not null);
        when 'member_wallet' then
          perform set_config('role', 'authenticated', true);
          report := report || 'ok=' || (secondhand.get_withdrawal_info(null) is not null);
        when 'guest_shop_page' then
          perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
          perform set_config('role', 'anon', true);
          report := report || 'profile=' || (secondhand.get_shop_profile(shop) is not null)
            || ' items=' || (secondhand.list_shop_items(shop, 'selling', 'newest', null, 10) is not null)
            || ' reviews=' || (secondhand.list_member_reviews(shop, null, null, null, 10) is not null);
        when 'guest_listing' then
          perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
          perform set_config('role', 'anon', true);
          report := report || 'ok=' || (secondhand.get_listing_detail(
            (select id from public.products where shop_id = shop order by created_at limit 1)) is not null);
        when 'staff_tools' then
          perform set_config('role', 'authenticated', true);
          report := report || 'ok=' || (kaoid_private.staff_tools_r24() is not null);
      end case;
      perform set_config('role', 'postgres', true);
      report := report || ' | ';
    exception when others then
      perform set_config('role', 'postgres', true);
      report := report || 'ERR ' || sqlstate || ' ' || sqlerrm || ' | ';
    end;
  end loop;
  raise exception 'E2E_REPORT %', report;
end $$;
