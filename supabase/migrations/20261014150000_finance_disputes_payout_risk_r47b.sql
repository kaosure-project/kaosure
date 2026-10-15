-- R47b: automated settlement and risk-based financial governance.
--
-- 1. Auto-Settlement: a Delivered update starts a 72-hour countdown. Buyer confirmation releases escrow to the shop
--    at once; otherwise the order-timeout cron releases it when the countdown ends. An open problem report freezes
--    escrow and stops the countdown (unchanged since R26). Without a Delivered update the shipping-based receive
--    window from R22 stays the long stop.
-- 2. Disputes: only frozen orders reach staff. Dispute staff propose "refund buyer" or "release to seller"; a finance
--    person (finance.refunds.review) confirms or sends it back. Dismissing stays single-person.
-- 3. Withdrawals: a risk engine sorts each request into the automatic lane (paid through the Partner; until an
--    outbound payout adapter exists one finance person pays it as before) or the review lane (one person approves,
--    a different person pays). Rejecting stays single-person.
-- While nobody else can be the second person, the Owner may do both steps 24 hours apart.

-- 1. Auto-Settlement ------------------------------------------------------------------------------------------------
alter table secondhand.market_settings
  add column auto_release_hours integer not null default 72 check (auto_release_hours between 24 and 336);

-- Called by the carrier tracking worker (service role) when a parcel is delivered.
create or replace function secondhand.mark_delivered_r47b(p_order_id uuid, p_delivered_at timestamptz default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
  v_hours integer;
  v_at timestamptz;
  v_until timestamptz;
begin
  select * into o from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'order_not_found' using errcode = '22023';
  end if;
  if o.delivered_at is not null then
    return jsonb_build_object('order_id', o.id, 'delivered_at', o.delivered_at, 'changed', false);
  end if;
  if o.order_status <> 'shipped' then
    raise exception 'order_not_shipped' using errcode = '22023';
  end if;
  select s.auto_release_hours into strict v_hours from secondhand.market_settings s where s.id;
  v_at := least(greatest(coalesce(p_delivered_at, now()), coalesce(o.shipped_at, now())), now());
  v_until := v_at + make_interval(hours => v_hours);

  update public.orders set delivered_at = v_at, updated_at = now() where id = o.id;
  update secondhand.order_details set receive_by = v_until, updated_at = now() where order_id = o.id;
  perform secondhand.order_log_r22(o.id, null, 'shipped', 'shipped', 'delivered', 'auto_release_at ' || v_until);
  perform secondhand.order_notify_r22(o.buyer_id, o.id, 'delivered', 'พัสดุถึงปลายทางแล้ว',
    'คำสั่งซื้อ ' || o.order_number || ': พัสดุจัดส่งสำเร็จแล้ว กรุณาตรวจสินค้าและกดยืนยันรับภายใน '
      || ceil(v_hours / 24.0)::int || ' วัน หากไม่ยืนยันและไม่แจ้งปัญหา ระบบจะปิดคำสั่งซื้อและโอนเงินให้ร้านค้าอัตโนมัติ');
  return jsonb_build_object('order_id', o.id, 'delivered_at', v_at, 'receive_by', v_until, 'changed', true);
end $$;

revoke all on function secondhand.mark_delivered_r47b(uuid, timestamptz) from public, anon, authenticated;
grant execute on function secondhand.mark_delivered_r47b(uuid, timestamptz) to service_role;

-- 2. Shared helpers -------------------------------------------------------------------------------------------------
create or replace function kaoid_private.owner_profile_r47b(p_profile uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.company_owners o where o.profile_id = p_profile);
$$;

-- Someone other than the excluded people could act as the second person for this permission.
create or replace function kaoid_private.finance_second_ready_r47b(p_permission text, p_exclude uuid[])
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles p
     where p.id <> all (array_remove(coalesce(p_exclude, '{}'), null))
       and (exists (select 1 from public.company_owners o where o.profile_id = p.id)
         or exists (select 1 from public.admin_assignments a where a.profile_id = p.id and a.is_active))
       and exists (select 1 from auth.mfa_factors f where f.user_id = p.id and f.status::text = 'verified')
       and kaoid_private.profile_permission_r47(p.id, p_permission));
$$;

-- 3. Disputes: propose, then a finance person confirms ----------------------------------------------------------------
alter table secondhand.order_issues
  add column proposed_decision text check (proposed_decision in ('refund', 'release')),
  add column proposed_note text check (char_length(proposed_note) between 3 and 500),
  add column proposed_by uuid references public.profiles(id),
  add column proposed_at timestamptz,
  add column confirm_mode text check (confirm_mode in ('two_person', 'cooling_off')),
  add column confirm_after timestamptz,
  add column confirmed_by uuid references public.profiles(id),
  add column returned_reason text check (char_length(returned_reason) between 3 and 500),
  add column returned_by uuid references public.profiles(id),
  add column returned_at timestamptz,
  add constraint order_issues_proposal_r47b check (
    (proposed_decision is null and proposed_note is null and proposed_by is null and proposed_at is null
      and confirm_mode is null and confirm_after is null)
    or (proposed_decision is not null and proposed_note is not null and proposed_by is not null
      and proposed_at is not null
      and ((confirm_mode = 'two_person' and confirm_after is null)
        or (confirm_mode = 'cooling_off' and confirm_after is not null))));

