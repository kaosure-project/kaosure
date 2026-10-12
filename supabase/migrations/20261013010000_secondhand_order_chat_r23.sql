-- R23: transaction chat (取引メッセージ) between the buyer and the seller of
-- one Secondhand order.
--
--   * A room opens when the order is paid (the seller is not part of an
--     unpaid order) and closes when the order completes or is cancelled;
--     closed rooms stay readable.
--   * Members never touch the chat tables: everything goes through
--     get_order_chat, send_order_message and mark_order_chat_read.
--   * Sending is refused when the members block each other, when the text
--     carries contact details or a way to pay outside KaoSure (phone or
--     account numbers, e-mail, LINE, links, PromptPay), and above 10
--     messages a minute. Resending with the same client id returns the first
--     message instead of a copy.
--   * The other member is notified once per batch of unread messages.

-- ---------------------------------------------------------------------------
-- Indexes for reading a room in order and for idempotent sends
-- ---------------------------------------------------------------------------
create index if not exists chat_messages_room_seq_r23 on public.chat_messages(room_id, sequence_number desc);
create unique index if not exists chat_messages_client_r23 on public.chat_messages(room_id, sender_id, client_message_id);
create index if not exists chat_messages_sender_recent_r23 on public.chat_messages(sender_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Rooms follow the order
-- ---------------------------------------------------------------------------
create or replace function secondhand.order_chat_room_r23()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (select 1 from secondhand.order_details d where d.order_id = new.id) then
    return null;
  end if;
  if new.order_status = 'paid' then
    insert into public.chat_rooms(order_id, buyer_id, seller_id, product_id, shop_id, room_status)
    values (new.id, new.buyer_id, new.seller_id, new.product_id, new.shop_id, 'active')
    on conflict (order_id) do nothing;
  elsif new.order_status in ('completed', 'cancelled', 'refunded') then
    update public.chat_rooms
       set room_status = 'closed', closed_at = coalesce(closed_at, now()), updated_at = now()
     where order_id = new.id and room_status <> 'closed';
  end if;
  return null;
end $$;

revoke all on function secondhand.order_chat_room_r23() from public, anon, authenticated;

create trigger orders_chat_room_r23
after update of order_status on public.orders
for each row
when (old.order_status is distinct from new.order_status)
execute function secondhand.order_chat_room_r23();

-- ---------------------------------------------------------------------------
-- Contact details and off-platform payment
-- ---------------------------------------------------------------------------
create or replace function secondhand.chat_contact_info_r23(p_text text)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v text := lower(translate(coalesce(p_text, ''),
                            '๐๑๒๓๔๕๖๗๘๙０１２３４５６７８９＠：．',
                            '0123456789' || '0123456789' || '@:.'));
begin
  return
    -- 9+ digits in a row, spaces, dots, dashes or brackets between them allowed:
    -- phone, bank account or PromptPay numbers.
    v ~ '\d([\s.\-()]*\d){8,}'
    or v ~ '[a-z0-9._%+\-]+@[a-z0-9\-]+(\.[a-z0-9\-]+)*\.[a-z]{2,}'
    or v ~ '(https?://|www\.|line\.me|lin\.ee|facebook\.com|fb\.com|fb\.me|m\.me|wa\.me|t\.me|instagram\.com|tiktok\.com)'
    or v ~ '(line|ไลน์|ไลน)\s*(id|ไอดี)?\s*[:@]'
    or v ~ '(ไอดีไลน์|ไลน์ไอดี|แอดไลน์|แอดไลน|add\s*line|line\s*id)'
    or v ~ '(พร้อมเพย์|พร้อมเพ|promptpay|prompt\s*pay|เลขบัญชี|เลขที่บัญชี)';
end $$;

revoke all on function secondhand.chat_contact_info_r23(text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Reads
-- ---------------------------------------------------------------------------
create or replace function secondhand.order_chat_room_for_r23(p_order_id uuid, p_viewer uuid)
returns public.chat_rooms
language sql
stable
security definer
set search_path = ''
as $$
  select r.* from public.chat_rooms r
    join public.orders o on o.id = r.order_id
    join secondhand.order_details d on d.order_id = o.id
   where r.order_id = p_order_id and p_viewer in (r.buyer_id, r.seller_id)
$$;

revoke all on function secondhand.order_chat_room_for_r23(uuid, uuid) from public, anon, authenticated;

create or replace function secondhand.get_order_chat(
  p_order_id uuid, p_before bigint default null, p_limit integer default 30
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_room public.chat_rooms;
  v_status text;
  v_limit integer := least(greatest(coalesce(p_limit, 30), 1), 100);
  v_items jsonb;
  v_more boolean;
  v_other uuid;
begin
  v_room := secondhand.order_chat_room_for_r23(p_order_id, u);
  if v_room.id is null then
    if exists (select 1 from public.orders o where o.id = p_order_id and o.buyer_id = u) then
      return jsonb_build_object('open', false, 'can_send', false, 'closed_reason', 'not_paid',
                                'messages', '[]'::jsonb, 'has_more', false, 'unread', 0);
    end if;
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  v_other := case when u = v_room.buyer_id then v_room.seller_id else v_room.buyer_id end;
  select o.order_status into v_status from public.orders o where o.id = p_order_id;

  select coalesce(jsonb_agg(jsonb_build_object(
           'id', m.id,
           'seq', m.sequence_number,
           'mine', m.sender_id = u,
           'body', case when m.is_hidden or m.is_recalled then null else m.message end,
           'hidden', m.is_hidden or m.is_recalled,
           'read', m.is_read,
           'created_at', m.created_at) order by m.sequence_number desc), '[]'::jsonb)
    into v_items
    from (select * from public.chat_messages x
           where x.room_id = v_room.id and (p_before is null or x.sequence_number < p_before)
           order by x.sequence_number desc
           limit v_limit + 1) m;
  v_more := jsonb_array_length(v_items) > v_limit;
  if v_more then
    v_items := v_items - v_limit;
  end if;

  return jsonb_build_object(
    'open', v_room.room_status <> 'closed' and v_status in ('paid', 'shipped'),
    'can_send', v_room.room_status <> 'closed' and v_status in ('paid', 'shipped')
                and not secondhand.blocked_between_r21b(u, v_other),
    'closed_reason', case
      when v_room.room_status = 'closed' or v_status not in ('paid', 'shipped') then 'order_closed'
      when secondhand.blocked_between_r21b(u, v_other) then 'member_blocked' end,
    'unread', case when u = v_room.buyer_id then v_room.buyer_unread_count else v_room.seller_unread_count end,
    'messages', v_items,
    'has_more', v_more);
end $$;

-- ---------------------------------------------------------------------------
-- Send
-- ---------------------------------------------------------------------------
create or replace function secondhand.send_order_message(p_order_id uuid, p_body text, p_client_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_room public.chat_rooms;
  v_status text;
  v_order_number text;
  v_body text := btrim(coalesce(p_body, ''));
  v_other uuid;
  v_other_unread integer;
  v_msg public.chat_messages;
begin
  select r.* into v_room from public.chat_rooms r
   where r.id = (secondhand.order_chat_room_for_r23(p_order_id, u)).id
   for update;
  if v_room.id is null then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  if p_client_id is null then
    raise exception 'invalid_message' using errcode = '22023';
  end if;

  -- The same client id again: the first send went through.
  select * into v_msg from public.chat_messages m
   where m.room_id = v_room.id and m.sender_id = u and m.client_message_id = p_client_id;
  if found then
    return jsonb_build_object('id', v_msg.id, 'seq', v_msg.sequence_number, 'created_at', v_msg.created_at);
  end if;

  select o.order_status, o.order_number into v_status, v_order_number from public.orders o where o.id = p_order_id;
  if v_room.room_status = 'closed' or v_status not in ('paid', 'shipped') then
    raise exception 'chat_closed' using errcode = '22023';
  end if;
  v_other := case when u = v_room.buyer_id then v_room.seller_id else v_room.buyer_id end;
  if secondhand.blocked_between_r21b(u, v_other) then
    raise exception 'member_blocked' using errcode = '42501';
  end if;
  if char_length(v_body) = 0 or char_length(v_body) > 1000 then
    raise exception 'invalid_message' using errcode = '22023';
  end if;
  if secondhand.chat_contact_info_r23(v_body) then
    raise exception 'contact_info_not_allowed' using errcode = '22023';
  end if;
  if (select count(*) from public.chat_messages m
       where m.sender_id = u and m.created_at > now() - interval '1 minute') >= 10 then
    raise exception 'too_many_messages' using errcode = '22023';
  end if;

  insert into public.chat_messages(room_id, sender_id, client_message_id, sequence_number, message_type, message,
                                   source)
  values (v_room.id, u, p_client_id, v_room.message_count + 1, 'text', v_body, 'secondhand')
  returning * into v_msg;

  v_other_unread := case when v_other = v_room.buyer_id then v_room.buyer_unread_count
                         else v_room.seller_unread_count end;
  update public.chat_rooms
     set message_count = message_count + 1,
         buyer_unread_count = buyer_unread_count + case when v_other = buyer_id then 1 else 0 end,
         seller_unread_count = seller_unread_count + case when v_other = seller_id then 1 else 0 end,
         last_sender_id = u, last_message_preview = left(v_body, 80), last_message_at = v_msg.created_at,
         updated_at = now()
   where id = v_room.id;

  -- One notification per batch: only when the other member had nothing unread.
  if v_other_unread = 0 then
    insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
    values (v_other, 'ข้อความใหม่จาก' || case when u = v_room.buyer_id then 'ผู้ซื้อ' else 'ผู้ขาย' end,
            'คำสั่งซื้อ ' || v_order_number || ': ' || left(v_body, 60),
            'order_message', p_order_id, '/orders/' || p_order_id,
            'order_message:' || v_msg.id || ':' || v_other);
  end if;

  return jsonb_build_object('id', v_msg.id, 'seq', v_msg.sequence_number, 'created_at', v_msg.created_at);
end $$;

-- ---------------------------------------------------------------------------
-- Read
-- ---------------------------------------------------------------------------
create or replace function secondhand.mark_order_chat_read(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_room public.chat_rooms;
  n integer;
begin
  select r.* into v_room from public.chat_rooms r
   where r.id = (secondhand.order_chat_room_for_r23(p_order_id, u)).id
   for update;
  if v_room.id is null then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  update public.chat_messages
     set is_read = true, read_at = now(), updated_at = now()
   where room_id = v_room.id and sender_id <> u and not is_read;
  get diagnostics n = row_count;
  update public.chat_rooms
     set buyer_unread_count = case when u = buyer_id then 0 else buyer_unread_count end,
         seller_unread_count = case when u = seller_id then 0 else seller_unread_count end,
         updated_at = now()
   where id = v_room.id;
  update public.notifications
     set is_read = true
   where profile_id = u and notification_type = 'order_message' and target_id = p_order_id
     and not coalesce(is_read, false);
  return jsonb_build_object('read', n);
end $$;

-- ---------------------------------------------------------------------------
-- Orders carry the viewer's unread message count
-- ---------------------------------------------------------------------------
create or replace function secondhand.order_json_r22(p_order_id uuid, p_viewer uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
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
    'marketplace_fee', case when p_viewer = o.seller_id then o.marketplace_fee end,
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
    'product', jsonb_build_object(
      'id', p.id, 'title', p.title,
      'image_path', (select i.image_url from public.product_images i where i.product_id = p.id
                      order by i.is_cover desc, i.image_order limit 1)),
    'counterpart', jsonb_build_object(
      'display_name', secondhand.member_name_r22(case when p_viewer = o.buyer_id then o.seller_id else o.buyer_id end),
      'avatar_url', m.avatar_url,
      'shop_id', case when p_viewer = o.buyer_id then o.shop_id
                      else (select s.id from public.shops s where s.owner_id = o.buyer_id
                              and s.seller_identity_type = 'personal' and s.shop_status = 'active'
                            order by s.created_at limit 1) end),
    'address', case when p_viewer = o.buyer_id or o.order_status in ('paid', 'shipped', 'completed') then d.address end,
    'reviewed', exists (select 1 from secondhand.reviews r where r.order_id = o.id and r.reviewer_id = p_viewer),
    'unread_messages', coalesce((select case when p_viewer = c.buyer_id then c.buyer_unread_count
                                             else c.seller_unread_count end
                                   from public.chat_rooms c where c.order_id = o.id), 0))
  from public.orders o
  join secondhand.order_details d on d.order_id = o.id
  join public.products p on p.id = o.product_id
  left join secondhand.member_profiles m
    on m.profile_id = case when p_viewer = o.buyer_id then o.seller_id else o.buyer_id end
  where o.id = p_order_id
    and (p_viewer = o.buyer_id or (p_viewer = o.seller_id and o.paid_at is not null))
$$;

-- ---------------------------------------------------------------------------
-- Grants and the Secondhand token scope
-- ---------------------------------------------------------------------------
revoke all on function secondhand.get_order_chat(uuid, bigint, integer) from public, anon, authenticated;
revoke all on function secondhand.send_order_message(uuid, text, uuid) from public, anon, authenticated;
revoke all on function secondhand.mark_order_chat_read(uuid) from public, anon, authenticated;
grant execute on function secondhand.get_order_chat(uuid, bigint, integer) to authenticated;
grant execute on function secondhand.send_order_message(uuid, text, uuid) to authenticated;
grant execute on function secondhand.mark_order_chat_read(uuid) to authenticated;

update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
                              'secondhand.get_order_chat', 'secondhand.send_order_message',
                              'secondhand.mark_order_chat_read']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
