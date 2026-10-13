-- R32: the order page tells each viewer what they may do for the shop, so a team member never sees a button the
-- server would refuse.
--   * can_manage: the seller side with the shop's 'orders' permission (ship, cancel, review the buyer). Always
--     false for the buyer.
--   * can_chat: the buyer, or the seller side with the shop's 'chat' permission (the order chat).
-- Same rules as mark_shipped, cancel_order, submit_review and order_chat_room_for_r23. No data changes.

create or replace function secondhand.order_json_r22(p_order_id uuid, p_viewer uuid)
returns jsonb
language sql
stable security definer
set search_path to ''
as $$
  select jsonb_build_object(
    'id', o.id,
    'order_number', o.order_number,
    'role', case when p_viewer = o.buyer_id then 'buyer' else 'seller' end,
    'status', o.order_status,
    'payment_method', d.payment_method,
    'price', o.product_price,
    'shipping_fee', o.shipping_fee,
    'total', o.total_amount,
    'marketplace_fee', case when p_viewer <> o.buyer_id then o.marketplace_fee end,
    'created_at', o.created_at,
    'paid_at', o.paid_at,
    'shipped_at', o.shipped_at,
    'completed_at', o.completed_at,
    'cancelled_at', o.cancelled_at,
    'cancelled_by', d.cancelled_by,
    'cancel_reason', o.cancel_reason,
    'pay_by', d.pay_by,
    'ship_by', d.ship_by,
    'receive_by', d.receive_by,
    'carrier', o.shipping_company,
    'tracking_number', o.tracking_number,
    'offer_applied', d.offer_id is not null,
    'shop_id', o.shop_id,
    'product', jsonb_build_object(
      'id', p.id, 'title', p.title,
      'image_path', (select i.image_url from public.product_images i where i.product_id = p.id
                      order by i.is_cover desc, i.image_order limit 1)),
    'counterpart', jsonb_build_object(
      'display_name', case when p_viewer = o.buyer_id and sh.seller_identity_type = 'business' then sh.shop_name
                           else secondhand.member_name_r22(case when p_viewer = o.buyer_id then o.seller_id
                                                                else o.buyer_id end) end,
      'avatar_url', case when p_viewer = o.buyer_id and sh.seller_identity_type = 'business' then null
                         else m.avatar_url end,
      'shop_id', case when p_viewer = o.buyer_id then o.shop_id
                      else (select s.id from public.shops s where s.owner_id = o.buyer_id
                              and s.seller_identity_type = 'personal' and s.shop_status = 'active'
                            order by s.created_at limit 1) end),
    'address', case when p_viewer = o.buyer_id or o.order_status in ('paid', 'shipped', 'completed') then d.address end,
    'reviewed', exists (select 1 from secondhand.reviews r
                         where r.order_id = o.id
                           and r.reviewer_id = case when p_viewer = o.buyer_id then o.buyer_id else o.seller_id end),
    'unread_messages', coalesce((select case when p_viewer = c.buyer_id then c.buyer_unread_count
                                             else c.seller_unread_count end
                                   from public.chat_rooms c where c.order_id = o.id), 0),
    'issue', (select secondhand.order_issue_json_r26(x) from secondhand.order_issues x
               where x.order_id = o.id order by x.created_at desc limit 1),
    'can_cancel', secondhand.can_cancel_order_r26(o, d, p_viewer),
    'can_open_issue', secondhand.can_open_order_issue_r26(o, p_viewer),
    'can_manage', p_viewer <> o.buyer_id and secondhand.shop_can_r27(o.shop_id, 'orders', p_viewer),
    'can_chat', p_viewer = o.buyer_id or secondhand.shop_can_r27(o.shop_id, 'chat', p_viewer))
  from public.orders o
  join secondhand.order_details d on d.order_id = o.id
  join public.products p on p.id = o.product_id
  join public.shops sh on sh.id = o.shop_id
  left join secondhand.member_profiles m
    on m.profile_id = case when p_viewer = o.buyer_id then o.seller_id else o.buyer_id end
  where o.id = p_order_id
    and (p_viewer = o.buyer_id
         or (o.paid_at is not null
             and (secondhand.shop_can_r27(o.shop_id, 'orders', p_viewer)
                  or secondhand.shop_can_r27(o.shop_id, 'chat', p_viewer))))
$$;