create or replace function kaoid_private.order_issue_staff_r26()
returns uuid language plpgsql stable security definer set search_path = '' as $$
begin
  if not (kaoid_private.staff_permission_r24('marketplace.orders.resolve')
          or kaoid_private.staff_permission_r24('finance.refunds.review')) then
    raise exception 'order_issue_access_denied' using errcode = '42501';
  end if;
  return auth.uid();
end $$;

create or replace function kaoid_private.order_issue_proposer_r47b()
returns uuid language plpgsql stable security definer set search_path = '' as $$
begin
  if not kaoid_private.staff_permission_r24('marketplace.orders.resolve') then
    raise exception 'order_issue_access_denied' using errcode = '42501';
  end if;
  return auth.uid();
end $$;

create or replace function kaoid_private.refund_confirmer_r47b()
returns uuid language plpgsql stable security definer set search_path = '' as $$
begin
  if not kaoid_private.staff_permission_r24('finance.refunds.review') then
    raise exception 'refund_confirm_denied' using errcode = '42501';
  end if;
  return auth.uid();
end $$;

create or replace function kaoid_private.order_issue_staff_json_r26(i secondhand.order_issues)
returns jsonb language sql stable security definer set search_path = '' as $$
  select secondhand.order_issue_json_r26(i) || jsonb_build_object(
    'resolved_by_name', (select p.display_name from public.profiles p where p.id = i.resolved_by),
    'proposal', case when i.proposed_by is not null then jsonb_build_object(
      'decision', i.proposed_decision, 'note', i.proposed_note, 'proposed_by', i.proposed_by,
      'proposed_by_name', (select p.display_name from public.profiles p where p.id = i.proposed_by),
      'proposed_at', i.proposed_at, 'mode', i.confirm_mode, 'confirm_after', i.confirm_after,
      'confirmed_by_name', (select p.display_name from public.profiles p where p.id = i.confirmed_by)) end,
    'returned', case when i.returned_by is not null then jsonb_build_object(
      'reason', i.returned_reason, 'at', i.returned_at,
      'by_name', (select p.display_name from public.profiles p where p.id = i.returned_by)) end,
    'can_propose', i.issue_status = 'open' and i.proposed_by is null
      and auth.uid() is distinct from o.buyer_id and auth.uid() is distinct from o.seller_id
      and kaoid_private.staff_permission_r24('marketplace.orders.resolve'),
    'can_confirm', i.issue_status = 'open' and i.proposed_by is not null
      and auth.uid() is distinct from o.buyer_id and auth.uid() is distinct from o.seller_id
      and (i.proposed_by is distinct from auth.uid() or (i.confirm_mode = 'cooling_off' and now() >= i.confirm_after))
      and kaoid_private.staff_permission_r24('finance.refunds.review'),
    'can_withdraw_proposal', i.issue_status = 'open' and i.proposed_by = auth.uid(),
    'order', jsonb_build_object(
      'id', o.id, 'order_number', o.order_number, 'status', o.order_status, 'total', o.total_amount,
      'payment_method', d.payment_method, 'escrow_status', e.escrow_status,
      'paid_at', o.paid_at, 'shipped_at', o.shipped_at, 'delivered_at', o.delivered_at, 'receive_by', d.receive_by,
      'carrier', o.shipping_company, 'tracking_number', o.tracking_number, 'product_title', p.title),
    'buyer', kaoid_private.review_member_json_r25(o.buyer_id),
    'seller', kaoid_private.review_member_json_r25(o.seller_id))
    from public.orders o
    join secondhand.order_details d on d.order_id = o.id
    join public.products p on p.id = o.product_id
    left join public.escrow_transactions e on e.id = d.escrow_id
   where o.id = i.order_id;
$$;

create or replace function kaoid_private.order_issue_queue_r26(p_filter text, p_before timestamptz)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  perform kaoid_private.order_issue_staff_r26();
  if p_filter is null or p_filter not in ('open', 'finance', 'closed') then
    raise exception 'invalid_filter' using errcode = '22023';
  end if;
  return (
    select coalesce(jsonb_agg(kaoid_private.order_issue_staff_json_r26(x.i) || jsonb_build_object('sort_at', x.sort_at)
                              order by x.sort_at desc, (x.i).id desc), '[]')
      from (select i, coalesce(i.resolved_at, i.proposed_at, i.created_at) as sort_at
              from secondhand.order_issues i
             where case p_filter when 'open' then i.issue_status = 'open'
                                 when 'finance' then i.issue_status = 'open' and i.proposed_by is not null
                                 else i.issue_status <> 'open' end
               and (p_before is null or coalesce(i.resolved_at, i.proposed_at, i.created_at) < p_before)
             order by coalesce(i.resolved_at, i.proposed_at, i.created_at) desc, i.id desc
             limit 30) x);
end $$;

