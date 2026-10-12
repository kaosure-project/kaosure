-- R24: seller withdrawals from the KaoSure Wallet, and central system contents.
--
-- Withdrawals
--   * A member withdraws from the wallet's available balance to the bank
--     account verified in Kao ID. No KYC is needed, no fee is charged and the
--     minimum comes from secondhand.market_settings.withdraw_min_amount (100).
--   * Requesting moves the amount from balance to hold_balance. Staff transfer
--     the money outside the system and record the transfer reference; a
--     rejected or cancelled request returns the amount to the balance.
--   * withdraw_requests never stores a full account number. Staff read it from
--     bank_accounts through withdrawal_detail_r24, which is logged.
--   * Escrow release to the seller is unchanged (complete_order_r22). My Page
--     now shows "pending release" from escrow still holding wallet-paid sales.
--
-- System contents
--   * public.system_contents keeps guidance, warnings, rules, terms and help
--     text per app in Thai and English. Apps read it with get_system_contents;
--     staff with content.system.manage edit it from the Kao ID Admin Hub.
--   * Every change is kept in system_content_revisions and activity_logs.

-- ---------------------------------------------------------------------------
-- Permissions
-- ---------------------------------------------------------------------------
insert into public.permissions
  (category, resource, action, code, name, description, scope, sort_order,
   is_active, is_dangerous, is_immutable, is_deprecated)
values
  ('Finance', 'withdrawals', 'approve', 'wallet.withdraw.approve', 'Wallet Withdrawals Approve',
   'Review wallet withdrawal requests, record bank transfers and reject requests.', 'global', 310,
   true, true, false, false),
  ('Content', 'system_contents', 'manage', 'content.system.manage', 'System Contents Manage',
   'Create, edit and delete guidance, warnings, rules, terms and help contents.', 'global', 320,
   true, false, false, false)
on conflict (code) do update
set is_active = true, is_deprecated = false, updated_at = now();

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
  from public.admin_roles r
 cross join public.permissions p
 where r.code in ('admin', 'super_admin') and r.is_active
   and p.code in ('wallet.withdraw.approve', 'content.system.manage') and p.is_active
   and not exists (select 1 from public.role_permissions rp where rp.role_id = r.id and rp.permission_id = p.id);

-- ---------------------------------------------------------------------------
-- System contents
-- ---------------------------------------------------------------------------
create table public.system_contents (
  id uuid primary key default gen_random_uuid(),
  content_key text not null unique
    check (content_key ~ '^[a-z0-9_]+(\.[a-z0-9_]+)+$' and char_length(content_key) <= 120),
  app_code text not null default 'common' check (app_code ~ '^[a-z][a-z0-9_]{1,39}$'),
  category text not null check (category in ('help', 'guide', 'rule', 'warning', 'terms', 'notice')),
  title jsonb not null check (jsonb_typeof(title) = 'object' and char_length(btrim(coalesce(title->>'th', ''))) > 0),
  body jsonb not null check (jsonb_typeof(body) = 'object' and char_length(btrim(coalesce(body->>'th', ''))) > 0),
  meta jsonb not null default '{}' check (jsonb_typeof(meta) = 'object'),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  version integer not null default 1 check (version > 0),
  created_by uuid references public.profiles(id) on delete set null,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index system_contents_app_category_idx on public.system_contents(app_code, category, sort_order);

create table public.system_content_revisions (
  id bigint generated always as identity primary key,
  content_id uuid not null,
  content_key text not null,
  version integer not null,
  change_kind text not null check (change_kind in ('create', 'update', 'delete')),
  snapshot jsonb not null,
  changed_by uuid references public.profiles(id) on delete set null,
  changed_at timestamptz not null default now()
);
create index system_content_revisions_content_idx on public.system_content_revisions(content_id, version desc);

alter table public.system_contents enable row level security;
alter table public.system_content_revisions enable row level security;
revoke all on table public.system_contents, public.system_content_revisions from public, anon, authenticated;

-- {"th": ..., "en": ...} with trimmed strings, Thai required, at most p_max characters each.
create or replace function kaoid_private.content_text_r24(p_value jsonb, p_max integer)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_key text;
  v_text text;
  v_out jsonb := '{}';
begin
  if p_value is null or jsonb_typeof(p_value) <> 'object' then
    raise exception 'invalid_content' using errcode = '22023';
  end if;
  for v_key in select jsonb_object_keys(p_value) loop
    if v_key not in ('th', 'en') or jsonb_typeof(p_value->v_key) <> 'string' then
      raise exception 'invalid_content' using errcode = '22023';
    end if;
    v_text := btrim(p_value->>v_key);
    if char_length(v_text) > p_max then
      raise exception 'content_too_long' using errcode = '22023';
    end if;
    if v_text <> '' then
      v_out := v_out || jsonb_build_object(v_key, v_text);
    end if;
  end loop;
  if not v_out ? 'th' then
    raise exception 'content_thai_required' using errcode = '22023';
  end if;
  return v_out;
end $$;

-- Thai text of one content for server-made messages, with {name} placeholders filled from p_values.
create or replace function kaoid_private.content_message_r24(p_key text, p_field text, p_values jsonb, p_default text)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_text text;
  v_name text;
begin
  select case p_field when 'title' then c.title->>'th' else c.body->>'th' end into v_text
    from public.system_contents c where c.content_key = p_key and c.is_active;
  v_text := coalesce(v_text, p_default);
  for v_name in select jsonb_object_keys(coalesce(p_values, '{}')) loop
    v_text := replace(v_text, '{' || v_name || '}', coalesce(p_values->>v_name, ''));
  end loop;
  return v_text;
end $$;

create or replace function kaoid_private.content_json_r24(c public.system_contents, p_staff boolean)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object('id', c.id, 'key', c.content_key, 'app', c.app_code, 'category', c.category,
                            'title', c.title, 'body', c.body, 'meta', c.meta, 'sort_order', c.sort_order,
                            'version', c.version, 'updated_at', c.updated_at)
         || case when p_staff then jsonb_build_object(
              'is_active', c.is_active, 'created_at', c.created_at,
              'updated_by_name', (select p.display_name from public.profiles p where p.id = c.updated_by))
            else '{}'::jsonb end;
$$;

-- Active contents of one app plus the shared ("common") ones.
create or replace function public.get_system_contents(p_app text, p_category text default null)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(kaoid_private.content_json_r24(c, false) order by c.sort_order, c.content_key), '[]')
    from public.system_contents c
   where c.is_active and c.app_code in (p_app, 'common')
     and (p_category is null or c.category = p_category);
