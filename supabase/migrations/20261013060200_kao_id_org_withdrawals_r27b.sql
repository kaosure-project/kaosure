-- R27b (3/3): staff review of organization withdrawals. An organization's withdrawal is paid only to the
-- organization's verified bank account, and staff who belong to that organization may not review it.

create or replace function kaoid_private.withdrawal_staff_json_r24(r public.withdraw_requests)
returns jsonb
language sql
stable security definer
set search_path to ''
as $$
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
                         order by k.issued_at desc limit 1));
$$;

create or replace function kaoid_private.withdrawal_detail_r24(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := kaoid_private.withdraw_staff_r24();
  r public.withdraw_requests;
  b public.bank_accounts;
  w public.wallets;
begin
  select * into r from public.withdraw_requests where id = p_id;
  if not found then
    raise exception 'withdrawal_not_found' using errcode = '22023';
  end if;
  select * into b from public.bank_accounts where id = r.bank_account_id;
  select * into w from public.wallets where id = r.wallet_id;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'finance.withdraw.read', 'withdraw_requests', r.id, 'Read withdrawal transfer details');
  return kaoid_private.withdrawal_staff_json_r24(r) || jsonb_build_object(
    'account_number', b.account_number, 'branch_name', b.branch_name, 'bank_code', b.bank_code,
    'bank_still_verified', secondhand.withdraw_bank_r27(r) is not distinct from r.bank_account_id
                           and r.bank_account_id is not null,
    'wallet_balance', w.balance, 'wallet_hold', w.hold_balance);
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
  if r.profile_id = u
     or (r.organization_id is not null
         and exists (select 1 from public.organization_members om
                      where om.organization_id = r.organization_id and om.profile_id = u
                        and om.status in ('active', 'invited', 'suspended'))) then
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
       set withdraw_status = 'paid', paid_at = now(), approved_at = now(), transfer_reference = v_ref,
           reviewed_by = u, reviewed_at = now(), updated_at = now()
     where id = r.id
    returning * into r;
    insert into public.activity_logs(profile_id, action, target_table, target_id, description)
    values (u, 'finance.withdraw.paid', 'withdraw_requests', r.id, v_ref);
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