-- refund / release become proposals; dismiss: no fault found, the order carries on.
create or replace function kaoid_private.order_issue_resolve_r26(p_issue_id uuid, p_decision text, p_note text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u uuid := kaoid_private.order_issue_proposer_r47b();
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
  i secondhand.order_issues;
  o public.orders;
  v_days integer;
  v_hours integer;
  v_mode text;
  v_values jsonb;
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if p_decision is null or p_decision not in ('refund', 'release', 'dismiss')
     or char_length(coalesce(v_note, '')) > 500 then
    raise exception 'invalid_decision' using errcode = '22023';
  end if;
  if char_length(coalesce(v_note, '')) < 3 then
    raise exception 'note_required' using errcode = '22023';
  end if;
  select * into i from secondhand.order_issues where id = p_issue_id for update;
  if not found then
    raise exception 'order_issue_not_found' using errcode = '22023';
  end if;
  select * into strict o from public.orders where id = i.order_id for update;
  if u in (o.buyer_id, o.seller_id) then
    raise exception 'own_order' using errcode = '42501';
  end if;
  if i.issue_status <> 'open' or o.order_status <> 'shipped' then
    raise exception 'order_issue_closed' using errcode = '22023';
  end if;
  if i.proposed_by is not null then
    if i.proposed_by = u and i.proposed_decision = p_decision then
      return kaoid_private.order_issue_staff_json_r26(i);
    end if;
    raise exception 'proposal_pending' using errcode = '22023';
  end if;

  if p_decision in ('refund', 'release') then
    v_mode := case
      when kaoid_private.finance_second_ready_r47b('finance.refunds.review', array[u, o.buyer_id, o.seller_id])
        then 'two_person'
      when kaoid_private.owner_profile_r47b(u) then 'cooling_off'
      else 'two_person' end;
    update secondhand.order_issues
       set proposed_decision = p_decision, proposed_note = v_note, proposed_by = u, proposed_at = now(),
           confirm_mode = v_mode,
           confirm_after = case when v_mode = 'cooling_off' then now() + interval '24 hours' end,
           returned_reason = null, returned_by = null, returned_at = null
     where id = i.id
    returning * into i;
    perform secondhand.order_log_r22(o.id, u, null, null, 'admin_action', 'propose_' || p_decision || ': ' || v_note);
    insert into public.activity_logs(profile_id, action, target_table, target_id, description)
    values (u, 'marketplace.order_issue.propose', 'order_issues', i.id,
            jsonb_build_object('order', o.order_number, 'decision', p_decision, 'note', v_note, 'mode', v_mode)::text);
    return kaoid_private.order_issue_staff_json_r26(i);
  end if;

  update secondhand.order_issues
     set issue_status = 'dismissed', resolution_note = v_note, resolved_by = u, resolved_at = now()
   where id = i.id
  returning * into i;
  select s.receive_window_days, s.auto_release_hours into strict v_days, v_hours
    from secondhand.market_settings s where s.id;
  if o.delivered_at is not null then
    v_days := ceil(v_hours / 24.0)::int;
    perform secondhand.order_issue_unhold_r26(o.id, now() + make_interval(hours => v_hours));
  else
    perform secondhand.order_issue_unhold_r26(o.id, now() + make_interval(days => v_days));
  end if;
  perform secondhand.order_log_r22(o.id, u, null, null, 'dispute_closed', 'dismiss: ' || v_note);

  v_values := jsonb_build_object('order', o.order_number, 'note', v_note, 'days', v_days);
  perform secondhand.order_issue_notify_r26(x.profile, i, 'secondhand.notice.order_issue_dismissed', v_values,
    'ทีมงานตรวจสอบปัญหาแล้ว',
    'คำสั่งซื้อ {order}: ทีมงานตรวจสอบแล้ว คำสั่งซื้อดำเนินต่อตามปกติ ผู้ซื้อยืนยันรับสินค้าได้ภายใน {days} วัน หมายเหตุ: {note}')
    from (values (o.buyer_id), (o.seller_id)) x(profile);

  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'marketplace.order_issue.dismiss', 'order_issues', i.id, o.order_number || ': ' || v_note);
  return kaoid_private.order_issue_staff_json_r26(i);
end $$;

create or replace function kaoid_private.order_issue_withdraw_proposal_r47b(p_issue_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u uuid := kaoid_private.order_issue_proposer_r47b();
  i secondhand.order_issues;
begin
  select * into i from secondhand.order_issues where id = p_issue_id for update;
  if not found then
    raise exception 'order_issue_not_found' using errcode = '22023';
  end if;
  if i.issue_status <> 'open' or i.proposed_by is null then
    raise exception 'proposal_missing' using errcode = '22023';
  end if;
  if i.proposed_by <> u then
    raise exception 'proposal_not_yours' using errcode = '42501';
  end if;
  update secondhand.order_issues
     set proposed_decision = null, proposed_note = null, proposed_by = null, proposed_at = null,
         confirm_mode = null, confirm_after = null
   where id = i.id
  returning * into i;
  perform secondhand.order_log_r22(i.order_id, u, null, null, 'admin_action', 'proposal_withdrawn');
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'marketplace.order_issue.unpropose', 'order_issues', i.id, null);
  return kaoid_private.order_issue_staff_json_r26(i);
end $$;