$$;

-- Staff tools only answer a Kao ID session; tokens issued to other apps never pass.
create or replace function kaoid_private.staff_permission_r24(p_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and nullif(auth.jwt()->>'client_id', '') is null
     and kaoid_private.permission_r13a(p_code);
$$;

create or replace function kaoid_private.content_list_r24(p_app text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not kaoid_private.staff_permission_r24('content.system.manage') then
    raise exception 'content_access_denied' using errcode = '42501';
  end if;
  return (select coalesce(jsonb_agg(kaoid_private.content_json_r24(c, true)
                                    order by c.app_code, c.category, c.sort_order, c.content_key), '[]')
            from public.system_contents c
           where p_app is null or c.app_code = p_app);
end $$;

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
  if p_category is null or p_category not in ('help', 'guide', 'rule', 'warning', 'terms', 'notice')
     or p_active is null or coalesce(p_sort, 0) not between -100000 and 100000 then
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

create or replace function kaoid_private.content_delete_r24(p_id uuid, p_version integer)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
  v_row public.system_contents;
begin
  if not kaoid_private.staff_permission_r24('content.system.manage') then
    raise exception 'content_access_denied' using errcode = '42501';
  end if;
  select * into v_row from public.system_contents c where c.id = p_id for update;
  if not found then
    raise exception 'content_not_found' using errcode = '22023';
  end if;
  if p_version is distinct from v_row.version then
    raise exception 'content_changed' using errcode = '40001';
  end if;
  insert into public.system_content_revisions(content_id, content_key, version, change_kind, snapshot, changed_by)
  values (v_row.id, v_row.content_key, v_row.version, 'delete', kaoid_private.content_json_r24(v_row, false), u);
  delete from public.system_contents where id = p_id;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'content.system.delete', 'system_contents', v_row.id, v_row.content_key || ' v' || v_row.version);
  return true;
end $$;

create or replace function public.content_list_r24(p_app text default null)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.content_list_r24(p_app); $$;
create or replace function public.content_save_r24(
  p_id uuid, p_key text, p_app text, p_category text, p_title jsonb, p_body jsonb, p_meta jsonb,
  p_sort integer, p_active boolean, p_version integer)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.content_save_r24(p_id, p_key, p_app, p_category, p_title, p_body, p_meta, p_sort,
                                             p_active, p_version); $$;
create or replace function public.content_delete_r24(p_id uuid, p_version integer)
returns boolean language sql security invoker set search_path = ''
as $$ select kaoid_private.content_delete_r24(p_id, p_version); $$;

-- ---------------------------------------------------------------------------
-- Withdrawals: data
-- ---------------------------------------------------------------------------
alter table secondhand.market_settings
  add column withdraw_min_amount numeric(12,2) not null default 100 check (withdraw_min_amount >= 1);

alter table public.wallets
  add constraint wallets_amounts_not_negative_r24 check (balance >= 0 and hold_balance >= 0);

alter table public.withdraw_requests
  alter column account_number drop not null,
  add column bank_account_id uuid references public.bank_accounts(id) on delete set null,
  add column account_last4 text check (account_last4 ~ '^[0-9]{1,4}$'),
  add column wallet_transaction_id uuid references public.wallet_transactions(id) on delete set null,
  add column transfer_reference text check (char_length(transfer_reference) <= 100),
  add column reviewed_by uuid references public.profiles(id) on delete set null,
  add column reviewed_at timestamptz,
  add column cancelled_at timestamptz,
  add column source_app text not null default 'secondhand',
  add constraint withdraw_requests_status_r24 check (withdraw_status in ('pending', 'paid', 'rejected', 'cancelled')),
  add constraint withdraw_requests_amount_r24 check (amount > 0 and amount = round(amount, 2)),
  add constraint withdraw_requests_no_full_account_r24 check (account_number is null);

create unique index withdraw_requests_one_pending_r24 on public.withdraw_requests(profile_id)
  where withdraw_status = 'pending';
create index withdraw_requests_status_created_r24 on public.withdraw_requests(withdraw_status, created_at desc);
create index withdraw_requests_profile_created_r24 on public.withdraw_requests(profile_id, created_at desc);

-- The bank account a member's money goes to: the newest one that passes the seller bank rule (R20f/R20g).
create or replace function secondhand.payout_bank_r24(p_profile_id uuid)
returns public.bank_accounts
language sql
stable
security definer
set search_path = ''
as $$
  select ba.*
    from public.financial_verifications fv
    join public.bank_accounts ba on ba.id = fv.bank_account_id
   where fv.identity_type = 'personal' and fv.profile_id = p_profile_id and fv.organization_id is null
     and fv.status = 'approved' and fv.name_match_status = 'matched'
     and ba.profile_id = p_profile_id and ba.organization_id is null
     and ba.is_verified and ba.is_active and ba.deleted_at is null and ba.status = 'verified'
     and kaoid_private.bank_holder_name_ok_r20g(p_profile_id, ba.account_name)
   order by ba.verified_at desc nulls last, ba.created_at desc
   limit 1;
$$;

-- Wallet-paid sales the buyer has paid for and the system still holds.
create or replace function secondhand.pending_release_r24(p_profile_id uuid)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum(o.total_amount), 0)::numeric(12,2)
    from public.orders o
    join secondhand.order_details d on d.order_id = o.id
   where o.seller_id = p_profile_id and d.payment_method = 'wallet'
     and o.escrow_status = 'holding' and o.order_status in ('paid', 'shipped');
$$;

create or replace function secondhand.withdrawal_json_r24(r public.withdraw_requests)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object('id', r.id, 'amount', r.amount, 'status', r.withdraw_status,
                            'bank_name', r.bank_name, 'account_name', r.account_name, 'last4', r.account_last4,
                            'created_at', r.created_at, 'paid_at', r.paid_at, 'rejected_at', r.rejected_at,
                            'cancelled_at', r.cancelled_at, 'reject_reason', r.reject_reason,
                            'transfer_reference', r.transfer_reference);
$$;

