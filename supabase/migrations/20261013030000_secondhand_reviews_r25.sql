-- R25: receiving with a review, preset comments from the CMS, review
-- notifications, and reports with moderation in the Kao ID Admin Hub.
--
-- Receiving (Yahoo! Flea Market)
--   * The buyer confirms receipt and rates the seller in one step
--     (receive_and_review). The order completes and escrow releases the sale
--     minus the sales fee to the seller's wallet at once (complete_order_r22;
--     mock payments still move no money). The seller then rates the buyer.
--   * The auto-receipt 7 days after shipping is unchanged; the buyer can still
--     rate afterwards. confirm_received() is no longer callable by members.
--
-- Reviews
--   * "ดี" may add one preset comment and free text. "ไม่ดี" has no presets and
--     needs a written reason. Reviews stay permanent.
--   * Presets live in public.system_contents (category 'preset', meta.role
--     buyer / seller / any = whose review form shows them). The preset text is
--     copied into the review so later CMS edits never change a sent review.
--     secondhand.review_presets stays retired (R21f).
--   * The reviewee is notified; whoever has not rated 3 days after completion
--     gets one reminder.
--
-- Moderation
--   * Members report a visible review once each. Staff with
--     marketplace.reviews.moderate hide or restore it from the Admin Hub, with
--     a fresh MFA, an activity log entry and notifications to the reviewer and
--     reporters. Hidden reviews drop out of every score (member_ratings).

-- ---------------------------------------------------------------------------
-- Permission
-- ---------------------------------------------------------------------------
insert into public.permissions
  (category, resource, action, code, name, description, scope, sort_order,
   is_active, is_dangerous, is_immutable, is_deprecated)
values
  ('Marketplace', 'reviews', 'moderate', 'marketplace.reviews.moderate', 'Marketplace Reviews Moderate',
   'Review reported member reviews and hide or restore them.', 'global', 330,
   true, false, false, false)
on conflict (code) do update
set is_active = true, is_deprecated = false, updated_at = now();

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
  from public.admin_roles r
 cross join public.permissions p
 where r.code in ('admin', 'super_admin') and r.is_active
   and p.code = 'marketplace.reviews.moderate' and p.is_active
   and not exists (select 1 from public.role_permissions rp where rp.role_id = r.id and rp.permission_id = p.id);

-- ---------------------------------------------------------------------------
-- System contents: preset comments
-- ---------------------------------------------------------------------------
alter table public.system_contents drop constraint system_contents_category_check;
alter table public.system_contents add constraint system_contents_category_check
  check (category in ('help', 'guide', 'rule', 'warning', 'terms', 'notice', 'preset'));

create or replace function kaoid_private.content_save_r24(
  p_id uuid, p_key text, p_app text, p_category text, p_title jsonb, p_body jsonb, p_meta jsonb,
  p_sort integer, p_active boolean, p_version integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
  v_row public.system_contents;
  v_title jsonb;
  v_body jsonb;
  v_meta jsonb := coalesce(p_meta, '{}');
begin
  if not kaoid_private.staff_permission_r24('content.system.manage') then
    raise exception 'content_access_denied' using errcode = '42501';
  end if;
  v_title := kaoid_private.content_text_r24(p_title, 200);
  v_body := kaoid_private.content_text_r24(p_body, 20000);
  if jsonb_typeof(v_meta) <> 'object' or char_length(v_meta::text) > 2000 then
    raise exception 'invalid_content' using errcode = '22023';
  end if;
  if p_category is null or p_category not in ('help', 'guide', 'rule', 'warning', 'terms', 'notice', 'preset')
     or p_active is null or coalesce(p_sort, 0) not between -100000 and 100000 then
    raise exception 'invalid_content' using errcode = '22023';
  end if;
  -- A preset is a short review comment; meta.role says whose form shows it.
  if p_category = 'preset' and (coalesce(v_meta->>'role', '') not in ('buyer', 'seller', 'any')
                                or char_length(v_body->>'th') > 300 or char_length(coalesce(v_body->>'en', '')) > 300) then
    raise exception 'invalid_content' using errcode = '22023';
  end if;

  if p_id is null then
    if p_key is null or p_key !~ '^[a-z0-9_]+(\.[a-z0-9_]+)+$' or char_length(p_key) > 120
       or p_app is null or p_app !~ '^[a-z][a-z0-9_]{1,39}$' then
      raise exception 'invalid_content_key' using errcode = '22023';
    end if;
    begin
      insert into public.system_contents(content_key, app_code, category, title, body, meta, sort_order, is_active,
                                         created_by, updated_by)
      values (p_key, p_app, p_category, v_title, v_body, v_meta, coalesce(p_sort, 0), p_active, u, u)
      returning * into v_row;
    exception when unique_violation then
      raise exception 'content_key_taken' using errcode = '23505';
    end;
    insert into public.system_content_revisions(content_id, content_key, version, change_kind, snapshot, changed_by)
    values (v_row.id, v_row.content_key, v_row.version, 'create', kaoid_private.content_json_r24(v_row, false), u);
  else
    select * into v_row from public.system_contents c where c.id = p_id for update;
    if not found then
      raise exception 'content_not_found' using errcode = '22023';
    end if;
    if p_version is distinct from v_row.version then
      raise exception 'content_changed' using errcode = '40001';
    end if;
    if p_key is distinct from v_row.content_key or p_app is distinct from v_row.app_code then
      raise exception 'content_key_locked' using errcode = '22023';
    end if;
    update public.system_contents
       set category = p_category, title = v_title, body = v_body, meta = v_meta, sort_order = coalesce(p_sort, 0),
           is_active = p_active, version = version + 1, updated_by = u, updated_at = now()
     where id = p_id
    returning * into v_row;
    insert into public.system_content_revisions(content_id, content_key, version, change_kind, snapshot, changed_by)
    values (v_row.id, v_row.content_key, v_row.version, 'update', kaoid_private.content_json_r24(v_row, false), u);
  end if;

  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'content.system.save', 'system_contents', v_row.id, v_row.content_key || ' v' || v_row.version);
  return kaoid_private.content_json_r24(v_row, true);
end $$;