create or replace function kaoid_private.order_issue_confirm_r47b(p_issue_id uuid, p_approve boolean, p_reason text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u uuid := kaoid_private.refund_confirmer_r47b();
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
  i secondhand.order_issues;
  o public.orders;
  v_decision text;
  v_values jsonb;
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if p_approve is null or char_length(coalesce(v_reason, '')) > 500 then
    raise exception 'invalid_decision' using errcode = '22023';
  end if;
  if not p_approve and char_length(coalesce(v_reason, '')) < 3 then
    raise exception 'reason_required' using errcode = '22023';
  end if;
  select * into i from secondhand.order_issues where id = p_issue_id for update;
  if not found then
    raise exception 'order_issue_not_found' using errcode = '22023';
  end if;
  select * into strict o from public.orders where id = i.order_id for update;
  if u in (o.buyer_id, o.seller_id) then
    raise exception 'own_order' using errcode = '42501';
  end if;
  if i.issue_status <> 'open' or o.order_status <> 'shipped' then
    raise exception 'order_issue_closed' using errcode = '22023';
  end if;
  if i.proposed_by is null then
    raise exception 'proposal_missing' using errcode = '22023';
  end if;
  if i.proposed_by = u then
    if not p_approve or i.confirm_mode <> 'cooling_off' then
      raise exception 'second_person_required' using errcode = '42501';
    end if;
    if now() < i.confirm_after then
      raise exception 'cooling_off_active' using errcode = '22023';
    end if;
  end if;

  if not p_approve then
    update secondhand.order_issues
       set proposed_decision = null, proposed_note = null, proposed_by = null, proposed_at = null,
           confirm_mode = null, confirm_after = null,
           returned_reason = v_reason, returned_by = u, returned_at = now()
     where id = i.id
    returning * into i;
    perform secondhand.order_log_r22(o.id, u, null, null, 'admin_action', 'proposal_returned: ' || v_reason);
    insert into public.activity_logs(profile_id, action, target_table, target_id, description)
    values (u, 'marketplace.order_issue.return', 'order_issues', i.id, o.order_number || ': ' || v_reason);
    return kaoid_private.order_issue_staff_json_r26(i);
  end if;

  v_decision := i.proposed_decision;
  update secondhand.order_issues
     set issue_status = case v_decision when 'refund' then 'refunded' else 'released' end,
         resolution_note = i.proposed_note, resolved_by = u, resolved_at = now(), confirmed_by = u
   where id = i.id
  returning * into i;
  if v_decision = 'refund' then
    perform secondhand.cancel_order_r22(o.id, u, 'staff', 'issue_refund');
  else
    perform secondhand.complete_order_r22(o.id, u);
  end if;
  perform secondhand.order_log_r22(o.id, u, null, null, 'dispute_closed', v_decision || ': ' || i.resolution_note);

  v_values := jsonb_build_object('order', o.order_number, 'note', i.resolution_note);
  perform secondhand.order_issue_notify_r26(x.profile, i, 'secondhand.notice.order_issue_' || i.issue_status, v_values,
    case v_decision when 'refund' then 'ทีมงานตัดสินคืนเงินให้ผู้ซื้อ' else 'ทีมงานตัดสินปล่อยเงินให้ผู้ขาย' end,
    case v_decision
      when 'refund' then 'คำสั่งซื้อ {order}: ทีมงานตรวจสอบแล้ว คืนเงินเต็มจำนวนให้ผู้ซื้อและยกเลิกคำสั่งซื้อ หมายเหตุ: {note}'
      else 'คำสั่งซื้อ {order}: ทีมงานตรวจสอบแล้ว ปล่อยเงินให้ผู้ขายและปิดคำสั่งซื้อ หมายเหตุ: {note}'
    end)
    from (values (o.buyer_id), (o.seller_id)) x(profile);

  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'marketplace.order_issue.' || v_decision, 'order_issues', i.id, o.order_number || ': ' || i.resolution_note);
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'marketplace.order_issue.confirm', 'order_issues', i.id,
          jsonb_build_object('order', o.order_number, 'decision', v_decision, 'proposed_by', i.proposed_by,
                             'confirmed_by', u, 'mode', i.confirm_mode)::text);
  return kaoid_private.order_issue_staff_json_r26(i);
end $$;

-- 4. Withdrawals: risk engine and two lanes --------------------------------------------------------------------------
create table kaoid_private.payout_risk_settings_r47b (
  id boolean primary key default true check (id),
  large_amount numeric(12,2) not null default 20000 check (large_amount between 1 and 10000000),
  first_withdrawal boolean not null default true,
  bank_new_days integer not null default 7 check (bank_new_days between 0 and 365),
  recovery_days integer not null default 30 check (recovery_days between 0 and 365),
  mfa_change_hours integer not null default 72 check (mfa_change_hours between 0 and 720),
  daily_amount numeric(12,2) not null default 50000 check (daily_amount between 1 and 100000000),
  daily_count integer not null default 3 check (daily_count between 1 and 100),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);
insert into kaoid_private.payout_risk_settings_r47b default values;
alter table kaoid_private.payout_risk_settings_r47b enable row level security;
revoke all on table kaoid_private.payout_risk_settings_r47b from public, anon, authenticated;

alter table public.withdraw_requests
  add column lane text not null default 'review' check (lane in ('auto', 'review')),
  add column risk_flags text[] not null default '{}',
  add column approved_by uuid references public.profiles(id),
  add column approval_mode text check (approval_mode in ('two_person', 'cooling_off')),
  add column pay_after timestamptz,
  add constraint withdraw_requests_approval_r47b check (
    (approved_by is null and approval_mode is null and pay_after is null)
    or (approved_by is not null and lane = 'review'
      and ((approval_mode = 'two_person' and pay_after is null)
        or (approval_mode = 'cooling_off' and pay_after is not null))));

create or replace function kaoid_private.withdraw_risk_r47b()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  s kaoid_private.payout_risk_settings_r47b;
  f text[] := '{}';
  v_sum numeric;
  v_count integer;