-- Puts a pending request's amount back into the balance (member cancel or staff reject).
create or replace function secondhand.return_withdrawal_r24(p_id uuid, p_status text, p_reason text, p_actor uuid)
returns public.withdraw_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.withdraw_requests;
  w public.wallets;
begin
  select * into strict r from public.withdraw_requests where id = p_id for update;
  if r.withdraw_status <> 'pending' then
    raise exception 'withdrawal_not_pending' using errcode = '22023';
  end if;
  select * into strict w from public.wallets where id = r.wallet_id for update;
  if w.hold_balance < r.amount then
    raise exception 'wallet_mismatch' using errcode = '22023';
  end if;
  update public.wallets
     set balance = balance + r.amount, hold_balance = hold_balance - r.amount, updated_at = now()
   where id = w.id;
  update public.wallet_transactions set transaction_status = 'reversed', updated_at = now()
   where id = r.wallet_transaction_id;
  insert into public.wallet_transactions(wallet_id, transaction_type, amount, balance_before, balance_after,
                                         description, transaction_status)
  values (w.id, 'withdraw_return', r.amount, w.balance, w.balance + r.amount,
          case p_status when 'cancelled' then 'ยกเลิกคำขอถอนเงิน' else 'คำขอถอนเงินไม่ผ่าน คืนยอดเข้ากระเป๋า' end,
          'completed');
  update public.withdraw_requests
     set withdraw_status = p_status,
         cancelled_at = case when p_status = 'cancelled' then now() end,
         rejected_at = case when p_status = 'rejected' then now() end,
         reject_reason = case when p_status = 'rejected' then p_reason end,
         reviewed_by = case when p_status = 'rejected' then p_actor end,
         reviewed_at = case when p_status = 'rejected' then now() end,
         updated_at = now()
   where id = r.id
  returning * into r;
  return r;
end $$;

-- ---------------------------------------------------------------------------
-- Withdrawals: member (Secondhand)
-- ---------------------------------------------------------------------------
create or replace function secondhand.get_withdrawal_info()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  w public.wallets;
  b public.bank_accounts;
  r public.withdraw_requests;
  v_min numeric(12,2);
  v_reason text;
begin
  select * into w from public.wallets where profile_id = u;
  b := secondhand.payout_bank_r24(u);
  select s.withdraw_min_amount into v_min from secondhand.market_settings s where s.id;
  select * into r from public.withdraw_requests x where x.profile_id = u and x.withdraw_status = 'pending';
  v_reason := case
    when b.id is null then 'bank_required'
    when w.id is not null and w.wallet_status <> 'active' then 'wallet_unavailable'
    when r.id is not null then 'request_pending'
    when coalesce(w.balance, 0) < v_min then 'balance_too_low'
  end;
  return jsonb_build_object(
    'balance', coalesce(w.balance, 0), 'hold_balance', coalesce(w.hold_balance, 0),
    'pending_release', secondhand.pending_release_r24(u), 'currency', coalesce(w.currency, 'THB'),
    'min_amount', v_min, 'fee', 0,
    'bank', case when b.id is not null then jsonb_build_object(
      'bank_name', b.bank_name, 'account_name', b.account_name, 'last4', right(b.account_number, 4)) end,
    'can_withdraw', v_reason is null, 'reason', v_reason,
    'pending', case when r.id is not null then secondhand.withdrawal_json_r24(r) end);
end $$;

create or replace function secondhand.request_withdrawal(p_amount numeric)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  w public.wallets;
  b public.bank_accounts;
  r public.withdraw_requests;
  v_min numeric(12,2);
  v_tx uuid;
begin
  select s.withdraw_min_amount into v_min from secondhand.market_settings s where s.id;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) or p_amount > 10000000 then
    raise exception 'invalid_amount' using errcode = '22023';
  end if;
  if p_amount < v_min then
    raise exception 'amount_below_minimum' using errcode = '22023';
  end if;
  b := secondhand.payout_bank_r24(u);
  if b.id is null then
    raise exception 'bank_required' using errcode = '42501';
  end if;

  insert into public.wallets(profile_id) values (u) on conflict (profile_id) do nothing;
  select * into strict w from public.wallets where profile_id = u for update;
  if w.wallet_status <> 'active' then
    raise exception 'wallet_unavailable' using errcode = '42501';
  end if;
  if exists (select 1 from public.withdraw_requests x where x.profile_id = u and x.withdraw_status = 'pending') then
    raise exception 'withdrawal_pending' using errcode = '22023';
  end if;
  if w.balance < p_amount then
    raise exception 'insufficient_balance' using errcode = '22023';
  end if;

  update public.wallets
     set balance = balance - p_amount, hold_balance = hold_balance + p_amount, updated_at = now()
   where id = w.id;
  insert into public.wallet_transactions(wallet_id, transaction_type, amount, balance_before, balance_after,
                                         description, transaction_status)
  values (w.id, 'withdraw', p_amount, w.balance, w.balance - p_amount,
          'ถอนเงินเข้าบัญชี ' || b.bank_name || ' ••••' || right(b.account_number, 4), 'pending')
  returning id into v_tx;
  insert into public.withdraw_requests(wallet_id, profile_id, amount, bank_name, account_name, account_number,
                                       bank_account_id, account_last4, wallet_transaction_id, source_app)
  values (w.id, u, p_amount, b.bank_name, b.account_name, null, b.id, right(b.account_number, 4), v_tx, 'secondhand')
  returning * into r;
  return secondhand.withdrawal_json_r24(r);
end $$;