-- ---------------------------------------------------------------------------
-- Reviews: presets, written reasons, moderation
-- ---------------------------------------------------------------------------
alter table secondhand.reviews
  drop constraint reviews_no_preset_r21f,
  drop constraint reviews_preset_code_fkey,
  add column preset_text jsonb,
  add column hidden_at timestamptz,
  add column hidden_by uuid references public.profiles(id) on delete set null,
  add column hidden_reason text check (char_length(hidden_reason) <= 500),
  add constraint reviews_preset_r25 check ((preset_code is null) = (preset_text is null)
                                           and (preset_code is null or verdict = 'good')),
  add constraint reviews_bad_reason_r25 check (verdict = 'good' or char_length(btrim(coalesce(comment, ''))) >= 5);

-- Only moderation may change a review, and only whether it is shown.
create or replace function secondhand.review_permanent_r21f()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (new.order_id, new.reviewer_id, new.reviewee_id, new.reviewer_role, new.verdict, new.comment,
      new.preset_code, new.preset_text, new.reply, new.replied_at, new.created_at)
     is distinct from
     (old.order_id, old.reviewer_id, old.reviewee_id, old.reviewer_role, old.verdict, old.comment,
      old.preset_code, old.preset_text, old.reply, old.replied_at, old.created_at) then
    raise exception 'review_permanent' using errcode = '42501';
  end if;
  return new;
end $$;