begin
  select * into strict s from kaoid_private.payout_risk_settings_r47b where id;
  if new.amount >= s.large_amount then
    f := array_append(f, 'large_amount');
  end if;
  if s.first_withdrawal and not exists (select 1 from public.withdraw_requests x
                                         where x.wallet_id = new.wallet_id and x.withdraw_status = 'paid') then
    f := array_append(f, 'first_withdrawal');
  end if;
  if not exists (select 1 from public.bank_accounts b
                  where b.id = new.bank_account_id and b.verified_at is not null
                    and b.verified_at <= now() - make_interval(days => s.bank_new_days)) then
    f := array_append(f, 'new_bank');
  end if;
  if exists (select 1 from kaoid_private.recovery_evidence_r10e e
              where e.profile_id = new.profile_id and e.created_at > now() - make_interval(days => s.recovery_days)) then
    f := array_append(f, 'recent_recovery');
  end if;
  if exists (select 1 from auth.mfa_factors m
              where m.user_id = new.profile_id
                and greatest(m.created_at, m.updated_at) > now() - make_interval(hours => s.mfa_change_hours)) then
    f := array_append(f, 'mfa_changed');
  end if;
  select coalesce(sum(x.amount) filter (where x.withdraw_status in ('pending', 'paid')), 0), count(*)
    into v_sum, v_count
    from public.withdraw_requests x
   where x.wallet_id = new.wallet_id and x.created_at > now() - interval '24 hours';
  if v_sum + new.amount > s.daily_amount then
    f := array_append(f, 'daily_amount');
  end if;
  if v_count + 1 > s.daily_count then
    f := array_append(f, 'daily_count');
  end if;
  new.risk_flags := f;
  new.lane := case when cardinality(f) = 0 then 'auto' else 'review' end;
  new.approved_by := null;
  new.approval_mode := null;
  new.pay_after := null;
  new.approved_at := null;
  return new;
end $$;

create trigger withdraw_requests_risk_r47b before insert on public.withdraw_requests
  for each row execute function kaoid_private.withdraw_risk_r47b();

