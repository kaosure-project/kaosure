-- Secondhand member center: narrowly expose read access to the shared Kao ID
-- wallet and member-owned orders. Existing RLS policies continue to restrict
-- each row to its owner/participants. No wallet write privilege is granted.

grant select (
  id,
  profile_id,
  balance,
  hold_balance,
  currency,
  wallet_status,
  created_at,
  updated_at
) on public.wallets to authenticated;

grant select (
  id,
  wallet_id,
  order_id,
  transaction_type,
  amount,
  balance_before,
  balance_after,
  description,
  transaction_status,
  created_at,
  updated_at,
  platform_id
) on public.wallet_transactions to authenticated;

grant select (
  id,
  order_number,
  product_id,
  buyer_id,
  seller_id,
  shop_id,
  product_price,
  shipping_fee,
  discount_amount,
  marketplace_fee,
  total_amount,
  payment_status,
  order_status,
  escrow_status,
  tracking_number,
  shipping_company,
  paid_at,
  shipped_at,
  delivered_at,
  completed_at,
  cancelled_at,
  cancel_reason,
  created_at,
  updated_at,
  platform_id
) on public.orders to authenticated;

-- Members may only mark their own notifications as read. Column-level grants
-- prevent changing ownership, message content, event type, or target.
grant update (is_read, read_at) on public.notifications to authenticated;