create table secondhand.review_reports (
  id uuid primary key default gen_random_uuid(),
  review_id uuid not null references secondhand.reviews(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (reason in ('abusive', 'personal_info', 'false_info', 'spam', 'other')),
  detail text check (char_length(detail) <= 500),
  report_status text not null default 'pending' check (report_status in ('pending', 'upheld', 'dismissed')),
  resolved_by uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  unique (review_id, reporter_id)
);
create index review_reports_pending_r25 on secondhand.review_reports(review_id) where report_status = 'pending';
create index review_reports_reporter_r25 on secondhand.review_reports(reporter_id, created_at desc);

alter table secondhand.review_reports enable row level security;
revoke all on table secondhand.review_reports from public, anon, authenticated;
grant all on table secondhand.review_reports to service_role;

-- ---------------------------------------------------------------------------
-- Writing a review
-- ---------------------------------------------------------------------------
-- An active preset of Secondhand that the given side's form shows, or null.
create or replace function secondhand.review_preset_r25(p_key text, p_role text)
returns public.system_contents
language sql
stable
security definer
set search_path = ''
as $$
  select c.* from public.system_contents c
   where c.content_key = p_key and c.app_code = 'secondhand' and c.category = 'preset' and c.is_active
     and c.meta->>'role' in (p_role, 'any');
$$;

create or replace function secondhand.write_review_r25(
  p_actor uuid, p_order_id uuid, p_verdict text, p_comment text, p_preset text)
returns secondhand.reviews
language plpgsql
security definer
set search_path = ''
as $$
declare
  o public.orders;
  v_comment text := nullif(btrim(coalesce(p_comment, '')), '');
  v_role text;
  v_preset public.system_contents;
  v_review secondhand.reviews;
begin
  select * into o from public.orders where id = p_order_id;
  if not found or p_actor not in (o.buyer_id, o.seller_id) then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  if p_verdict is null or p_verdict not in ('good', 'bad') or char_length(coalesce(v_comment, '')) > 1000 then
    raise exception 'invalid_review' using errcode = '22023';
  end if;
  v_role := case when p_actor = o.buyer_id then 'buyer' else 'seller' end;
  if p_verdict = 'bad' and (p_preset is not null or char_length(coalesce(v_comment, '')) < 5) then
    raise exception 'review_reason_required' using errcode = '22023';
  end if;
  if p_preset is not null then
    v_preset := secondhand.review_preset_r25(p_preset, v_role);
    if v_preset.id is null then
      raise exception 'invalid_preset' using errcode = '22023';
    end if;
  end if;

  insert into secondhand.reviews(order_id, reviewer_id, reviewee_id, reviewer_role, verdict, comment,
                                 preset_code, preset_text)
  values (p_order_id, p_actor, case when v_role = 'buyer' then o.seller_id else o.buyer_id end, v_role, p_verdict,
          v_comment, v_preset.content_key, v_preset.body)
  on conflict (order_id, reviewer_id) do nothing
  returning * into v_review;
  if v_review.id is null then
    raise exception 'review_already_sent' using errcode = '23505';
  end if;

  insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (v_review.reviewee_id,
          kaoid_private.content_message_r24('secondhand.notice.review_received', 'title', null, 'คุณได้รับรีวิวแล้ว'),
          kaoid_private.content_message_r24('secondhand.notice.review_received', 'body',
            jsonb_build_object('name', secondhand.member_name_r22(p_actor), 'order', o.order_number,
                               'verdict', case p_verdict when 'good' then 'ดี' else 'ไม่ดี' end),
            '{name} ประเมินคุณว่า "{verdict}" จากคำสั่งซื้อ {order}'),
          'review_received', p_order_id, '/orders/' || p_order_id, 'review_received:' || v_review.id);
  return v_review;
end $$;

-- After completion either side rates the other once (the seller rates the buyer here).
drop function secondhand.submit_review(uuid, text, text);

create or replace function secondhand.submit_review(
  p_order_id uuid, p_verdict text, p_comment text default null, p_preset text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
  o public.orders;
  v_review secondhand.reviews;
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if coalesce(kaoid_private.account_access_r10d()->>'state', '') <> 'active' then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  select * into o from public.orders where id = p_order_id;
  if not found or u not in (o.buyer_id, o.seller_id) then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  if o.completed_at is null and coalesce(o.order_status, '') <> 'completed' then
    raise exception 'order_not_completed' using errcode = '22023';
  end if;
  v_review := secondhand.write_review_r25(u, p_order_id, p_verdict, p_comment, p_preset);
  return jsonb_build_object('id', v_review.id, 'reviewer_role', v_review.reviewer_role, 'verdict', v_review.verdict);
end $$;

-- "ได้รับสินค้าแล้ว": the buyer's review and the receipt in one step.
create or replace function secondhand.receive_and_review(
  p_order_id uuid, p_verdict text, p_comment text default null, p_preset text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  o public.orders;
begin
  select * into o from public.orders where id = p_order_id and buyer_id = u for update;
  if not found then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  if o.order_status <> 'shipped' then
    raise exception 'order_not_receivable' using errcode = '22023';
  end if;
  perform secondhand.write_review_r25(u, p_order_id, p_verdict, p_comment, p_preset);
  perform secondhand.complete_order_r22(p_order_id, u);
  return jsonb_build_object('order_id', p_order_id, 'status', 'completed', 'verdict', p_verdict);
end $$;

-- ---------------------------------------------------------------------------
-- Completion: escrow release with messages from the CMS
-- ---------------------------------------------------------------------------
create or replace function secondhand.complete_order_r22(p_order_id uuid, p_actor uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
  v_details secondhand.order_details;
  v_wallet public.wallets;
  v_net numeric;
  v_values jsonb;
  v_buyer_key text;
begin
  select * into strict v_order from public.orders o where o.id = p_order_id for update;
  select * into strict v_details from secondhand.order_details d where d.order_id = p_order_id for update;
  if v_order.order_status <> 'shipped' then
    raise exception 'order_not_receivable' using errcode = '22023';
  end if;

  -- The commission trigger sets marketplace_fee on completion.
  update public.orders
     set order_status = 'completed', escrow_status = 'released', delivered_at = coalesce(delivered_at, now()),
         completed_at = now(), updated_at = now()
   where id = p_order_id
  returning * into v_order;
  v_net := greatest(v_order.total_amount - v_order.marketplace_fee, 0);

  update public.escrow_transactions set escrow_status = 'released', released_at = now() where id = v_details.escrow_id;

  if v_details.payment_method = 'wallet' then
    select * into strict v_wallet from public.wallets w where w.profile_id = v_order.seller_id for update;
    update public.wallets set balance = balance + v_net, updated_at = now() where id = v_wallet.id;
    insert into public.wallet_transactions(wallet_id, order_id, transaction_type, amount, balance_before,
                                           balance_after, description)
    values (v_wallet.id, v_order.id, 'sale', v_net, v_wallet.balance, v_wallet.balance + v_net,
            'รายได้จากการขาย ' || v_order.order_number);
  end if;
  insert into public.payment_transactions(escrow_id, receiver_wallet_id, transaction_type, amount, status,
                                          reference_no, note, processed_at)
  select v_details.escrow_id,
         case when v_details.payment_method = 'wallet'
              then (select w.id from public.wallets w where w.profile_id = v_order.seller_id) end,
         x.kind, x.amount, 'completed', v_order.order_number,
         case when v_details.payment_method = 'mock' then 'mock: no money moved' else 'wallet' end, now()
    from (values ('release', v_net), ('fee', v_order.marketplace_fee)) x(kind, amount)
   where x.amount > 0 or x.kind = 'release';

  perform secondhand.order_log_r22(p_order_id, p_actor, 'shipped', 'completed', 'completed',
                                   case when p_actor is null then 'auto' end);
  perform secondhand.order_log_r22(p_order_id, p_actor, 'completed', 'completed', 'escrow_released',
                                   v_details.payment_method);

  v_values := jsonb_build_object('order', v_order.order_number,
                                 'net', to_char(v_net, 'FM999,999,990.00'),
                                 'fee', to_char(v_order.marketplace_fee, 'FM999,999,990.00'));
  perform secondhand.order_notify_r22(v_order.seller_id, p_order_id, 'completed',
    kaoid_private.content_message_r24('secondhand.notice.order_completed_seller', 'title', null,
                                      'การซื้อขายเสร็จสมบูรณ์'),
    case when v_details.payment_method = 'mock'
         then kaoid_private.content_message_r24('secondhand.notice.order_completed_seller_mock', 'body', v_values,
                'คำสั่งซื้อ {order}: ชำระแบบจำลอง จึงไม่มีเงินเข้ากระเป๋า กรุณาประเมินผู้ซื้อ')
         else kaoid_private.content_message_r24('secondhand.notice.order_completed_seller', 'body', v_values,
                'คำสั่งซื้อ {order}: โอนรายได้สุทธิ ฿{net} เข้ากระเป๋าแล้ว (หักค่าธรรมเนียม ฿{fee}) กรุณาประเมินผู้ซื้อ')
    end);
  v_buyer_key := case when exists (select 1 from secondhand.reviews r
                                    where r.order_id = p_order_id and r.reviewer_id = v_order.buyer_id)
                      then 'secondhand.notice.order_completed_buyer'
                      else 'secondhand.notice.order_auto_received_buyer' end;
  perform secondhand.order_notify_r22(v_order.buyer_id, p_order_id, 'completed',
    kaoid_private.content_message_r24(v_buyer_key, 'title', null, 'การซื้อขายเสร็จสมบูรณ์'),
    kaoid_private.content_message_r24(v_buyer_key, 'body', v_values,
      case when v_buyer_key = 'secondhand.notice.order_completed_buyer'
           then 'คำสั่งซื้อ {order} เสร็จสมบูรณ์ ขอบคุณที่ประเมินผู้ขาย'
           else 'คำสั่งซื้อ {order}: ระบบยืนยันรับสินค้าให้อัตโนมัติแล้ว อย่าลืมประเมินผู้ขาย' end));
end $$;

-- ---------------------------------------------------------------------------
-- Reminders: once, 3 days after completion, to whoever has not rated
-- ---------------------------------------------------------------------------
create or replace function secondhand.run_review_reminders_r25()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  n integer;
begin
  insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
  select x.profile_id,
         kaoid_private.content_message_r24('secondhand.notice.review_reminder', 'title', null, 'รอให้คะแนน'),
         kaoid_private.content_message_r24('secondhand.notice.review_reminder', 'body',
           jsonb_build_object('order', x.order_number, 'side', case x.side when 'buyer' then 'ผู้ขาย' else 'ผู้ซื้อ' end),
           'คำสั่งซื้อ {order}: อย่าลืมประเมิน{side}'),
         'review_reminder', x.order_id, '/orders/' || x.order_id, 'review_reminder:' || x.order_id || ':' || x.profile_id
    from (select o.id as order_id, o.order_number, s.profile_id, s.side
            from public.orders o
            join secondhand.order_details d on d.order_id = o.id
           cross join lateral (values (o.buyer_id, 'buyer'), (o.seller_id, 'seller')) s(profile_id, side)
           where o.order_status = 'completed'
             and o.completed_at <= now() - interval '3 days'
             and o.completed_at > now() - interval '30 days'
             and not exists (select 1 from secondhand.reviews r where r.order_id = o.id and r.reviewer_id = s.profile_id)
         ) x
  on conflict (event_key) where event_key is not null do nothing;
  get diagnostics n = row_count;
  return n;
end $$;

select cron.schedule('secondhand-review-reminders-r25', '0 2 * * *', 'select secondhand.run_review_reminders_r25();');

-- ---------------------------------------------------------------------------
-- Member reads
-- ---------------------------------------------------------------------------
-- "รอให้คะแนน": completed orders the signed-in member has not rated yet.
create or replace function secondhand.list_orders_to_review(p_before timestamptz default null,
                                                            p_limit integer default 20)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_items jsonb;
  v_more boolean;
begin
  select coalesce(jsonb_agg(secondhand.order_json_r22(x.id, u) order by x.completed_at desc, x.id desc), '[]'::jsonb)
    into v_items
    from (select o.id, o.completed_at from public.orders o
           where u in (o.buyer_id, o.seller_id)
             and o.order_status = 'completed' and o.completed_at is not null
             and exists (select 1 from secondhand.order_details d where d.order_id = o.id)
             and not exists (select 1 from secondhand.reviews r where r.order_id = o.id and r.reviewer_id = u)
             and (p_before is null or o.completed_at < p_before)
           order by o.completed_at desc, o.id desc
           limit v_limit + 1) x;
  v_more := jsonb_array_length(v_items) > v_limit;
  if v_more then
    v_items := v_items - v_limit;
  end if;
  return jsonb_build_object('orders', v_items, 'has_more', v_more);
end $$;

-- Review page: ทั้งหมด / ดี / ไม่ดี, with the preset text and whether the viewer may report.
create or replace function secondhand.list_member_reviews(
  p_shop_id uuid default null,
  p_verdict text default null,
  p_before timestamptz default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := case when coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then null else auth.uid() end;
  v_profile uuid;
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_items jsonb;
  v_more boolean;
begin
  if p_verdict is not null and p_verdict not in ('good', 'bad') then
    raise exception 'invalid_filter' using errcode = '22023';
  end if;
  if p_shop_id is null then
    v_profile := u;
    if v_profile is null then
      raise exception 'Authentication required' using errcode = '42501';
    end if;
  else
    select s.owner_id into v_profile
      from public.shops s
     where s.id = p_shop_id and s.seller_identity_type = 'personal';
    if v_profile is null then
      raise exception 'Shop not found' using errcode = '22023';
    end if;
  end if;

  select coalesce(jsonb_agg(x.item order by x.created_at desc, x.id desc), '[]'::jsonb) into v_items
    from (
      select r.id, r.created_at, jsonb_build_object(
               'id', r.id,
               'verdict', r.verdict,
               'comment', r.comment,
               'preset_text', r.preset_text,
               'reviewer_role', r.reviewer_role,
               'created_at', r.created_at,
               'reported', u is not null and exists (select 1 from secondhand.review_reports rr
                                                      where rr.review_id = r.id and rr.reporter_id = u),
               'can_report', u is not null and u <> r.reviewer_id,
               'reviewer', jsonb_build_object(
                 'display_name', coalesce(nullif(btrim(m.display_name), ''), secondhand.kao_id_name_r21c(r.reviewer_id)),
                 'avatar_url', m.avatar_url,
                 'shop_id', (select s.id from public.shops s
                              where s.owner_id = r.reviewer_id and s.seller_identity_type = 'personal'
                                and s.shop_status = 'active'
                              order by s.created_at limit 1))) as item
        from secondhand.reviews r
        left join secondhand.member_profiles m on m.profile_id = r.reviewer_id
       where r.reviewee_id = v_profile and r.is_visible
         and (p_verdict is null or r.verdict = p_verdict)
         and (p_before is null or r.created_at < p_before)
       order by r.created_at desc, r.id desc
       limit v_limit + 1
    ) x;

  v_more := jsonb_array_length(v_items) > v_limit;
  if v_more then
    v_items := v_items - v_limit;
  end if;

  return (
    select jsonb_build_object(
      'review_count', coalesce(mr.review_count, 0),
      'good_count', coalesce(mr.good_count, 0),
      'bad_count', coalesce(mr.bad_count, 0),
      'rating', mr.rating,
      'reviews', v_items,
      'has_more', v_more)
      from (select 1) one
      left join secondhand.member_ratings mr on mr.profile_id = v_profile);
end $$;

-- ---------------------------------------------------------------------------
-- Reporting a review
-- ---------------------------------------------------------------------------
create or replace function secondhand.report_review(p_review_id uuid, p_reason text, p_detail text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
  v_detail text := nullif(btrim(coalesce(p_detail, '')), '');
  r secondhand.reviews;
  v_id uuid;
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if coalesce(kaoid_private.account_access_r10d()->>'state', '') <> 'active' then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  if p_reason is null or p_reason not in ('abusive', 'personal_info', 'false_info', 'spam', 'other')
     or char_length(coalesce(v_detail, '')) > 500 or (p_reason = 'other' and char_length(coalesce(v_detail, '')) < 5) then
    raise exception 'invalid_report' using errcode = '22023';
  end if;
  select * into r from secondhand.reviews where id = p_review_id and is_visible;
  if not found then
    raise exception 'review_not_found' using errcode = '22023';
  end if;
  if r.reviewer_id = u then
    raise exception 'own_review' using errcode = '22023';
  end if;
  if (select count(*) from secondhand.review_reports rr
       where rr.reporter_id = u and rr.created_at > now() - interval '1 day') >= 20 then
    raise exception 'report_limit' using errcode = '22023';
  end if;
  insert into secondhand.review_reports(review_id, reporter_id, reason, detail)
  values (p_review_id, u, p_reason, v_detail)
  on conflict (review_id, reporter_id) do nothing
  returning id into v_id;
  if v_id is null then
    raise exception 'review_already_reported' using errcode = '23505';
  end if;
  return jsonb_build_object('id', v_id, 'status', 'pending');
end $$;

-- ---------------------------------------------------------------------------
-- Moderation: staff (Kao ID Admin Hub)
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.review_staff_r25()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not kaoid_private.staff_permission_r24('marketplace.reviews.moderate') then
    raise exception 'review_access_denied' using errcode = '42501';
  end if;
  return auth.uid();
end $$;

create or replace function kaoid_private.review_member_json_r25(p_profile uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', p_profile,
    'display_name', secondhand.member_name_r22(p_profile),
    'account_code', (select a.account_code from kaoid_private.account_refs_r10c a where a.profile_id = p_profile));
$$;

create or replace function kaoid_private.review_staff_json_r25(r secondhand.reviews)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', r.id,
    'order_id', r.order_id,
    'order_number', (select o.order_number from public.orders o where o.id = r.order_id),
    'verdict', r.verdict,
    'comment', r.comment,
    'preset_text', r.preset_text,
    'reviewer_role', r.reviewer_role,
    'created_at', r.created_at,
    'is_visible', r.is_visible,
    'hidden_at', r.hidden_at,
    'hidden_reason', r.hidden_reason,
    'hidden_by_name', (select p.display_name from public.profiles p where p.id = r.hidden_by),
    'reviewer', kaoid_private.review_member_json_r25(r.reviewer_id),
    'reviewee', kaoid_private.review_member_json_r25(r.reviewee_id),
    'pending_reports', (select count(*) from secondhand.review_reports rr
                         where rr.review_id = r.id and rr.report_status = 'pending'),
    'total_reports', (select count(*) from secondhand.review_reports rr where rr.review_id = r.id),
    'last_reported_at', (select max(rr.created_at) from secondhand.review_reports rr where rr.review_id = r.id),
    'reasons', (select coalesce(jsonb_object_agg(x.reason, x.n), '{}'::jsonb)
                  from (select rr.reason, count(*) as n from secondhand.review_reports rr
                         where rr.review_id = r.id and rr.report_status = 'pending'
                         group by rr.reason) x));
$$;

-- reported: waiting reports first; hidden: newest hidden first; recent: every review, newest first.
create or replace function kaoid_private.review_queue_r25(p_filter text, p_before timestamptz)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform kaoid_private.review_staff_r25();
  if p_filter is null or p_filter not in ('reported', 'hidden', 'recent') then
    raise exception 'invalid_filter' using errcode = '22023';
  end if;
  return (
    select coalesce(jsonb_agg(kaoid_private.review_staff_json_r25(x.r) || jsonb_build_object('sort_at', x.sort_at)
                              order by x.sort_at desc, (x.r).id desc), '[]')
      from (select r, s.sort_at
              from secondhand.reviews r
             cross join lateral (select case p_filter
                       when 'reported' then (select max(rr.created_at) from secondhand.review_reports rr
                                              where rr.review_id = r.id and rr.report_status = 'pending')
                       when 'hidden' then r.hidden_at
                       else r.created_at end as sort_at) s
             where s.sort_at is not null
               and (p_filter <> 'hidden' or not r.is_visible)
               and (p_before is null or s.sort_at < p_before)
             order by s.sort_at desc, r.id desc
             limit 30) x);
end $$;

create or replace function kaoid_private.review_detail_r25(p_review_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  r secondhand.reviews;
begin
  perform kaoid_private.review_staff_r25();
  select * into r from secondhand.reviews where id = p_review_id;
  if not found then
    raise exception 'review_not_found' using errcode = '22023';
  end if;
  return kaoid_private.review_staff_json_r25(r) || jsonb_build_object(
    'reports', (select coalesce(jsonb_agg(jsonb_build_object(
                  'id', rr.id, 'reason', rr.reason, 'detail', rr.detail, 'status', rr.report_status,
                  'created_at', rr.created_at, 'resolved_at', rr.resolved_at,
                  'reporter', kaoid_private.review_member_json_r25(rr.reporter_id))
                  order by rr.created_at desc), '[]')
                  from secondhand.review_reports rr where rr.review_id = r.id));
end $$;

-- Hides (p_hide) or shows a review and settles its waiting reports.
create or replace function kaoid_private.review_moderate_r25(p_review_id uuid, p_hide boolean, p_note text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := kaoid_private.review_staff_r25();
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
  r secondhand.reviews;
  v_was_visible boolean;
  v_order text;
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if p_hide is null or char_length(coalesce(v_note, '')) > 500 then
    raise exception 'invalid_decision' using errcode = '22023';
  end if;
  if p_hide and char_length(coalesce(v_note, '')) < 3 then
    raise exception 'note_required' using errcode = '22023';
  end if;
  select * into r from secondhand.reviews where id = p_review_id for update;
  if not found then
    raise exception 'review_not_found' using errcode = '22023';
  end if;
  if u in (r.reviewer_id, r.reviewee_id) then
    raise exception 'own_review' using errcode = '42501';
  end if;
  v_was_visible := r.is_visible;
  select o.order_number into v_order from public.orders o where o.id = r.order_id;

  if p_hide then
    if v_was_visible then
      update secondhand.reviews
         set is_visible = false, hidden_at = now(), hidden_by = u, hidden_reason = v_note, updated_at = now()
       where id = r.id
      returning * into r;
    end if;
  elsif not v_was_visible then
    update secondhand.reviews
       set is_visible = true, hidden_at = null, hidden_by = null, hidden_reason = null, updated_at = now()
     where id = r.id
    returning * into r;
  end if;

  insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
  select rr.reporter_id,
         kaoid_private.content_message_r24(x.key, 'title', null, x.title),
         kaoid_private.content_message_r24(x.key, 'body', jsonb_build_object('order', v_order), x.body),
         'review_report', r.id, null, 'review_report:' || rr.id || ':' || x.status
    from secondhand.review_reports rr
   cross join (select case when p_hide then 'secondhand.notice.review_report_upheld'
                           else 'secondhand.notice.review_report_dismissed' end as key,
                      case when p_hide then 'upheld' else 'dismissed' end as status,
                      case when p_hide then 'ซ่อนรีวิวที่คุณรายงานแล้ว' else 'ตรวจสอบรีวิวที่คุณรายงานแล้ว' end as title,
                      case when p_hide then 'ทีมงานซ่อนรีวิวจากคำสั่งซื้อ {order} ตามที่คุณรายงานแล้ว ขอบคุณค่ะ'
                           else 'ทีมงานตรวจสอบแล้ว รีวิวจากคำสั่งซื้อ {order} ไม่ผิดกติกา จึงยังแสดงอยู่' end as body) x
   where rr.review_id = r.id and rr.report_status = 'pending'
  on conflict (event_key) where event_key is not null do nothing;
  update secondhand.review_reports
     set report_status = case when p_hide then 'upheld' else 'dismissed' end, resolved_by = u, resolved_at = now()
   where review_id = r.id and report_status = 'pending';

  if v_was_visible is distinct from r.is_visible then
    insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
    values (r.reviewer_id,
            kaoid_private.content_message_r24(
              case when p_hide then 'secondhand.notice.review_hidden' else 'secondhand.notice.review_restored' end,
              'title', null, case when p_hide then 'รีวิวของคุณถูกซ่อน' else 'รีวิวของคุณแสดงอีกครั้ง' end),
            kaoid_private.content_message_r24(
              case when p_hide then 'secondhand.notice.review_hidden' else 'secondhand.notice.review_restored' end,
              'body', jsonb_build_object('order', v_order, 'reason', coalesce(v_note, '')),
              case when p_hide then 'รีวิวจากคำสั่งซื้อ {order} ถูกซ่อนเพราะไม่เป็นไปตามกติกา: {reason}'
                   else 'รีวิวจากคำสั่งซื้อ {order} กลับมาแสดงแล้วหลังทีมงานตรวจสอบ' end),
            case when p_hide then 'review_hidden' else 'review_restored' end, r.order_id, null,
            'review_moderated:' || r.id || ':' || extract(epoch from now())::bigint || ':' || r.is_visible);
  end if;

  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, case when p_hide then 'marketplace.review.hide' else 'marketplace.review.show' end, 'reviews', r.id,
          coalesce(v_note, case when p_hide then 'hidden' else 'shown' end));
  return kaoid_private.review_staff_json_r25(r);
end $$;

-- Which Admin Hub tools the signed-in staff member can open.
create or replace function kaoid_private.staff_tools_r24()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_withdrawals boolean := kaoid_private.staff_permission_r24('wallet.withdraw.approve');
  v_contents boolean := kaoid_private.staff_permission_r24('content.system.manage');
  v_reviews boolean := kaoid_private.staff_permission_r24('marketplace.reviews.moderate');
begin
  return jsonb_build_object(
    'withdrawals', v_withdrawals,
    'contents', v_contents,
    'reviews', v_reviews,
    'pending_withdrawals', case when v_withdrawals then
      (select count(*) from public.withdraw_requests r where r.withdraw_status = 'pending') end,
    'pending_review_reports', case when v_reviews then
      (select count(distinct rr.review_id) from secondhand.review_reports rr where rr.report_status = 'pending') end);
end $$;

create or replace function public.review_queue_r25(p_filter text default 'reported', p_before timestamptz default null)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.review_queue_r25(p_filter, p_before); $$;
create or replace function public.review_detail_r25(p_review_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.review_detail_r25(p_review_id); $$;
create or replace function public.review_moderate_r25(p_review_id uuid, p_hide boolean, p_note text default null)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.review_moderate_r25(p_review_id, p_hide, p_note); $$;

-- ---------------------------------------------------------------------------
-- Seed contents (Thai and English). Staff edit them from the Admin Hub.
-- ---------------------------------------------------------------------------
insert into public.system_contents(content_key, app_code, category, title, body, meta, sort_order) values
  ('secondhand.review.rules', 'secondhand', 'rule',
   jsonb_build_object('th', $c$กติกาการประเมิน$c$, 'en', $c$Review rules$c$),
   jsonb_build_object('th', $c$ประเมินได้ครั้งเดียวต่อคำสั่งซื้อ และแก้ไขหรือลบไม่ได้หลังส่ง
เลือก "ดี" หรือ "ไม่ดี" ตามประสบการณ์จริงในการซื้อขายครั้งนี้
ถ้าเลือก "ไม่ดี" ต้องเขียนเหตุผลด้วยตัวเอง
ห้ามใส่ข้อมูลส่วนตัว เบอร์โทร ช่องทางติดต่อภายนอก หรือถ้อยคำไม่สุภาพ
รีวิวที่ผิดกติกาอาจถูกซ่อนโดยทีมงาน KaoSure$c$,
                      'en', $c$You can review each order once, and a sent review can't be edited or deleted.
Choose "Good" or "Bad" based on this deal only.
If you choose "Bad", write the reason yourself.
Don't include personal details, phone numbers, outside contacts or rude words.
Reviews that break these rules may be hidden by the KaoSure team.$c$),
   '{"icon": "gavel"}', 300),
  ('secondhand.review.receive_guide', 'secondhand', 'guide',
   jsonb_build_object('th', $c$ก่อนกดได้รับสินค้า$c$, 'en', $c$Before confirming receipt$c$),
   jsonb_build_object('th', $c$ตรวจสอบสินค้าให้เรียบร้อยก่อนกดยืนยัน
เมื่อยืนยัน ระบบจะโอนเงินสุทธิเข้า KaoSure Wallet ของผู้ขายทันที และยกเลิกคำสั่งซื้อไม่ได้อีก
ถ้าสินค้ามีปัญหา ให้คุยกับผู้ขายในแชตคำสั่งซื้อก่อนกดยืนยัน$c$,
                      'en', $c$Check the item carefully before you confirm.
Once confirmed, the seller's earnings go to their KaoSure Wallet at once and the order can't be cancelled.
If something is wrong, talk to the seller in the order chat before confirming.$c$),
   '{"icon": "inventory"}', 310),
  ('secondhand.review.bad_guide', 'secondhand', 'warning',
   jsonb_build_object('th', $c$เขียนเหตุผลที่ประเมินไม่ดี$c$, 'en', $c$Tell us why it was bad$c$),
   jsonb_build_object('th', $c$อธิบายสิ่งที่เกิดขึ้นตามจริงอย่างสุภาพ อย่างน้อย 5 ตัวอักษร เพื่อช่วยสมาชิกคนอื่นตัดสินใจ$c$,
                      'en', $c$Describe what happened, honestly and politely, in at least 5 characters to help other members.$c$),
   '{"icon": "warning"}', 320),
  ('secondhand.review.report_guide', 'secondhand', 'guide',
   jsonb_build_object('th', $c$รายงานรีวิว$c$, 'en', $c$Report a review$c$),
   jsonb_build_object('th', $c$ทีมงานจะตรวจสอบรีวิวที่ถูกรายงาน การรายงานไม่ได้ลบรีวิวทันที
ถ้ารีวิวผิดกติกา ทีมงานจะซ่อนรีวิวนั้นและแจ้งผลให้คุณทราบทางการแจ้งเตือน$c$,
                      'en', $c$The team checks every reported review; reporting doesn't remove it right away.
If the review breaks the rules, the team hides it and lets you know in your notifications.$c$),
   '{"icon": "flag"}', 330),

  ('secondhand.review_preset.buyer_as_described', 'secondhand', 'preset',
   jsonb_build_object('th', $c$สินค้าตรงตามรายละเอียด$c$, 'en', $c$As described$c$),
   jsonb_build_object('th', $c$สินค้าตรงตามรายละเอียดที่ลงไว้ ขอบคุณค่ะ$c$, 'en', $c$The item matched the listing. Thank you!$c$),
   '{"role": "buyer"}', 10),
  ('secondhand.review_preset.buyer_fast_shipping', 'secondhand', 'preset',
   jsonb_build_object('th', $c$จัดส่งรวดเร็ว$c$, 'en', $c$Fast shipping$c$),
   jsonb_build_object('th', $c$จัดส่งรวดเร็ว ได้รับสินค้าไวกว่าที่คิด$c$, 'en', $c$Shipped quickly; it arrived sooner than expected.$c$),
   '{"role": "buyer"}', 20),
  ('secondhand.review_preset.buyer_well_packed', 'secondhand', 'preset',
   jsonb_build_object('th', $c$แพ็กสินค้าดีมาก$c$, 'en', $c$Carefully packed$c$),
   jsonb_build_object('th', $c$แพ็กสินค้ามาอย่างดี สินค้าไม่เสียหาย$c$, 'en', $c$Packed carefully; the item arrived undamaged.$c$),
   '{"role": "buyer"}', 30),
  ('secondhand.review_preset.buyer_friendly', 'secondhand', 'preset',
   jsonb_build_object('th', $c$ติดต่อง่าย สุภาพ$c$, 'en', $c$Friendly seller$c$),
   jsonb_build_object('th', $c$ผู้ขายตอบไวและสุภาพ ซื้อขายได้อย่างสบายใจ$c$, 'en', $c$Quick, polite replies. A pleasant deal.$c$),
   '{"role": "buyer"}', 40),
  ('secondhand.review_preset.buyer_recommend', 'secondhand', 'preset',
   jsonb_build_object('th', $c$แนะนำผู้ขายรายนี้$c$, 'en', $c$Recommended$c$),
   jsonb_build_object('th', $c$ประทับใจมาก แนะนำผู้ขายรายนี้ค่ะ$c$, 'en', $c$Very happy with this seller. Recommended!$c$),
   '{"role": "buyer"}', 50),
  ('secondhand.review_preset.seller_fast_payment', 'secondhand', 'preset',
   jsonb_build_object('th', $c$ชำระเงินรวดเร็ว$c$, 'en', $c$Quick payment$c$),
   jsonb_build_object('th', $c$ชำระเงินรวดเร็ว ขอบคุณที่ซื้อสินค้าค่ะ$c$, 'en', $c$Paid quickly. Thank you for your purchase!$c$),
   '{"role": "seller"}', 10),
  ('secondhand.review_preset.seller_quick_receipt', 'secondhand', 'preset',
   jsonb_build_object('th', $c$ยืนยันรับสินค้าไว$c$, 'en', $c$Confirmed receipt quickly$c$),
   jsonb_build_object('th', $c$ยืนยันรับสินค้าและประเมินอย่างรวดเร็ว ขอบคุณค่ะ$c$, 'en', $c$Confirmed receipt and reviewed quickly. Thank you!$c$),
   '{"role": "seller"}', 20),
  ('secondhand.review_preset.seller_smooth_deal', 'secondhand', 'preset',
   jsonb_build_object('th', $c$ซื้อขายราบรื่น$c$, 'en', $c$Smooth deal$c$),
   jsonb_build_object('th', $c$ซื้อขายได้อย่างราบรื่น ไม่มีปัญหาใด ๆ$c$, 'en', $c$A smooth deal with no problems at all.$c$),
   '{"role": "seller"}', 30),
  ('secondhand.review_preset.seller_friendly', 'secondhand', 'preset',
   jsonb_build_object('th', $c$สุภาพ ติดต่อง่าย$c$, 'en', $c$Friendly buyer$c$),
   jsonb_build_object('th', $c$ผู้ซื้อสุภาพและติดต่อง่าย ยินดีที่ได้ซื้อขายด้วยค่ะ$c$, 'en', $c$Polite and easy to deal with. Glad to have traded with you!$c$),
   '{"role": "seller"}', 40),
  ('secondhand.review_preset.seller_welcome_back', 'secondhand', 'preset',
   jsonb_build_object('th', $c$ยินดีต้อนรับอีกครั้ง$c$, 'en', $c$Welcome back anytime$c$),
   jsonb_build_object('th', $c$ขอบคุณมากค่ะ ถ้ามีโอกาสยินดีให้บริการอีกครั้ง$c$, 'en', $c$Thank you so much. You're welcome back anytime!$c$),
   '{"role": "seller"}', 50),

  ('secondhand.notice.review_received', 'secondhand', 'notice',
   jsonb_build_object('th', $c$คุณได้รับรีวิวแล้ว$c$, 'en', $c$You received a review$c$),
   jsonb_build_object('th', $c${name} ประเมินคุณว่า "{verdict}" จากคำสั่งซื้อ {order}$c$,
                      'en', $c${name} rated you "{verdict}" for order {order}.$c$),
   '{"placeholders": ["name", "verdict", "order"]}', 200),
  ('secondhand.notice.review_reminder', 'secondhand', 'notice',
   jsonb_build_object('th', $c$รอให้คะแนน$c$, 'en', $c$Waiting for your review$c$),
   jsonb_build_object('th', $c$คำสั่งซื้อ {order}: อย่าลืมประเมิน{side}$c$,
                      'en', $c$Order {order}: don't forget to rate the {side}.$c$),
   '{"placeholders": ["order", "side"]}', 210),
  ('secondhand.notice.review_hidden', 'secondhand', 'notice',
   jsonb_build_object('th', $c$รีวิวของคุณถูกซ่อน$c$, 'en', $c$Your review was hidden$c$),
   jsonb_build_object('th', $c$รีวิวจากคำสั่งซื้อ {order} ถูกซ่อนเพราะไม่เป็นไปตามกติกา: {reason}$c$,
                      'en', $c$Your review for order {order} was hidden for breaking the rules: {reason}$c$),
   '{"placeholders": ["order", "reason"]}', 220),
  ('secondhand.notice.review_restored', 'secondhand', 'notice',
   jsonb_build_object('th', $c$รีวิวของคุณแสดงอีกครั้ง$c$, 'en', $c$Your review is shown again$c$),
   jsonb_build_object('th', $c$รีวิวจากคำสั่งซื้อ {order} กลับมาแสดงแล้วหลังทีมงานตรวจสอบ$c$,
                      'en', $c$Your review for order {order} is shown again after the team's check.$c$),
   '{"placeholders": ["order"]}', 230),
  ('secondhand.notice.review_report_upheld', 'secondhand', 'notice',
   jsonb_build_object('th', $c$ซ่อนรีวิวที่คุณรายงานแล้ว$c$, 'en', $c$The review you reported is hidden$c$),
   jsonb_build_object('th', $c$ทีมงานซ่อนรีวิวจากคำสั่งซื้อ {order} ตามที่คุณรายงานแล้ว ขอบคุณค่ะ$c$,
                      'en', $c$The team hid the review for order {order} that you reported. Thank you!$c$),
   '{"placeholders": ["order"]}', 240),
  ('secondhand.notice.review_report_dismissed', 'secondhand', 'notice',
   jsonb_build_object('th', $c$ตรวจสอบรีวิวที่คุณรายงานแล้ว$c$, 'en', $c$We checked the review you reported$c$),
   jsonb_build_object('th', $c$ทีมงานตรวจสอบแล้ว รีวิวจากคำสั่งซื้อ {order} ไม่ผิดกติกา จึงยังแสดงอยู่$c$,
                      'en', $c$The team found that the review for order {order} follows the rules, so it stays.$c$),
   '{"placeholders": ["order"]}', 250),
  ('secondhand.notice.order_completed_seller', 'secondhand', 'notice',
   jsonb_build_object('th', $c$การซื้อขายเสร็จสมบูรณ์$c$, 'en', $c$Sale completed$c$),
   jsonb_build_object('th', $c$คำสั่งซื้อ {order}: โอนรายได้สุทธิ ฿{net} เข้ากระเป๋าแล้ว (หักค่าธรรมเนียม ฿{fee}) กรุณาประเมินผู้ซื้อ$c$,
                      'en', $c$Order {order}: ฿{net} net (after a ฿{fee} fee) is in your wallet. Please rate the buyer.$c$),
   '{"placeholders": ["order", "net", "fee"]}', 260),
  ('secondhand.notice.order_completed_seller_mock', 'secondhand', 'notice',
   jsonb_build_object('th', $c$การซื้อขายเสร็จสมบูรณ์$c$, 'en', $c$Sale completed$c$),
   jsonb_build_object('th', $c$คำสั่งซื้อ {order}: ชำระแบบจำลอง จึงไม่มีเงินเข้ากระเป๋า กรุณาประเมินผู้ซื้อ$c$,
                      'en', $c$Order {order}: paid with the test payment, so no money reached your wallet. Please rate the buyer.$c$),
   '{"placeholders": ["order", "net", "fee"]}', 270),
  ('secondhand.notice.order_completed_buyer', 'secondhand', 'notice',
   jsonb_build_object('th', $c$การซื้อขายเสร็จสมบูรณ์$c$, 'en', $c$Purchase completed$c$),
   jsonb_build_object('th', $c$คำสั่งซื้อ {order} เสร็จสมบูรณ์ ขอบคุณที่ประเมินผู้ขาย$c$,
                      'en', $c$Order {order} is complete. Thank you for rating the seller.$c$),
   '{"placeholders": ["order"]}', 280),
  ('secondhand.notice.order_auto_received_buyer', 'secondhand', 'notice',
   jsonb_build_object('th', $c$การซื้อขายเสร็จสมบูรณ์$c$, 'en', $c$Purchase completed$c$),
   jsonb_build_object('th', $c$คำสั่งซื้อ {order}: ระบบยืนยันรับสินค้าให้อัตโนมัติแล้ว อย่าลืมประเมินผู้ขาย$c$,
                      'en', $c$Order {order}: receipt was confirmed automatically. Don't forget to rate the seller.$c$),
   '{"placeholders": ["order"]}', 290)
on conflict (content_key) do nothing;

-- ---------------------------------------------------------------------------
-- Grants and app scope
-- ---------------------------------------------------------------------------
revoke all on function secondhand.review_preset_r25(text, text) from public, anon, authenticated;
revoke all on function secondhand.write_review_r25(uuid, uuid, text, text, text) from public, anon, authenticated;
revoke all on function secondhand.run_review_reminders_r25() from public, anon, authenticated;
revoke all on function kaoid_private.review_staff_r25() from public, anon, authenticated;
revoke all on function kaoid_private.review_member_json_r25(uuid) from public, anon, authenticated;
revoke all on function kaoid_private.review_staff_json_r25(secondhand.reviews) from public, anon, authenticated;

revoke all on function secondhand.confirm_received(uuid) from public, anon, authenticated;
revoke all on function secondhand.submit_review(uuid, text, text, text) from public, anon, authenticated;
revoke all on function secondhand.receive_and_review(uuid, text, text, text) from public, anon, authenticated;
revoke all on function secondhand.list_orders_to_review(timestamptz, integer) from public, anon, authenticated;
revoke all on function secondhand.report_review(uuid, text, text) from public, anon, authenticated;
grant execute on function secondhand.submit_review(uuid, text, text, text) to authenticated;
grant execute on function secondhand.receive_and_review(uuid, text, text, text) to authenticated;
grant execute on function secondhand.list_orders_to_review(timestamptz, integer) to authenticated;
grant execute on function secondhand.report_review(uuid, text, text) to authenticated;

revoke all on function kaoid_private.review_queue_r25(text, timestamptz), kaoid_private.review_detail_r25(uuid),
  kaoid_private.review_moderate_r25(uuid, boolean, text),
  public.review_queue_r25(text, timestamptz), public.review_detail_r25(uuid),
  public.review_moderate_r25(uuid, boolean, text)
  from public, anon;
grant execute on function kaoid_private.review_queue_r25(text, timestamptz), kaoid_private.review_detail_r25(uuid),
  kaoid_private.review_moderate_r25(uuid, boolean, text),
  public.review_queue_r25(text, timestamptz), public.review_detail_r25(uuid),
  public.review_moderate_r25(uuid, boolean, text)
  to authenticated;

-- Secondhand receives with a review and reports with its app token; moderation stays first-party only.
update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
                              'secondhand.receive_and_review', 'secondhand.report_review',
                              'secondhand.list_orders_to_review']) r
                             where r <> 'secondhand.confirm_received' order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