create or replace function kaoid_private.withdrawal_own_r47b(r public.withdraw_requests, p_profile uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select r.profile_id = p_profile
      or (r.organization_id is not null
          and exists (select 1 from public.organization_members om
                       where om.organization_id = r.organization_id and om.profile_id = p_profile
                         and om.status in ('active', 'invited', 'suspended')));
$$;

create or replace function kaoid_private.withdrawal_staff_json_r24(r public.withdraw_requests)
returns jsonb language sql stable security definer set search_path = '' as $$
  select secondhand.withdrawal_json_r24(r) || jsonb_build_object(
    'profile_id', r.profile_id, 'source_app', r.source_app, 'reviewed_at', r.reviewed_at,
    'display_name', (select p.display_name from public.profiles p where p.id = r.profile_id),
    'account_code', (select a.account_code from kaoid_private.account_refs_r10c a where a.profile_id = r.profile_id),
    'reviewer_name', (select p.display_name from public.profiles p where p.id = r.reviewed_by),
    'organization_id', r.organization_id,
    'organization_name', (select o.name from public.organizations o where o.id = r.organization_id),
    'business_kao_id', (select k.kao_id from public.kao_id_identities k
                         where k.organization_id = r.organization_id and k.profile_id is null
                           and k.identity_type = 'business' and k.status = 'active'
                         order by k.issued_at desc limit 1),
    'lane', r.lane, 'risk_flags', to_jsonb(r.risk_flags),
    'approved_by', r.approved_by, 'approved_at', r.approved_at, 'approval_mode', r.approval_mode,
    'pay_after', r.pay_after,
    'approved_by_name', (select p.display_name from public.profiles p where p.id = r.approved_by),
    'can_approve', r.withdraw_status = 'pending' and r.lane = 'review' and r.approved_by is null
      and not kaoid_private.withdrawal_own_r47b(r, auth.uid()),
    'can_pay', r.withdraw_status = 'pending' and not kaoid_private.withdrawal_own_r47b(r, auth.uid())
      and (r.lane = 'auto'
        or (r.approved_by is not null
          and (r.approved_by is distinct from auth.uid()
            or (r.approval_mode = 'cooling_off' and now() >= r.pay_after)))));
$$;

create or replace function kaoid_private.withdrawal_approve_r47b(p_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u uuid := kaoid_private.withdraw_staff_r24();
  r public.withdraw_requests;
  v_mode text;
  v_exclude uuid[];
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  select * into r from public.withdraw_requests where id = p_id for update;
  if not found then
    raise exception 'withdrawal_not_found' using errcode = '22023';
  end if;
  if kaoid_private.withdrawal_own_r47b(r, u) then
    raise exception 'own_withdrawal' using errcode = '42501';
  end if;
  if r.withdraw_status <> 'pending' then
    raise exception 'withdrawal_not_pending' using errcode = '22023';
  end if;
  if r.lane <> 'review' then
    raise exception 'approval_not_needed' using errcode = '22023';
  end if;
  if r.approved_by is not null then
    if r.approved_by = u then
      return kaoid_private.withdrawal_staff_json_r24(r);
    end if;
    raise exception 'withdrawal_already_approved' using errcode = '22023';
  end if;
  if r.bank_account_id is null or secondhand.withdraw_bank_r27(r) is distinct from r.bank_account_id then
    raise exception 'bank_changed' using errcode = '22023';
  end if;

  v_exclude := array[u, r.profile_id] || coalesce(array(
    select om.profile_id from public.organization_members om
     where om.organization_id = r.organization_id and om.status in ('active', 'invited', 'suspended')), '{}');
  v_mode := case
    when kaoid_private.finance_second_ready_r47b('wallet.withdraw.approve', v_exclude) then 'two_person'
    when kaoid_private.owner_profile_r47b(u) then 'cooling_off'
    else 'two_person' end;
  update public.withdraw_requests
     set approved_by = u, approved_at = now(), approval_mode = v_mode,
         pay_after = case when v_mode = 'cooling_off' then now() + interval '24 hours' end, updated_at = now()
   where id = r.id
  returning * into r;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'finance.withdraw.approve', 'withdraw_requests', r.id,
          jsonb_build_object('mode', v_mode, 'risk_flags', r.risk_flags, 'amount', r.amount)::text);
  return kaoid_private.withdrawal_staff_json_r24(r);
end $$;

create or replace function kaoid_private.withdrawal_review_r24(p_id uuid, p_paid boolean, p_reference text,
                                                               p_reason text)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := kaoid_private.withdraw_staff_r24();
  r public.withdraw_requests;
  w public.wallets;
  v_ref text := btrim(coalesce(p_reference, ''));
  v_reason text := btrim(coalesce(p_reason, ''));
  v_amount text;
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if p_paid is null then
    raise exception 'invalid_decision' using errcode = '22023';
  end if;
  if p_paid and char_length(v_ref) not between 3 and 100 then
    raise exception 'reference_required' using errcode = '22023';
  end if;
  if not p_paid and char_length(v_reason) not between 3 and 500 then
    raise exception 'reason_required' using errcode = '22023';
  end if;

  select * into r from public.withdraw_requests where id = p_id for update;
  if not found then
    raise exception 'withdrawal_not_found' using errcode = '22023';
  end if;
  if kaoid_private.withdrawal_own_r47b(r, u) then
    raise exception 'own_withdrawal' using errcode = '42501';
  end if;
  if r.withdraw_status <> 'pending' then
    if r.reviewed_by = u and r.withdraw_status = (case when p_paid then 'paid' else 'rejected' end) then
      return kaoid_private.withdrawal_staff_json_r24(r);
    end if;
    raise exception 'withdrawal_not_pending' using errcode = '22023';
  end if;

  v_amount := to_char(r.amount, 'FM999,999,990.00');
  if p_paid then
    if r.lane = 'review' then
      if r.approved_by is null then
        raise exception 'approval_required' using errcode = '22023';
      end if;
      if r.approved_by = u then
        if r.approval_mode <> 'cooling_off' then
          raise exception 'second_person_required' using errcode = '42501';
        end if;
        if now() < r.pay_after then
          raise exception 'cooling_off_active' using errcode = '22023';
        end if;
      end if;
    end if;
    if r.bank_account_id is null or secondhand.withdraw_bank_r27(r) is distinct from r.bank_account_id then
      raise exception 'bank_changed' using errcode = '22023';
    end if;
    select * into strict w from public.wallets where id = r.wallet_id for update;
    if w.hold_balance < r.amount then
      raise exception 'wallet_mismatch' using errcode = '22023';
    end if;
    update public.wallets set hold_balance = hold_balance - r.amount, updated_at = now() where id = w.id;
    update public.wallet_transactions set transaction_status = 'completed', updated_at = now()
     where id = r.wallet_transaction_id;
    update public.withdraw_requests
       set withdraw_status = 'paid', paid_at = now(), approved_at = coalesce(approved_at, now()),
           transfer_reference = v_ref, reviewed_by = u, reviewed_at = now(), updated_at = now()
     where id = r.id
    returning * into r;
    insert into public.activity_logs(profile_id, action, target_table, target_id, description)
    values (u, 'finance.withdraw.paid', 'withdraw_requests', r.id,
            jsonb_build_object('reference', v_ref, 'lane', r.lane, 'approved_by', r.approved_by,
                               'mode', r.approval_mode)::text);
    insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
    values (r.profile_id,
            kaoid_private.content_message_r24('secondhand.notice.withdraw_paid', 'title', null, 'โอนเงินเข้าบัญชีแล้ว'),
            kaoid_private.content_message_r24('secondhand.notice.withdraw_paid', 'body',
              jsonb_build_object('amount', v_amount, 'bank', r.bank_name, 'last4', r.account_last4),
              'โอน ฿{amount} เข้าบัญชี {bank} ••••{last4} แล้ว'),
            'withdrawal', r.id, '/wallet', 'withdrawal:' || r.id || ':paid');
  else
    r := secondhand.return_withdrawal_r24(r.id, 'rejected', v_reason, u);
    insert into public.activity_logs(profile_id, action, target_table, target_id, description)
    values (u, 'finance.withdraw.reject', 'withdraw_requests', r.id, v_reason);
    insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
    values (r.profile_id,
            kaoid_private.content_message_r24('secondhand.notice.withdraw_rejected', 'title', null,
                                              'คำขอถอนเงินไม่ผ่าน'),
            kaoid_private.content_message_r24('secondhand.notice.withdraw_rejected', 'body',
              jsonb_build_object('amount', v_amount, 'reason', v_reason),
              'ยอด ฿{amount} คืนเข้า KaoSure Wallet แล้ว เหตุผล: {reason}'),
            'withdrawal', r.id, '/wallet', 'withdrawal:' || r.id || ':rejected');
  end if;
  return kaoid_private.withdrawal_staff_json_r24(r);
end $$;

-- Once a person approved a flagged withdrawal the member can no longer cancel it.
create or replace function secondhand.cancel_withdrawal(p_id uuid)
returns jsonb language plpgsql security definer set search_path to '' as $$
declare
  u uuid := secondhand.order_actor_r22();
  r public.withdraw_requests;
begin
  select * into r from public.withdraw_requests x where x.id = p_id for update;
  if not found
     or not (r.profile_id = u
             or (r.organization_id is not null
                 and exists (select 1 from public.shops s
                              where s.organization_id = r.organization_id and s.seller_identity_type = 'business'
                                and secondhand.shop_can_r27(s.id, 'finance', u)))) then
    raise exception 'withdrawal_not_found' using errcode = '22023';
  end if;
  if r.withdraw_status = 'cancelled' then
    return secondhand.withdrawal_json_r24(r);
  end if;
  if r.withdraw_status = 'pending' and r.approved_by is not null then
    raise exception 'withdrawal_in_review' using errcode = '22023';
  end if;
  r := secondhand.return_withdrawal_r24(r.id, 'cancelled', null, u);
  return secondhand.withdrawal_json_r24(r);
end $$;

-- 5. Risk settings: everyone with withdrawal access reads them, only the Owner changes them --------------------------
create or replace function kaoid_private.payout_risk_settings_r47b()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare s kaoid_private.payout_risk_settings_r47b;
begin
  if not (kaoid_private.staff_permission_r24('wallet.withdraw.approve')
          or kaoid_private.staff_permission_r24('settings.system.manage')) then
    raise exception 'payout_settings_denied' using errcode = '42501';
  end if;
  select * into strict s from kaoid_private.payout_risk_settings_r47b where id;
  return jsonb_build_object(
    'large_amount', s.large_amount, 'first_withdrawal', s.first_withdrawal, 'bank_new_days', s.bank_new_days,
    'recovery_days', s.recovery_days, 'mfa_change_hours', s.mfa_change_hours, 'daily_amount', s.daily_amount,
    'daily_count', s.daily_count, 'updated_at', s.updated_at,
    'updated_by_name', (select p.display_name from public.profiles p where p.id = s.updated_by),
    'can_edit', kaoid_private.staff_permission_r24('settings.system.manage'));
end $$;

create or replace function kaoid_private.payout_risk_settings_save_r47b(
  p_large numeric, p_first boolean, p_bank_days integer, p_recovery_days integer, p_mfa_hours integer,
  p_daily_amount numeric, p_daily_count integer)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  old kaoid_private.payout_risk_settings_r47b;
  s kaoid_private.payout_risk_settings_r47b;
begin
  if not kaoid_private.staff_permission_r24('settings.system.manage') then
    raise exception 'owner_required' using errcode = '42501';
  end if;
  perform kaoid_private.require_fresh_mfa_r14a();
  if p_large is null or p_large not between 1 and 10000000 or p_large <> round(p_large, 2)
     or p_first is null or p_bank_days is null or p_bank_days not between 0 and 365
     or p_recovery_days is null or p_recovery_days not between 0 and 365
     or p_mfa_hours is null or p_mfa_hours not between 0 and 720
     or p_daily_amount is null or p_daily_amount not between 1 and 100000000 or p_daily_amount <> round(p_daily_amount, 2)
     or p_daily_count is null or p_daily_count not between 1 and 100 then
    raise exception 'invalid_settings' using errcode = '22023';
  end if;
  select * into strict old from kaoid_private.payout_risk_settings_r47b where id for update;
  update kaoid_private.payout_risk_settings_r47b
     set large_amount = p_large, first_withdrawal = p_first, bank_new_days = p_bank_days,
         recovery_days = p_recovery_days, mfa_change_hours = p_mfa_hours, daily_amount = p_daily_amount,
         daily_count = p_daily_count, updated_at = now(), updated_by = auth.uid()
   where id
  returning * into s;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (auth.uid(), 'finance.payout_risk.update', 'payout_risk_settings', null,
          jsonb_build_object('before', to_jsonb(old) - 'id' - 'updated_by' - 'updated_at',
                             'after', to_jsonb(s) - 'id' - 'updated_by' - 'updated_at')::text);
  return kaoid_private.payout_risk_settings_r47b();
end $$;

-- 6. Admin Hub tools -------------------------------------------------------------------------------------------------
create or replace function kaoid_private.staff_tools_r24()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_withdrawals boolean := kaoid_private.staff_permission_r24('wallet.withdraw.approve');
  v_contents boolean := kaoid_private.staff_permission_r24('content.system.manage');
  v_reviews boolean := kaoid_private.staff_permission_r24('marketplace.reviews.moderate');
  v_issues boolean := kaoid_private.staff_permission_r24('marketplace.orders.resolve');
  v_refunds boolean := kaoid_private.staff_permission_r24('finance.refunds.review');
  v_topups boolean := kaoid_private.staff_permission_r24('wallet.deposit.approve');
  v_topup_settings boolean := kaoid_private.staff_permission_r24('wallet.deposit.settings');
  v_grants boolean := kaoid_private.staff_permission_r24('admin.assignments.approve');
  v_risk_settings boolean := kaoid_private.staff_permission_r24('settings.system.manage');
begin
  return jsonb_build_object(
    'withdrawals', v_withdrawals,
    'contents', v_contents,
    'reviews', v_reviews,
    'order_issues', v_issues or v_refunds,
    'refund_confirm', v_refunds,
    'topups', v_topups,
    'topup_settings', v_topup_settings,
    'grant_approvals', v_grants,
    'payout_risk_settings', v_risk_settings,
    'pending_withdrawals', case when v_withdrawals then
      (select count(*) from public.withdraw_requests r where r.withdraw_status = 'pending') end,
    'risk_withdrawals', case when v_withdrawals then
      (select count(*) from public.withdraw_requests r where r.withdraw_status = 'pending' and r.lane = 'review') end,
    'pending_review_reports', case when v_reviews then
      (select count(distinct rr.review_id) from secondhand.review_reports rr where rr.report_status = 'pending') end,
    'open_order_issues', case when v_issues then
      (select count(*) from secondhand.order_issues i where i.issue_status = 'open' and i.proposed_by is null) end,
    'issue_proposals', case when v_refunds then
      (select count(*) from secondhand.order_issues i
        where i.issue_status = 'open' and i.proposed_by is not null
          and (i.proposed_by <> auth.uid() or (i.confirm_mode = 'cooling_off' and now() >= i.confirm_after))) end,
    'pending_topups', case when v_topups then
      (select count(*) from public.topup_requests t where t.status in ('pending_review', 'awaiting_second')) end,
    'pending_grants', case when v_grants then
      (select count(*) from kaoid_private.staff_grants_r47 g
         join public.approval_requests q on q.id = g.approval_request_id
        where g.status = 'pending' and g.mode = 'two_person' and q.expires_at > now()
          and g.requested_by <> auth.uid() and g.target_profile_id <> auth.uid()) end);
end $$;

-- 7. Public entry points ---------------------------------------------------------------------------------------------
create or replace function public.withdrawal_approve_r47b(p_id uuid)
returns jsonb language sql set search_path = '' as $$ select kaoid_private.withdrawal_approve_r47b(p_id); $$;

create or replace function public.order_issue_confirm_r47b(p_issue_id uuid, p_approve boolean, p_reason text default null)
returns jsonb language sql set search_path = '' as $$
  select kaoid_private.order_issue_confirm_r47b(p_issue_id, p_approve, p_reason); $$;

create or replace function public.order_issue_withdraw_proposal_r47b(p_issue_id uuid)
returns jsonb language sql set search_path = '' as $$
  select kaoid_private.order_issue_withdraw_proposal_r47b(p_issue_id); $$;

create or replace function public.payout_risk_settings_r47b()
returns jsonb language sql set search_path = '' as $$ select kaoid_private.payout_risk_settings_r47b(); $$;

create or replace function public.payout_risk_settings_save_r47b(
  p_large numeric, p_first boolean, p_bank_days integer, p_recovery_days integer, p_mfa_hours integer,
  p_daily_amount numeric, p_daily_count integer)
returns jsonb language sql set search_path = '' as $$
  select kaoid_private.payout_risk_settings_save_r47b(p_large, p_first, p_bank_days, p_recovery_days, p_mfa_hours,
                                                      p_daily_amount, p_daily_count); $$;

revoke all on function kaoid_private.owner_profile_r47b(uuid) from public, anon, authenticated;
revoke all on function kaoid_private.finance_second_ready_r47b(text, uuid[]) from public, anon, authenticated;
revoke all on function kaoid_private.order_issue_proposer_r47b() from public, anon, authenticated;
revoke all on function kaoid_private.refund_confirmer_r47b() from public, anon, authenticated;
revoke all on function kaoid_private.withdraw_risk_r47b() from public, anon, authenticated;
revoke all on function kaoid_private.withdrawal_own_r47b(public.withdraw_requests, uuid) from public, anon, authenticated;

revoke all on function kaoid_private.withdrawal_approve_r47b(uuid),
  kaoid_private.order_issue_confirm_r47b(uuid, boolean, text),
  kaoid_private.order_issue_withdraw_proposal_r47b(uuid),
  kaoid_private.payout_risk_settings_r47b(),
  kaoid_private.payout_risk_settings_save_r47b(numeric, boolean, integer, integer, integer, numeric, integer),
  public.withdrawal_approve_r47b(uuid),
  public.order_issue_confirm_r47b(uuid, boolean, text),
  public.order_issue_withdraw_proposal_r47b(uuid),
  public.payout_risk_settings_r47b(),
  public.payout_risk_settings_save_r47b(numeric, boolean, integer, integer, integer, numeric, integer)
  from public, anon;
grant execute on function kaoid_private.withdrawal_approve_r47b(uuid),
  kaoid_private.order_issue_confirm_r47b(uuid, boolean, text),
  kaoid_private.order_issue_withdraw_proposal_r47b(uuid),
  kaoid_private.payout_risk_settings_r47b(),
  kaoid_private.payout_risk_settings_save_r47b(numeric, boolean, integer, integer, integer, numeric, integer),
  public.withdrawal_approve_r47b(uuid),
  public.order_issue_confirm_r47b(uuid, boolean, text),
  public.order_issue_withdraw_proposal_r47b(uuid),
  public.payout_risk_settings_r47b(),
  public.payout_risk_settings_save_r47b(numeric, boolean, integer, integer, integer, numeric, integer)
  to authenticated;
