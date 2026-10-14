-- R46: drop empty legacy tables from the first marketplace schema.
-- Each table has no rows, no grant to anon or authenticated, and no function, view, policy, realtime publication
-- or app code that uses it. Kept on purpose: tables referenced by live foreign keys (chat_quick_replies, devices,
-- organization_roles, payment_methods, product_variants) and tables listed by the account closure checks (api_keys, cancel_requests,
-- commission, invoice, order_items, organization_delegations, receipt, refund_requests, return_requests, tax_records).
-- One statement without cascade: any dependency outside this list stops the migration.

-- Refuse to drop a table that has gained rows since the audit.
do $$
declare
  t text;
  n bigint;
begin
  foreach t in array array[
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
    'ai_embeddings', 'ai_logs', 'ai_prompts', 'ai_training'] loop
    execute format('select count(*) from public.%I', t) into n;
    if n > 0 then
      raise exception 'R46 stopped: public.% has % rows', t, n;
    end if;
  end loop;
end $$;

drop table
  -- Legacy shop catalogue, cart and social features (Secondhand has no cart; listings, reviews and reports live in secondhand.*)
  public.carts,
  public.cart_items,
  public.variant_images,
  public.inventory_logs,
  public.product_attributes,
  public.product_attribute_values,
  public.product_tags,
  public.product_tag_relations,
  public.tags,
  public.brands,
  public.price_history,
  public.product_statistics,
  public.product_views,
  public.product_comments,
  public.comment_images,
  public.comment_likes,
  public.comment_reports,
  public.product_reports,
  public.reviews,
  public.review_images,
  public.seller_levels,
  public.seller_statistics,
  public.sales_statistics,
  public.shop_announcements,
  -- Legacy disputes, payments, shipping and promotions (replaced by secondhand order issues, escrow and shipping options)
  public.dispute_files,
  public.dispute_logs,
  public.dispute_messages,
  public.payment_logs,
  public.shipments,
  public.shipment_tracking,
  public.shipping_methods,
  public.shipping_rates,
  public.shipping_addresses,
  public.coupons,
  public.coupon_usage,
  public.promotions,
  public.promotion_products,
  public.flash_sales,
  public.currencies,
  -- Legacy content, support, search and logging (replaced by system_contents, activity_logs and the Admin Hub plan)
  public.announcements,
  public.faq,
  public.help_articles,
  public.pages,
  public.page_views,
  public.media_files,
  public.media_folders,
  public.media_tags,
  public.notification_templates,
  public.support_tickets,
  public.support_messages,
  public.ticket_files,
  public.system_settings,
  public.user_preferences,
  public.saved_searches,
  public.search_history,
  public.search_keywords,
  public.popular_searches,
  public.analytics_events,
  public.audit_logs,
  public.login_history,
  public.webhooks,
  public.reports,
  public.verification_history,
  public.chat_message_attachments,
  public.chat_read_logs,
  public.organization_role_permissions,
  -- Unused AI scaffolding
  public.ai_embeddings,
  public.ai_logs,
  public.ai_prompts,
  public.ai_training;