create or replace function secondhand.cancel_withdrawal(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  r public.withdraw_requests;
begin
  select * into r from public.withdraw_requests x where x.id = p_id and x.profile_id = u for update;
  if not found then
    raise exception 'withdrawal_not_found' using errcode = '22023';
  end if;
  if r.withdraw_status = 'cancelled' then
    return secondhand.withdrawal_json_r24(r);
  end if;
  r := secondhand.return_withdrawal_r24(r.id, 'cancelled', null, u);
  return secondhand.withdrawal_json_r24(r);
end $$;

create or replace function secondhand.list_my_withdrawals(p_before timestamptz default null, p_limit integer default 20)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
begin
  return (select coalesce(jsonb_agg(secondhand.withdrawal_json_r24(x) order by x.created_at desc), '[]')
            from (select * from public.withdraw_requests r
                   where r.profile_id = u and (p_before is null or r.created_at < p_before)
                   order by r.created_at desc
                   limit least(greatest(coalesce(p_limit, 20), 1), 50)) x);
end $$;

-- ---------------------------------------------------------------------------
-- Withdrawals: staff (Kao ID Admin Hub)
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.withdraw_staff_r24()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not kaoid_private.staff_permission_r24('wallet.withdraw.approve') then
    raise exception 'withdraw_access_denied' using errcode = '42501';
  end if;
  return auth.uid();
end $$;

create or replace function kaoid_private.withdrawal_staff_json_r24(r public.withdraw_requests)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select secondhand.withdrawal_json_r24(r) || jsonb_build_object(
    'profile_id', r.profile_id, 'source_app', r.source_app, 'reviewed_at', r.reviewed_at,
    'display_name', (select p.display_name from public.profiles p where p.id = r.profile_id),
    'account_code', (select a.account_code from kaoid_private.account_refs_r10c a where a.profile_id = r.profile_id),
    'reviewer_name', (select p.display_name from public.profiles p where p.id = r.reviewed_by));
$$;

create or replace function kaoid_private.withdrawal_queue_r24(p_status text, p_before timestamptz)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform kaoid_private.withdraw_staff_r24();
  if p_status is null or p_status not in ('pending', 'paid', 'rejected', 'cancelled') then
    raise exception 'invalid_status' using errcode = '22023';
  end if;
  return (select coalesce(jsonb_agg(kaoid_private.withdrawal_staff_json_r24(x) order by x.created_at desc), '[]')
            from (select * from public.withdraw_requests r
                   where r.withdraw_status = p_status and (p_before is null or r.created_at < p_before)
                   order by r.created_at desc limit 30) x);
end $$;

-- Full account number for the transfer. Every read is logged.
create or replace function kaoid_private.withdrawal_detail_r24(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
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
    'bank_still_verified', (secondhand.payout_bank_r24(r.profile_id)).id is not distinct from r.bank_account_id
                           and r.bank_account_id is not null,
    'wallet_balance', w.balance, 'wallet_hold', w.hold_balance);
end $$;

create or replace function kaoid_private.withdrawal_review_r24(p_id uuid, p_paid boolean, p_reference text,
                                                               p_reason text)
returns jsonb
language plpgsql
security definer
set search_path = ''
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
  if r.profile_id = u then
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
    if r.bank_account_id is null
       or (secondhand.payout_bank_r24(r.profile_id)).id is distinct from r.bank_account_id then
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
begin
  return jsonb_build_object(
    'withdrawals', v_withdrawals,
    'contents', v_contents,
    'pending_withdrawals', case when v_withdrawals then
      (select count(*) from public.withdraw_requests r where r.withdraw_status = 'pending') end);
end $$;

create or replace function public.staff_tools_r24()
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.staff_tools_r24(); $$;
create or replace function public.withdrawal_queue_r24(p_status text default 'pending', p_before timestamptz default null)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.withdrawal_queue_r24(p_status, p_before); $$;
create or replace function public.withdrawal_detail_r24(p_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.withdrawal_detail_r24(p_id); $$;
create or replace function public.withdrawal_review_r24(p_id uuid, p_paid boolean, p_reference text default null,
                                                        p_reason text default null)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.withdrawal_review_r24(p_id, p_paid, p_reference, p_reason); $$;

-- ---------------------------------------------------------------------------
-- Seed contents (Thai and English). Staff edit them from the Admin Hub.
-- ---------------------------------------------------------------------------
insert into public.system_contents(content_key, app_code, category, title, body, meta, sort_order) values
  ('secondhand.help.buying', 'secondhand', 'help', jsonb_build_object('th', $c$การซื้อสินค้า$c$, 'en', $c$Buying$c$),
   jsonb_build_object('th', $c$กด "ซื้อสินค้า" ได้ทันทีจากหน้าสินค้า ไม่มีตะกร้าสินค้า ผู้ขายรับผิดชอบค่าจัดส่ง
ต้องยืนยันอีเมลและเบอร์โทรศัพท์ใน Kao ID ก่อนซื้อ และซื้อจากผู้ที่บล็อกกันอยู่ไม่ได้
ไม่มีการจองสินค้า ใครชำระเงินสำเร็จก่อนได้สินค้าไป สินค้าจะขึ้น SOLD เมื่อมีผู้ชำระเงินแล้วเท่านั้น
ถ้ามีผู้อื่นชำระเงินก่อน คำสั่งซื้อที่ยังไม่ได้ชำระจะถูกยกเลิกอัตโนมัติ คำสั่งซื้อที่ไม่ได้ชำระภายใน 24 ชั่วโมงก็จะยกเลิกเช่นกัน
ชำระด้วยยอดเงินใน KaoSure Wallet ได้เมื่อยอดเงินพอ
เงินค่าสินค้าจะถูกพักไว้กับระบบ (Escrow) และโอนให้ผู้ขายหลังคุณกด "ได้รับสินค้าแล้ว"
ถ้าไม่ได้กดยืนยัน ระบบจะยืนยันรับสินค้าให้อัตโนมัติ 7 วันหลังผู้ขายจัดส่ง
ยกเลิกได้ก่อนชำระเงิน หรือหลังชำระแล้วถ้าผู้ขายไม่จัดส่งภายในเวลาที่กำหนด โดยระบบคืนเงินให้
ถ้าผู้ขายเปลี่ยนราคาหรือปิดการขาย คำสั่งซื้อที่ยังไม่ได้ชำระจะถูกยกเลิก สั่งซื้อใหม่ได้ถ้ายังสนใจ
ดูคำสั่งซื้อทั้งหมดได้ที่ หน้าของฉัน > สินค้าที่ซื้อ$c$,
                      'en', $c$Tap "Buy now" on an item page. There's no cart, and the seller pays for shipping.
Verify your email and phone number in Kao ID before buying. You can't buy from someone you've blocked or who blocked you.
Items can't be reserved. Whoever pays first gets the item, and it shows SOLD only once someone has paid.
If someone else pays first, your unpaid order is cancelled automatically. Orders not paid within 24 hours are cancelled too.
You can pay from your KaoSure Wallet when the balance is enough.
Your payment is held by the system (escrow) and goes to the seller after you tap "I received the item".
If you don't confirm, receipt is confirmed automatically 7 days after the seller ships.
You can cancel before paying, or after paying if the seller doesn't ship in time, and the system refunds you.
If the seller changes the price or closes the listing, unpaid orders are cancelled. Order again if you're still interested.
See all your orders in My page > Purchases.$c$),
   '{"icon": "shopping_bag"}', 10),
  ('secondhand.help.offers', 'secondhand', 'help', jsonb_build_object('th', $c$การขอลดราคา$c$, 'en', $c$Price offers$c$),
   jsonb_build_object('th', $c$เลือกขอลดได้ 3%, 5%, 7% หรือ 9% ระบบคำนวณราคาให้อัตโนมัติ
เปิดข้อเสนอได้ครั้งละ 1 รายการต่อสินค้า และขอใหม่ได้เมื่อข้อเสนอเดิมหมดเวลาหรือถูกปฏิเสธ
ผู้ขายมีเวลาตอบ 24 ชั่วโมง ถ้าไม่ตอบ ข้อเสนอจะยกเลิกอัตโนมัติ
เมื่อผู้ขายยอมรับ คุณซื้อในราคาพิเศษได้ภายใน 24 ชั่วโมง
ราคาพิเศษเห็นและใช้ได้เฉพาะคุณกับผู้ขาย ผู้ซื้อคนอื่นยังเห็นราคาเต็ม
การยอมรับข้อเสนอไม่ใช่การจองสินค้า ถ้ามีผู้อื่นชำระเงินในราคาเต็มก่อน สินค้าจะเป็นของผู้นั้นและข้อเสนอของคุณจะสิ้นสุด$c$,
                      'en', $c$Ask for 3%, 5%, 7% or 9% off; the price is worked out for you.
You can have one open offer per item, and make a new one once the last expires or is declined.
The seller has 24 hours to answer. Without an answer the offer is cancelled automatically.
Once the seller accepts, you can buy at the special price within 24 hours.
Only you and the seller see and can use the special price; other buyers still see the full price.
An accepted offer doesn't reserve the item. If someone pays the full price first, the item is theirs and your offer ends.$c$),
   '{"icon": "local_offer"}', 20),
  ('secondhand.help.selling', 'secondhand', 'help', jsonb_build_object('th', $c$การลงขาย$c$, 'en', $c$Selling$c$),
   jsonb_build_object('th', $c$1 บัญชีมีร้านค้าได้ 1 ร้าน
ยืนยันอีเมล เบอร์โทรศัพท์ และบัญชีรับเงินใน Kao ID แล้วลงขายได้ภายในราคาต่อชิ้นที่ตลาดกำหนด
ยืนยันตัวตนกับ Kao ID (KYC) แล้วจะได้ป้าย "ยืนยันตัวตนแล้ว" และลงขายได้เต็มวงเงินของตลาด
สินค้าที่ขายแล้วยังแสดงในร้านพร้อมป้าย SOLD$c$,
                      'en', $c$One account can have one shop.
Verify your email, phone number and payout account in Kao ID to list items up to the market's per-item price limit.
Verify your identity (KYC) with Kao ID to get the "Verified" badge and list up to the market's full limit.
Sold items stay in your shop with a SOLD label.$c$),
   '{"icon": "sell"}', 30),
  ('secondhand.help.sales', 'secondhand', 'help', jsonb_build_object('th', $c$ยอดขายและการรับเงิน$c$, 'en', $c$Sales and payouts$c$),
   jsonb_build_object('th', $c$สินค้ายังขายอยู่จนกว่าจะมีผู้ซื้อชำระเงินสำเร็จ คุณจะได้รับแจ้งเมื่อขายได้
เมื่อผู้ซื้อชำระเงินแล้ว กรุณาจัดส่งภายในระยะเวลาที่ตั้งไว้ในประกาศ แล้วกด "แจ้งจัดส่งแล้ว" พร้อมชื่อขนส่ง
ที่อยู่ผู้ซื้อจะแสดงหลังผู้ซื้อชำระเงินแล้วเท่านั้น
เงินค่าสินค้าจะถูกพักไว้กับระบบ และเข้ายอดขายของคุณ (หักค่าธรรมเนียมการขาย) หลังผู้ซื้อยืนยันว่าได้รับสินค้า หรือครบ 7 วันหลังจัดส่ง
"รอปล่อยเงิน" คือยอดที่ยังพักไว้ระหว่างการจัดส่ง
ผู้ขายยกเลิกคำสั่งซื้อได้ก่อนจัดส่ง ระบบจะคืนเงินให้ผู้ซื้อและปิดการขายสินค้าไว้ก่อน
บัญชีรับเงินยืนยันและแก้ไขที่ Kao ID เท่านั้น
ถอนยอดเงินเข้าบัญชีที่ยืนยันแล้วได้ที่ หน้าของฉัน > กระเป๋าเงิน > ถอนเงิน ขั้นต่ำ ฿100 ต่อครั้ง ไม่มีค่าธรรมเนียม$c$,
                      'en', $c$An item stays on sale until a buyer pays. You'll be notified when it sells.
Once the buyer has paid, ship within the time set in your listing, then tap "Mark as shipped" with the carrier name.
The buyer's address is shown only after they pay.
The payment is held by the system and added to your sales (minus the sales fee) after the buyer confirms receipt, or 7 days after shipping.
"Pending release" is money still held while the item is on its way.
Sellers can cancel an order before shipping. The buyer is refunded and the listing is closed for now.
Your payout account is verified and changed in Kao ID only.
Withdraw your balance to your verified account from My page > Wallet > Withdraw. The minimum is ฿100 per request and there's no fee.$c$),
   '{"icon": "payments"}', 40),
  ('secondhand.help.questions', 'secondhand', 'help', jsonb_build_object('th', $c$คำถามและการติดต่อ$c$, 'en', $c$Questions and contact$c$),
   jsonb_build_object('th', $c$ก่อนซื้อ ถามผู้ขายผ่านช่องคำถามใต้สินค้าซึ่งทุกคนเห็นได้
คำถามและคำตอบแก้ไขหรือลบไม่ได้หลังส่งแล้ว
แชตส่วนตัวกับผู้ขายเปิดในหน้าคำสั่งซื้อหลังผู้ซื้อชำระเงินแล้ว เห็นเฉพาะผู้ซื้อกับผู้ขาย
ห้ามส่งเบอร์โทร ไลน์ อีเมล ลิงก์ หรือเลขบัญชีในแชต ระบบจะไม่ส่งข้อความนั้น และอย่าโอนเงินนอกระบบ
ผู้ขายแจ้งเลขพัสดุผ่านปุ่ม "แจ้งจัดส่งแล้ว" ไม่ต้องส่งในแชต
เมื่อการซื้อขายเสร็จสมบูรณ์หรือถูกยกเลิก แชตจะปิดและดูข้อความย้อนหลังได้อย่างเดียว$c$,
                      'en', $c$Before buying, ask the seller in the questions section under the item, which everyone can see.
Questions and answers can't be edited or deleted once sent.
Private chat with the seller opens on the order page after the buyer pays. Only the buyer and seller see it.
Don't send phone numbers, LINE IDs, emails, links or account numbers in chat; such messages aren't sent. Never pay outside the system.
Sellers add the tracking number with "Mark as shipped", not in chat.
When the trade completes or is cancelled, the chat closes and stays readable only.$c$),
   '{"icon": "forum"}', 50),
  ('secondhand.help.reviews', 'secondhand', 'help', jsonb_build_object('th', $c$การประเมิน (รีวิว)$c$, 'en', $c$Reviews$c$),
   jsonb_build_object('th', $c$หลังซื้อขายเสร็จ ผู้ซื้อและผู้ขายประเมินกันได้ฝ่ายละ 1 ครั้ง เลือก "ดี" หรือ "ไม่ดี" และเขียนข้อความเพิ่มได้
ส่งการประเมินแล้วจะแก้ไขหรือลบไม่ได้ทุกกรณี กรุณาตรวจให้แน่ใจก่อนกดส่ง
ดาวแสดงเฉพาะที่หัวโปรไฟล์ คิดจากสัดส่วนการประเมิน "ดี" ทั้งหมด เช่น ดี 9 ไม่ดี 1 ได้ 4.5 ดาว
ดูการประเมินทั้งหมดได้โดยกดที่ดาว แยกเป็นแท็บ ทั้งหมด / ดี / ไม่ดี$c$,
                      'en', $c$After a trade, the buyer and seller can each review the other once: choose "Good" or "Bad" and add a message if you like.
Reviews can't be edited or deleted for any reason, so check before you send.
Stars appear only on the profile header, from the share of "Good" reviews; for example 9 good and 1 bad is 4.5 stars.
Tap the stars to see every review, in All / Good / Bad tabs.$c$),
   '{"icon": "rate_review"}', 60),
  ('secondhand.help.safety', 'secondhand', 'help', jsonb_build_object('th', $c$ความปลอดภัย$c$, 'en', $c$Safety$c$),
   jsonb_build_object('th', $c$ชำระเงินผ่านระบบเท่านั้น อย่าโอนเงินนอกระบบ
พบสินค้าไม่เหมาะสม กด "รายงาน" ที่หน้าสินค้าได้
ข้อมูลตัวตนและบัญชีธนาคารจัดการที่ Kao ID เท่านั้น$c$,
                      'en', $c$Pay only through the system. Never transfer money outside it.
If an item looks wrong, tap "Report" on the item page.
Identity and bank details are managed in Kao ID only.$c$),
   '{"icon": "shield"}', 70),
  ('secondhand.help.blocking', 'secondhand', 'help', jsonb_build_object('th', $c$การบล็อกผู้ใช้$c$, 'en', $c$Blocking users$c$),
   jsonb_build_object('th', $c$บล็อกผู้ใช้ได้จากหน้าร้านค้า หรือจากข้อเสนอขอลดราคาในสินค้าของคุณ
เมื่อบล็อกแล้ว ทั้งสองฝ่ายจะขอลดราคาหรือถามคำถามในสินค้าของอีกฝ่ายไม่ได้
ข้อเสนอที่ค้างอยู่ระหว่างกันจะถูกยกเลิก และอีกฝ่ายจะไม่ได้รับแจ้ง
ดูรายชื่อและเลิกบล็อกได้ที่ หน้าของฉัน > ผู้ใช้ที่บล็อก$c$,
                      'en', $c$Block a user from their shop page, or from a price offer on your item.
Once blocked, neither of you can make offers or ask questions on the other's items.
Open offers between you are cancelled, and the other person isn't told.
See the list and unblock in My page > Blocked users.$c$),
   '{"icon": "block"}', 80),
  ('secondhand.withdraw.rules', 'secondhand', 'rule',
   jsonb_build_object('th', $c$เงื่อนไขการถอนเงิน$c$, 'en', $c$Withdrawal rules$c$),
   jsonb_build_object('th', $c$ถอนได้จากยอดเงินที่พร้อมใช้ใน KaoSure Wallet ขั้นต่ำ ฿100 ต่อครั้ง ไม่มีค่าธรรมเนียม
เงินจะโอนเข้าบัญชีธนาคารที่ยืนยันแล้วใน Kao ID เท่านั้น ไม่ต้องยืนยันตัวตน (KYC) เพิ่ม
ระหว่างรอโอน ยอดที่ถอนจะแสดงเป็น "กำลังโอนเข้าบัญชี" และนำไปใช้ซื้อสินค้าไม่ได้
มีคำขอถอนที่รอดำเนินการได้ครั้งละ 1 รายการ และยกเลิกเองได้จนกว่าเจ้าหน้าที่จะดำเนินการ
ถ้าคำขอไม่ผ่าน ยอดเงินจะคืนเข้า KaoSure Wallet ทันทีพร้อมแจ้งเหตุผล$c$,
                      'en', $c$You can withdraw the available balance of your KaoSure Wallet: at least ฿100 per request, with no fee.
Money goes only to the bank account verified in Kao ID. No extra identity check (KYC) is needed.
While it's being transferred, the amount shows as "Transferring to bank" and can't be used to buy.
You can have one pending request at a time and cancel it until staff process it.
If a request is declined, the amount returns to your KaoSure Wallet at once, with the reason.$c$),
   '{"icon": "account_balance"}', 10),
  ('secondhand.withdraw.warning', 'secondhand', 'warning',
   jsonb_build_object('th', $c$ระวังมิจฉาชีพ$c$, 'en', $c$Beware of scams$c$),
   jsonb_build_object('th', $c$KaoSure ไม่ขอรหัสผ่าน รหัส OTP หรือให้โอนเงินเพื่อปลดล็อกการถอนเงิน อย่าแจ้งข้อมูลเหล่านี้กับผู้ใด$c$,
                      'en', $c$KaoSure never asks for your password, an OTP, or a transfer to unlock a withdrawal. Never share these with anyone.$c$),
   '{"icon": "warning"}', 20),
  ('secondhand.notice.withdraw_paid', 'secondhand', 'notice',
   jsonb_build_object('th', $c$โอนเงินเข้าบัญชีแล้ว$c$, 'en', $c$Money sent to your bank$c$),
   jsonb_build_object('th', $c$โอน ฿{amount} เข้าบัญชี {bank} ••••{last4} แล้ว$c$,
                      'en', $c$฿{amount} was sent to {bank} ••••{last4}.$c$),
   '{"placeholders": ["amount", "bank", "last4"]}', 100),
  ('secondhand.notice.withdraw_rejected', 'secondhand', 'notice',
   jsonb_build_object('th', $c$คำขอถอนเงินไม่ผ่าน$c$, 'en', $c$Withdrawal declined$c$),
   jsonb_build_object('th', $c$ยอด ฿{amount} คืนเข้า KaoSure Wallet แล้ว เหตุผล: {reason}$c$,
                      'en', $c$฿{amount} is back in your KaoSure Wallet. Reason: {reason}$c$),
   '{"placeholders": ["amount", "reason"]}', 110);

-- ---------------------------------------------------------------------------
-- My Page: "pending release" comes from escrow still holding wallet-paid sales;
-- hold_balance is money on its way to the member's bank account.
-- ---------------------------------------------------------------------------
create or replace function secondhand.get_my_page()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
  v_shop uuid;
  v_todo jsonb;
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.data_access_r10d() then
    raise exception 'Account unavailable' using errcode = '42501';
  end if;

  select s.id into v_shop
    from public.shops s
   where s.owner_id = u and s.seller_identity_type = 'personal'
   order by s.created_at
   limit 1;

  select coalesce(jsonb_agg(t.item order by t.ord), '[]'::jsonb) into v_todo
    from (
      select 0 as ord, count(*) as n, jsonb_build_object(
               'code', 'pay_orders', 'count', count(*),
               'order_id', (array_agg(o.id order by d.pay_by))[1],
               'due_at', min(d.pay_by)) as item
        from public.orders o join secondhand.order_details d on d.order_id = o.id
       where o.buyer_id = u and o.order_status = 'pending' and d.pay_by > now()
      union all
      select 0, count(*), jsonb_build_object(
               'code', 'ship_orders', 'count', count(*),
               'order_id', (array_agg(o.id order by d.ship_by))[1],
               'due_at', min(d.ship_by))
        from public.orders o join secondhand.order_details d on d.order_id = o.id
       where o.seller_id = u and o.order_status = 'paid'
      union all
      select 0, count(*), jsonb_build_object(
               'code', 'confirm_receipt', 'count', count(*),
               'order_id', (array_agg(o.id order by d.receive_by))[1],
               'due_at', min(d.receive_by))
        from public.orders o join secondhand.order_details d on d.order_id = o.id
       where o.buyer_id = u and o.order_status = 'shipped'
      union all
      select 1, count(*), jsonb_build_object(
               'code', 'answer_offers', 'count', count(*),
               'product_id', (array_agg(o.product_id order by o.expires_at))[1],
               'due_at', min(o.expires_at))
        from secondhand.price_offers o
       where o.seller_id = u and o.status = 'pending' and o.expires_at > now()
      union all
      select 2, count(*), jsonb_build_object(
               'code', 'buy_offer', 'count', count(*),
               'product_id', (array_agg(o.product_id order by o.purchase_expires_at))[1],
               'due_at', min(o.purchase_expires_at))
        from secondhand.price_offers o
       where o.buyer_id = u and o.status = 'accepted' and o.purchase_expires_at > now()
      union all
      select 3, count(*), jsonb_build_object(
               'code', 'answer_questions', 'count', count(*),
               'product_id', (array_agg(q.product_id order by q.created_at))[1],
               'since', min(q.created_at))
        from secondhand.listing_questions q
        join public.products p on p.id = q.product_id
        join secondhand.listings l on l.product_id = p.id
       where l.seller_id = u and q.answer is null and not q.is_hidden and p.status = 'active'
      union all
      select 4, count(*), jsonb_build_object(
               'code', 'write_reviews', 'count', count(*),
               'order_id', (array_agg(o.id order by coalesce(o.completed_at, o.created_at)))[1])
        from public.orders o
       where u in (o.buyer_id, o.seller_id)
         and (o.order_status = 'completed' or o.completed_at is not null)
         and not exists (select 1 from secondhand.reviews r where r.order_id = o.id and r.reviewer_id = u)
      union all
      select 5, count(*), jsonb_build_object('code', 'unread_notifications', 'count', count(*))
        from public.notifications n
       where n.profile_id = u and not coalesce(n.is_read, false) and not coalesce(n.is_deleted, false)
         and (n.expires_at is null or n.expires_at > now())
    ) t
   where t.n > 0;

  return jsonb_build_object(
    'profile', (
      select jsonb_build_object(
        'display_name', coalesce(nullif(btrim(m.display_name), ''), nullif(btrim(p.display_name), ''), 'สมาชิก KaoSure'),
        'avatar_url', m.avatar_url,
        'bio', m.bio,
        'joined_at', coalesce(m.created_at, p.created_at),
        'shop_id', v_shop)
        from public.profiles p
        left join secondhand.member_profiles m on m.profile_id = p.id
       where p.id = u),
    'account_active', kaoid_private.account_active_r9f(),
    'seller_status', secondhand.seller_status_r20f(u),
    'rating', (
      select jsonb_build_object(
        'rating', r.rating,
        'review_count', coalesce(r.review_count, 0),
        'good_count', coalesce(r.good_count, 0),
        'bad_count', coalesce(r.bad_count, 0))
        from (select 1) one
        left join secondhand.member_ratings r on r.profile_id = u),
    'wallet', (
      select jsonb_build_object('balance', w.balance, 'hold_balance', w.hold_balance,
                                'pending_release', secondhand.pending_release_r24(u),
                                'currency', w.currency, 'status', w.wallet_status)
        from public.wallets w where w.profile_id = u),
    'counts', jsonb_build_object(
      'on_sale', (select count(*) from public.products p join secondhand.listings l on l.product_id = p.id
                   where l.seller_id = u and p.status = 'active' and p.is_active and p.stock > 0),
      'closed', (select count(*) from public.products p join secondhand.listings l on l.product_id = p.id
                  where l.seller_id = u and p.status = 'closed'),
      'selling', (select count(*) from public.orders o where o.seller_id = u and o.paid_at is not null
                   and o.order_status not in ('cancelled', 'completed', 'refunded')),
      'sold', (select count(*) from public.orders o where o.seller_id = u and o.order_status = 'completed'),
      'buying', (select count(*) from public.orders o where o.buyer_id = u
                  and coalesce(o.order_status, 'pending') not in ('cancelled', 'completed', 'refunded')),
      'purchased', (select count(*) from public.orders o where o.buyer_id = u and o.order_status = 'completed'),
      'favorites', (select count(*) from public.favorites f where f.profile_id = u),
      'following', (select count(*) from public.followers f where f.profile_id = u),
      'drafts', (select count(*) from secondhand.listing_drafts d where d.seller_id = u),
      'unread_notifications', (select count(*) from public.notifications n
                                where n.profile_id = u and not coalesce(n.is_read, false)
                                  and not coalesce(n.is_deleted, false)
                                  and (n.expires_at is null or n.expires_at > now())),
      'shipping_addresses', (select count(*) from secondhand.shipping_addresses a
                              where a.profile_id = u and a.address_type = 'shipping'),
      'return_addresses', (select count(*) from secondhand.shipping_addresses a
                            where a.profile_id = u and a.address_type = 'return'),
      'blocked_users', (select count(*) from public.user_blocks b
                         where b.blocker_profile_id = u and coalesce(b.is_active, true)
                           and (b.expires_at is null or b.expires_at > now()))),
    'todo', v_todo
  );
end $$;

-- ---------------------------------------------------------------------------
-- Grants and app scope
-- ---------------------------------------------------------------------------
revoke all on function kaoid_private.content_text_r24(jsonb, integer) from public, anon, authenticated;
revoke all on function kaoid_private.content_message_r24(text, text, jsonb, text) from public, anon, authenticated;
revoke all on function kaoid_private.content_json_r24(public.system_contents, boolean) from public, anon, authenticated;
revoke all on function secondhand.payout_bank_r24(uuid) from public, anon, authenticated;
revoke all on function secondhand.pending_release_r24(uuid) from public, anon, authenticated;
revoke all on function secondhand.withdrawal_json_r24(public.withdraw_requests) from public, anon, authenticated;
revoke all on function secondhand.return_withdrawal_r24(uuid, text, text, uuid) from public, anon, authenticated;
revoke all on function kaoid_private.withdraw_staff_r24() from public, anon, authenticated;
revoke all on function kaoid_private.staff_permission_r24(text) from public, anon, authenticated;
revoke all on function kaoid_private.withdrawal_staff_json_r24(public.withdraw_requests) from public, anon, authenticated;

revoke all on function public.get_system_contents(text, text) from public, anon, authenticated;
grant execute on function public.get_system_contents(text, text) to anon, authenticated;

revoke all on function kaoid_private.content_list_r24(text), kaoid_private.content_save_r24(uuid, text, text, text, jsonb, jsonb, jsonb, integer, boolean, integer),
  kaoid_private.content_delete_r24(uuid, integer), kaoid_private.withdrawal_queue_r24(text, timestamptz),
  kaoid_private.withdrawal_detail_r24(uuid), kaoid_private.withdrawal_review_r24(uuid, boolean, text, text),
  kaoid_private.staff_tools_r24(),
  public.content_list_r24(text), public.content_save_r24(uuid, text, text, text, jsonb, jsonb, jsonb, integer, boolean, integer),
  public.content_delete_r24(uuid, integer), public.withdrawal_queue_r24(text, timestamptz),
  public.withdrawal_detail_r24(uuid), public.withdrawal_review_r24(uuid, boolean, text, text),
  public.staff_tools_r24()
  from public, anon;
grant execute on function kaoid_private.content_list_r24(text), kaoid_private.content_save_r24(uuid, text, text, text, jsonb, jsonb, jsonb, integer, boolean, integer),
  kaoid_private.content_delete_r24(uuid, integer), kaoid_private.withdrawal_queue_r24(text, timestamptz),
  kaoid_private.withdrawal_detail_r24(uuid), kaoid_private.withdrawal_review_r24(uuid, boolean, text, text),
  kaoid_private.staff_tools_r24(),
  public.content_list_r24(text), public.content_save_r24(uuid, text, text, text, jsonb, jsonb, jsonb, integer, boolean, integer),
  public.content_delete_r24(uuid, integer), public.withdrawal_queue_r24(text, timestamptz),
  public.withdrawal_detail_r24(uuid), public.withdrawal_review_r24(uuid, boolean, text, text),
  public.staff_tools_r24()
  to authenticated;

revoke all on function secondhand.get_withdrawal_info() from public, anon, authenticated;
revoke all on function secondhand.request_withdrawal(numeric) from public, anon, authenticated;
revoke all on function secondhand.cancel_withdrawal(uuid) from public, anon, authenticated;
revoke all on function secondhand.list_my_withdrawals(timestamptz, integer) from public, anon, authenticated;
revoke all on function secondhand.get_my_page() from public, anon, authenticated;
grant execute on function secondhand.get_withdrawal_info() to authenticated;
grant execute on function secondhand.request_withdrawal(numeric) to authenticated;
grant execute on function secondhand.cancel_withdrawal(uuid) to authenticated;
grant execute on function secondhand.list_my_withdrawals(timestamptz, integer) to authenticated;
grant execute on function secondhand.get_my_page() to authenticated;

-- Secondhand reads contents and requests withdrawals with its app token; staff tools stay first-party only.
update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
                              'public.get_system_contents', 'secondhand.get_withdrawal_info',
                              'secondhand.request_withdrawal', 'secondhand.cancel_withdrawal',
                              'secondhand.list_my_withdrawals']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';