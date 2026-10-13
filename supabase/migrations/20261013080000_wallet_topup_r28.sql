-- R28: KaoSure Wallet top-up by PromptPay transfer with a slip reviewed by staff.
--
--   * Only members with an active personal Kao ID may top up their personal wallet
--     (organization wallets come later). Kao ID and Secondhand call the same RPCs.
--   * The member chooses an amount and gets a PromptPay QR (EMVCo payload built
--     here) for the receiving account staff set in the Admin Hub. Top-up stays off
--     until that account is set. The member then attaches the transfer slip.
--   * Staff with wallet.deposit.approve check the slip, confirm the payer is the
--     member named in Kao ID and record the bank reference. Amounts from the
--     dual-review threshold need a second, different reviewer. Approval credits
--     wallets.balance and writes one 'deposit' wallet_transactions row in the same
--     transaction. Every staff action needs fresh MFA and is logged.
--   * Slips live in the private wallet-slips bucket: the member writes only into
--     their own open request folder, staff with the permission read them.

-- ---------------------------------------------------------------------------
-- Permissions
-- ---------------------------------------------------------------------------
insert into public.permissions
  (category, resource, action, code, name, description, scope, sort_order,
   is_active, is_dangerous, is_immutable, is_deprecated)
values
  ('Finance', 'deposits', 'approve', 'wallet.deposit.approve', 'Wallet Top-ups Approve',
   'Review wallet top-up slips and approve or reject the amount.', 'global', 330,
   true, true, false, false),
  ('Finance', 'deposits', 'settings', 'wallet.deposit.settings', 'Wallet Top-up Settings',
   'Set the PromptPay receiving account and top-up limits.', 'global', 340,
   true, true, false, false)
on conflict (code) do update
set is_active = true, is_deprecated = false, updated_at = now();

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
  from public.admin_roles r
 cross join public.permissions p
 where r.code in ('admin', 'super_admin') and r.is_active
   and p.code in ('wallet.deposit.approve', 'wallet.deposit.settings') and p.is_active
   and not exists (select 1 from public.role_permissions rp where rp.role_id = r.id and rp.permission_id = p.id);

-- ---------------------------------------------------------------------------
-- Data
-- ---------------------------------------------------------------------------
create table kaoid_private.topup_settings_r28 (
  id boolean primary key default true check (id),
  enabled boolean not null default false,
  promptpay_type text check (promptpay_type in ('phone', 'national_id', 'ewallet')),
  promptpay_id text,
  receiver_name text check (char_length(receiver_name) <= 120),
  min_amount numeric(12,2) not null default 100 check (min_amount >= 1),
  max_amount numeric(12,2) not null default 50000,
  daily_max numeric(12,2) not null default 200000,
  dual_review_from numeric(12,2) not null default 50000 check (dual_review_from >= 1),
  slip_hours integer not null default 24 check (slip_hours between 1 and 72),
  version integer not null default 1 check (version > 0),
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  check (max_amount >= min_amount and max_amount <= 1000000 and daily_max >= max_amount and daily_max <= 10000000),
  check (not enabled or (promptpay_type is not null and promptpay_id is not null
                         and char_length(btrim(coalesce(receiver_name, ''))) > 0)),
  check (promptpay_id is null or promptpay_id ~ case promptpay_type when 'phone' then '^0[0-9]{9}$'
                                                                   when 'national_id' then '^[0-9]{13}$'
                                                                   else '^[0-9]{15}$' end)
);
insert into kaoid_private.topup_settings_r28(id) values (true);
revoke all on table kaoid_private.topup_settings_r28 from public, anon, authenticated;

create table public.topup_requests (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete restrict,
  wallet_id uuid not null references public.wallets(id) on delete restrict,
  amount numeric(12,2) not null check (amount > 0 and amount = round(amount, 2)),
  status text not null default 'awaiting_slip'
    check (status in ('awaiting_slip', 'pending_review', 'awaiting_second', 'approved', 'rejected', 'cancelled',
                      'expired')),
  source_app text not null check (source_app in ('kaoid', 'secondhand')),
  promptpay_type text not null,
  promptpay_id text not null,
  receiver_name text not null,
  qr_payload text not null,
  dual_review boolean not null,
  expires_at timestamptz not null,
  slip_path text,
  slip_etag text,
  slip_size bigint,
  slip_uploaded_at timestamptz,
  first_reviewer uuid references public.profiles(id) on delete set null,
  first_reference text,
  first_reviewed_at timestamptz,
  bank_reference text check (char_length(bank_reference) between 3 and 100),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  reject_reason text check (char_length(reject_reason) between 3 and 500),
  wallet_transaction_id uuid references public.wallet_transactions(id) on delete set null,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((status in ('awaiting_slip', 'cancelled', 'expired')) or slip_path is not null),
  check (status <> 'approved' or (wallet_transaction_id is not null and bank_reference is not null))
);
create unique index topup_requests_one_open_r28 on public.topup_requests(profile_id)
  where status in ('awaiting_slip', 'pending_review', 'awaiting_second');
create unique index topup_requests_reference_r28 on public.topup_requests(lower(coalesce(bank_reference, first_reference)))
  where status in ('awaiting_second', 'approved');
create index topup_requests_status_created_r28 on public.topup_requests(status, created_at desc);
create index topup_requests_profile_created_r28 on public.topup_requests(profile_id, created_at desc);
create index topup_requests_slip_etag_r28 on public.topup_requests(slip_etag) where slip_etag is not null;

alter table public.topup_requests enable row level security;
revoke all on table public.topup_requests from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Slip storage
-- ---------------------------------------------------------------------------
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('wallet-slips', 'wallet-slips', false, 5242880, array['image/jpeg'])
on conflict (id) do update
set public = false, file_size_limit = 5242880, allowed_mime_types = array['image/jpeg'];

-- "<owner>/<request>/slip.jpg" for the member's own request that still waits for its slip.
create or replace function kaoid_private.topup_slip_upload_ok_r28(p_name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1 from public.topup_requests r
     where r.profile_id = auth.uid() and r.status = 'awaiting_slip' and r.expires_at > now()
       and p_name = r.profile_id::text || '/' || r.id::text || '/slip.jpg');
$$;

create or replace function kaoid_private.topup_slip_staff_read_r28(p_name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select kaoid_private.staff_permission_r24('wallet.deposit.approve')
     and exists (select 1 from public.topup_requests r where r.slip_path = p_name);
$$;

revoke all on function kaoid_private.topup_slip_upload_ok_r28(text), kaoid_private.topup_slip_staff_read_r28(text)
  from public, anon;
grant execute on function kaoid_private.topup_slip_upload_ok_r28(text), kaoid_private.topup_slip_staff_read_r28(text)
  to authenticated;

create policy wallet_slips_insert_own_r28 on storage.objects for insert to authenticated
  with check (bucket_id = 'wallet-slips' and kaoid_private.topup_slip_upload_ok_r28(name));
create policy wallet_slips_select_own_r28 on storage.objects for select to authenticated
  using (bucket_id = 'wallet-slips' and owner_id = (select auth.uid()::text));
create policy wallet_slips_staff_read_r28 on storage.objects for select to authenticated
  using (bucket_id = 'wallet-slips' and kaoid_private.topup_slip_staff_read_r28(name));

-- ---------------------------------------------------------------------------
-- PromptPay QR (EMVCo merchant-presented, dynamic with amount)
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.crc16_ccitt_r28(p_text text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_bytes bytea := convert_to(p_text, 'UTF8');
  v_crc integer := 65535;
  i integer;
  j integer;
begin
  for i in 0 .. length(v_bytes) - 1 loop
    v_crc := v_crc # (get_byte(v_bytes, i) << 8);
    for j in 1 .. 8 loop
      if (v_crc & 32768) <> 0 then
        v_crc := ((v_crc << 1) # 4129) & 65535;
      else
        v_crc := (v_crc << 1) & 65535;
      end if;
    end loop;
  end loop;
  return upper(lpad(to_hex(v_crc), 4, '0'));
end $$;

create or replace function kaoid_private.emv_tlv_r28(p_tag text, p_value text)
returns text
language sql
immutable
set search_path = ''
as $$ select p_tag || lpad(char_length(p_value)::text, 2, '0') || p_value; $$;

create or replace function kaoid_private.promptpay_payload_r28(p_type text, p_id text, p_amount numeric)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_target text;
  v_body text;
begin
  v_target := case p_type
    when 'phone' then kaoid_private.emv_tlv_r28('01', '0066' || substr(p_id, 2))
    when 'national_id' then kaoid_private.emv_tlv_r28('02', p_id)
    when 'ewallet' then kaoid_private.emv_tlv_r28('03', p_id)
  end;
  if v_target is null or p_amount is null or p_amount <= 0 then
    raise exception 'invalid_promptpay' using errcode = '22023';
  end if;
  v_body := kaoid_private.emv_tlv_r28('00', '01')
         || kaoid_private.emv_tlv_r28('01', '12')
         || kaoid_private.emv_tlv_r28('29', kaoid_private.emv_tlv_r28('00', 'A000000677010111') || v_target)
         || kaoid_private.emv_tlv_r28('53', '764')
         || kaoid_private.emv_tlv_r28('54', to_char(p_amount, 'FM999999990.00'))
         || kaoid_private.emv_tlv_r28('58', 'TH')
         || '6304';
  return v_body || kaoid_private.crc16_ccitt_r28(v_body);
end $$;

-- Shows only the last digits of the receiving PromptPay number.
create or replace function kaoid_private.promptpay_masked_r28(p_type text, p_id text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case when p_id is null then null
              when p_type = 'phone' then substr(p_id, 1, 3) || '-xxx-' || right(p_id, 4)
              else repeat('x', char_length(p_id) - 4) || right(p_id, 4) end;
$$;

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.topup_code_r28(p_id uuid)
returns text
language sql
immutable
set search_path = ''
as $$ select 'TU' || upper(substr(replace(p_id::text, '-', ''), 1, 8)); $$;

create or replace function kaoid_private.topup_json_r28(r public.topup_requests)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', r.id, 'code', kaoid_private.topup_code_r28(r.id), 'amount', r.amount, 'status', r.status,
    'source_app', r.source_app, 'receiver_name', r.receiver_name,
    'promptpay_type', r.promptpay_type, 'promptpay_masked', kaoid_private.promptpay_masked_r28(r.promptpay_type, r.promptpay_id),
    'qr_payload', case when r.status = 'awaiting_slip' then r.qr_payload end,
    'expires_at', r.expires_at, 'slip_uploaded_at', r.slip_uploaded_at, 'reviewed_at', r.reviewed_at,
    'reject_reason', r.reject_reason, 'cancelled_at', r.cancelled_at, 'created_at', r.created_at);
$$;

-- Marks requests whose slip window has passed. Runs from cron and before member actions.
create or replace function kaoid_private.expire_topups_r28(p_profile uuid default null)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  update public.topup_requests
     set status = 'expired', updated_at = now()
   where status = 'awaiting_slip' and expires_at <= now()
     and (p_profile is null or profile_id = p_profile);
  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- The member behind a top-up call: signed in, account active and holding an active personal Kao ID.
create or replace function kaoid_private.topup_member_r28()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_restricted' using errcode = '42501';
  end if;
  return u;
end $$;

create or replace function kaoid_private.kao_id_active_r28(p_profile uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.kao_id_identities k
                  where k.profile_id = p_profile and k.identity_type = 'personal'
                    and k.organization_id is null and k.status = 'active');
$$;

-- Requested today (Bangkok time) and still counting toward the daily limit.
create or replace function kaoid_private.topup_today_r28(p_profile uuid)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum(r.amount), 0)::numeric(12,2)
    from public.topup_requests r
   where r.profile_id = p_profile
     and r.status in ('awaiting_slip', 'pending_review', 'awaiting_second', 'approved')
     and r.created_at >= (date_trunc('day', now() at time zone 'Asia/Bangkok') at time zone 'Asia/Bangkok');
$$;

-- ---------------------------------------------------------------------------
-- Member RPCs (Kao ID and Secondhand)
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.topup_info_r28()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := kaoid_private.topup_member_r28();
  s kaoid_private.topup_settings_r28;
  w public.wallets;
  r public.topup_requests;
  v_today numeric(12,2);
  v_reason text;
begin
  perform kaoid_private.expire_topups_r28(u);
  select * into s from kaoid_private.topup_settings_r28 where id;
  select * into w from public.wallets where profile_id = u;
  select * into r from public.topup_requests x
   where x.profile_id = u and x.status in ('awaiting_slip', 'pending_review', 'awaiting_second');
  v_today := kaoid_private.topup_today_r28(u);
  v_reason := case
    when not s.enabled then 'topup_unavailable'
    when not kaoid_private.kao_id_active_r28(u) then 'kao_id_required'
    when w.id is not null and w.wallet_status <> 'active' then 'wallet_unavailable'
    when r.id is not null then 'request_open'
    when v_today + s.min_amount > s.daily_max then 'daily_limit_reached'
  end;
  return jsonb_build_object(
    'balance', coalesce(w.balance, 0), 'currency', coalesce(w.currency, 'THB'),
    'min_amount', s.min_amount, 'max_amount', least(s.max_amount, greatest(s.daily_max - v_today, 0)),
    'per_request_max', s.max_amount, 'daily_max', s.daily_max, 'today_total', v_today,
    'slip_hours', s.slip_hours,
    'receiver_name', case when s.enabled then s.receiver_name end,
    'can_top_up', v_reason is null, 'reason', v_reason,
    'open', case when r.id is not null then kaoid_private.topup_json_r28(r) end);
end $$;

create or replace function kaoid_private.topup_create_r28(p_amount numeric, p_source text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := kaoid_private.topup_member_r28();
  s kaoid_private.topup_settings_r28;
  w public.wallets;
  r public.topup_requests;
  v_id uuid := gen_random_uuid();
begin
  if p_source is null or p_source not in ('kaoid', 'secondhand') then
    raise exception 'invalid_source' using errcode = '22023';
  end if;
  select * into s from kaoid_private.topup_settings_r28 where id;
  if not s.enabled then
    raise exception 'topup_unavailable' using errcode = '42501';
  end if;
  if not kaoid_private.kao_id_active_r28(u) then
    raise exception 'KAO_ID_REQUIRED' using errcode = '42501';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then
    raise exception 'invalid_amount' using errcode = '22023';
  end if;
  if p_amount < s.min_amount then
    raise exception 'amount_below_minimum' using errcode = '22023';
  end if;
  if p_amount > s.max_amount then
    raise exception 'amount_above_maximum' using errcode = '22023';
  end if;

  insert into public.wallets(profile_id) values (u) on conflict (profile_id) do nothing;
  select * into strict w from public.wallets where profile_id = u for update;
  if w.wallet_status <> 'active' then
    raise exception 'wallet_unavailable' using errcode = '42501';
  end if;
  perform kaoid_private.expire_topups_r28(u);
  if exists (select 1 from public.topup_requests x
              where x.profile_id = u and x.status in ('awaiting_slip', 'pending_review', 'awaiting_second')) then
    raise exception 'topup_open' using errcode = '22023';
  end if;
  if kaoid_private.topup_today_r28(u) + p_amount > s.daily_max then
    raise exception 'daily_limit_reached' using errcode = '22023';
  end if;

  insert into public.topup_requests(id, profile_id, wallet_id, amount, source_app, promptpay_type, promptpay_id,
                                    receiver_name, qr_payload, dual_review, expires_at)
  values (v_id, u, w.id, p_amount, p_source, s.promptpay_type, s.promptpay_id, s.receiver_name,
          kaoid_private.promptpay_payload_r28(s.promptpay_type, s.promptpay_id, p_amount),
          p_amount >= s.dual_review_from, now() + make_interval(hours => s.slip_hours))
  returning * into r;
  return kaoid_private.topup_json_r28(r);
end $$;

-- The slip must already be uploaded to "<owner>/<request>/slip.jpg" in wallet-slips.
create or replace function kaoid_private.topup_attach_slip_r28(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := kaoid_private.topup_member_r28();
  r public.topup_requests;
  o storage.objects;
  v_path text;
  v_etag text;
begin
  select * into r from public.topup_requests x where x.id = p_id and x.profile_id = u for update;
  if not found then
    raise exception 'topup_not_found' using errcode = '22023';
  end if;
  if r.status in ('pending_review', 'awaiting_second') and r.slip_path is not null then
    return kaoid_private.topup_json_r28(r);
  end if;
  if r.status <> 'awaiting_slip' then
    raise exception 'topup_not_open' using errcode = '22023';
  end if;
  if r.expires_at <= now() then
    update public.topup_requests set status = 'expired', updated_at = now() where id = r.id;
    raise exception 'topup_expired' using errcode = '22023';
  end if;

  v_path := u::text || '/' || r.id::text || '/slip.jpg';
  select * into o from storage.objects x
   where x.bucket_id = 'wallet-slips' and x.name = v_path and x.owner_id = u::text;
  if not found then
    raise exception 'slip_required' using errcode = '22023';
  end if;
  if coalesce(o.metadata->>'mimetype', '') <> 'image/jpeg'
     or coalesce((o.metadata->>'size')::bigint, 0) not between 1 and 5242880 then
    raise exception 'invalid_slip' using errcode = '22023';
  end if;
  v_etag := nullif(btrim(o.metadata->>'eTag', '"'), '');
  if v_etag is not null and exists (
       select 1 from public.topup_requests x
        where x.slip_etag = v_etag and x.id <> r.id and x.status in ('pending_review', 'awaiting_second', 'approved')) then
    raise exception 'slip_duplicate' using errcode = '23505';
  end if;

  update public.topup_requests
     set status = 'pending_review', slip_path = v_path, slip_etag = v_etag, slip_size = (o.metadata->>'size')::bigint,
         slip_uploaded_at = now(), updated_at = now()
   where id = r.id
  returning * into r;
  return kaoid_private.topup_json_r28(r);
end $$;

create or replace function kaoid_private.topup_cancel_r28(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := kaoid_private.topup_member_r28();
  r public.topup_requests;
begin
  select * into r from public.topup_requests x where x.id = p_id and x.profile_id = u for update;
  if not found then
    raise exception 'topup_not_found' using errcode = '22023';
  end if;
  if r.status = 'cancelled' then
    return kaoid_private.topup_json_r28(r);
  end if;
  if r.status <> 'awaiting_slip' then
    raise exception 'topup_not_cancellable' using errcode = '22023';
  end if;
  update public.topup_requests
     set status = 'cancelled', cancelled_at = now(), updated_at = now()
   where id = r.id
  returning * into r;
  return kaoid_private.topup_json_r28(r);
end $$;

create or replace function kaoid_private.topup_history_r28(p_before timestamptz, p_limit integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := kaoid_private.topup_member_r28();
begin
  perform kaoid_private.expire_topups_r28(u);
  return (select coalesce(jsonb_agg(kaoid_private.topup_json_r28(x) order by x.created_at desc), '[]')
            from (select * from public.topup_requests r
                   where r.profile_id = u and (p_before is null or r.created_at < p_before)
                   order by r.created_at desc
                   limit least(greatest(coalesce(p_limit, 20), 1), 50)) x);
end $$;

-- ---------------------------------------------------------------------------
-- Staff RPCs (Kao ID Admin Hub only)
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.topup_staff_r28()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not kaoid_private.staff_permission_r24('wallet.deposit.approve') then
    raise exception 'topup_access_denied' using errcode = '42501';
  end if;
  return auth.uid();
end $$;

-- Name on the member's approved primary identity document, else the profile name.
create or replace function kaoid_private.topup_member_name_r28(p_profile uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select d.full_name from public.identity_documents d
      where d.owner_id = p_profile and d.status = 'approved' and d.deleted_at is null
        and kaoid_private.primary_identity_r27a(d.document_type, d.issuing_country, d.thai_document_kind)
        and (d.expiry_date is null or d.expiry_date >= current_date)
      order by d.verified_at desc nulls last, d.created_at desc limit 1),
    (select nullif(btrim(concat_ws(' ', p.first_name, p.last_name)), '') from public.profiles p where p.id = p_profile));
$$;

create or replace function kaoid_private.topup_staff_json_r28(r public.topup_requests)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select kaoid_private.topup_json_r28(r) || jsonb_build_object(
    'profile_id', r.profile_id, 'dual_review', r.dual_review,
    'display_name', (select p.display_name from public.profiles p where p.id = r.profile_id),
    'account_code', (select a.account_code from kaoid_private.account_refs_r10c a where a.profile_id = r.profile_id),
    'first_reviewer', r.first_reviewer, 'first_reviewed_at', r.first_reviewed_at,
    'first_reviewer_name', (select p.display_name from public.profiles p where p.id = r.first_reviewer),
    'bank_reference', r.bank_reference,
    'reviewer_name', (select p.display_name from public.profiles p where p.id = r.reviewed_by));
$$;

create or replace function kaoid_private.topup_queue_r28(p_status text, p_before timestamptz)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform kaoid_private.topup_staff_r28();
  if p_status is null or p_status not in ('pending_review', 'awaiting_second', 'approved', 'rejected', 'awaiting_slip',
                                          'expired', 'cancelled') then
    raise exception 'invalid_status' using errcode = '22023';
  end if;
  return (select coalesce(jsonb_agg(kaoid_private.topup_staff_json_r28(x) order by x.created_at desc), '[]')
            from (select * from public.topup_requests r
                   where r.status = p_status and (p_before is null or r.created_at < p_before)
                   order by r.created_at desc limit 30) x);
end $$;

create or replace function kaoid_private.topup_detail_r28(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := kaoid_private.topup_staff_r28();
  r public.topup_requests;
  w public.wallets;
begin
  select * into r from public.topup_requests where id = p_id;
  if not found then
    raise exception 'topup_not_found' using errcode = '22023';
  end if;
  select * into w from public.wallets where id = r.wallet_id;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'finance.topup.read', 'topup_requests', r.id, 'Read top-up slip details');
  return kaoid_private.topup_staff_json_r28(r) || jsonb_build_object(
    'slip_path', r.slip_path,
    'member_name', kaoid_private.topup_member_name_r28(r.profile_id),
    'kao_id', (select k.kao_id from public.kao_id_identities k
                where k.profile_id = r.profile_id and k.identity_type = 'personal' and k.organization_id is null
                  and k.status = 'active' limit 1),
    'kao_id_active', kaoid_private.kao_id_active_r28(r.profile_id),
    'wallet_balance', w.balance, 'wallet_status', w.wallet_status,
    'today_total', kaoid_private.topup_today_r28(r.profile_id),
    'duplicate_slips', (select coalesce(jsonb_agg(jsonb_build_object(
                                 'id', x.id, 'code', kaoid_private.topup_code_r28(x.id), 'status', x.status,
                                 'amount', x.amount, 'created_at', x.created_at) order by x.created_at desc), '[]')
                          from public.topup_requests x
                         where r.slip_etag is not null and x.slip_etag = r.slip_etag and x.id <> r.id),
    'own_request', r.profile_id = u);
end $$;

create or replace function kaoid_private.topup_review_r28(p_id uuid, p_approve boolean, p_payer_confirmed boolean,
                                                          p_reference text, p_reason text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := kaoid_private.topup_staff_r28();
  r public.topup_requests;
  w public.wallets;
  v_ref text := btrim(coalesce(p_reference, ''));
  v_reason text := btrim(coalesce(p_reason, ''));
  v_amount text;
  v_tx uuid;
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if p_approve is null then
    raise exception 'invalid_decision' using errcode = '22023';
  end if;
  if p_approve and not coalesce(p_payer_confirmed, false) then
    raise exception 'payer_confirmation_required' using errcode = '22023';
  end if;
  if p_approve and char_length(v_ref) not between 3 and 100 then
    raise exception 'reference_required' using errcode = '22023';
  end if;
  if not p_approve and char_length(v_reason) not between 3 and 500 then
    raise exception 'reason_required' using errcode = '22023';
  end if;

  select * into r from public.topup_requests where id = p_id for update;
  if not found then
    raise exception 'topup_not_found' using errcode = '22023';
  end if;
  if r.profile_id = u then
    raise exception 'own_topup' using errcode = '42501';
  end if;
  if r.status not in ('pending_review', 'awaiting_second') then
    if r.reviewed_by = u and r.status = (case when p_approve then 'approved' else 'rejected' end) then
      return kaoid_private.topup_staff_json_r28(r);
    end if;
    raise exception 'topup_not_pending' using errcode = '22023';
  end if;
  if r.status = 'awaiting_second' and r.first_reviewer = u then
    if p_approve then
      return kaoid_private.topup_staff_json_r28(r);
    end if;
    raise exception 'second_reviewer_required' using errcode = '42501';
  end if;

  v_amount := to_char(r.amount, 'FM999,999,990.00');
  if not p_approve then
    update public.topup_requests
       set status = 'rejected', reject_reason = v_reason, reviewed_by = u, reviewed_at = now(), updated_at = now()
     where id = r.id
    returning * into r;
    insert into public.activity_logs(profile_id, action, target_table, target_id, description)
    values (u, 'finance.topup.reject', 'topup_requests', r.id, v_reason);
    insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
    values (r.profile_id,
            kaoid_private.content_message_r24('common.notice.topup_rejected', 'title', null, 'การเติมเงินไม่ผ่าน'),
            kaoid_private.content_message_r24('common.notice.topup_rejected', 'body',
              jsonb_build_object('amount', v_amount, 'reason', v_reason),
              'คำขอเติมเงิน ฿{amount} ไม่ผ่านการตรวจสอบ เหตุผล: {reason}'),
            'wallet', r.id, '/wallet', 'topup:' || r.id || ':rejected');
    return kaoid_private.topup_staff_json_r28(r);
  end if;

  if not kaoid_private.kao_id_active_r28(r.profile_id) then
    raise exception 'member_kao_id_inactive' using errcode = '22023';
  end if;
  if exists (select 1 from public.topup_requests x
              where x.id <> r.id and x.status in ('awaiting_second', 'approved')
                and lower(coalesce(x.bank_reference, x.first_reference)) = lower(v_ref)) then
    raise exception 'reference_used' using errcode = '23505';
  end if;

  if r.dual_review and r.status = 'pending_review' then
    update public.topup_requests
       set status = 'awaiting_second', first_reviewer = u, first_reference = v_ref, first_reviewed_at = now(),
           updated_at = now()
     where id = r.id
    returning * into r;
    insert into public.activity_logs(profile_id, action, target_table, target_id, description)
    values (u, 'finance.topup.first_approve', 'topup_requests', r.id, v_ref);
    return kaoid_private.topup_staff_json_r28(r);
  end if;
  if r.status = 'awaiting_second' and lower(v_ref) <> lower(r.first_reference) then
    raise exception 'reference_mismatch' using errcode = '22023';
  end if;

  select * into strict w from public.wallets where id = r.wallet_id for update;
  if w.wallet_status <> 'active' then
    raise exception 'wallet_unavailable' using errcode = '22023';
  end if;
  update public.wallets set balance = balance + r.amount, updated_at = now() where id = w.id;
  insert into public.wallet_transactions(wallet_id, transaction_type, amount, balance_before, balance_after,
                                         description, transaction_status)
  values (w.id, 'deposit', r.amount, w.balance, w.balance + r.amount,
          'เติมเงินผ่าน PromptPay ' || kaoid_private.topup_code_r28(r.id), 'completed')
  returning id into v_tx;
  update public.topup_requests
     set status = 'approved', bank_reference = v_ref, reviewed_by = u, reviewed_at = now(),
         wallet_transaction_id = v_tx, updated_at = now()
   where id = r.id
  returning * into r;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'finance.topup.approve', 'topup_requests', r.id, v_ref || ' ฿' || v_amount);
  insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (r.profile_id,
          kaoid_private.content_message_r24('common.notice.topup_approved', 'title', null, 'เติมเงินสำเร็จ'),
          kaoid_private.content_message_r24('common.notice.topup_approved', 'body',
            jsonb_build_object('amount', v_amount), 'เติมเงิน ฿{amount} เข้า KaoSure Wallet แล้ว'),
          'wallet', r.id, '/wallet', 'topup:' || r.id || ':approved');
  return kaoid_private.topup_staff_json_r28(r);
end $$;

-- Settings: the PromptPay number is returned in full only to staff who may change it.
create or replace function kaoid_private.topup_settings_staff_r28()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not kaoid_private.staff_permission_r24('wallet.deposit.settings') then
    raise exception 'topup_settings_denied' using errcode = '42501';
  end if;
  return auth.uid();
end $$;

create or replace function kaoid_private.topup_settings_json_r28(s kaoid_private.topup_settings_r28)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'enabled', s.enabled, 'promptpay_type', s.promptpay_type, 'promptpay_id', s.promptpay_id,
    'receiver_name', s.receiver_name, 'min_amount', s.min_amount, 'max_amount', s.max_amount,
    'daily_max', s.daily_max, 'dual_review_from', s.dual_review_from, 'slip_hours', s.slip_hours,
    'version', s.version, 'updated_at', s.updated_at,
    'updated_by_name', (select p.display_name from public.profiles p where p.id = s.updated_by));
$$;

create or replace function kaoid_private.topup_settings_read_r28()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform kaoid_private.topup_settings_staff_r28();
  return (select kaoid_private.topup_settings_json_r28(s) from kaoid_private.topup_settings_r28 s where s.id);
end $$;

create or replace function kaoid_private.topup_settings_save_r28(
  p_enabled boolean, p_promptpay_type text, p_promptpay_id text, p_receiver_name text, p_min numeric,
  p_max numeric, p_daily numeric, p_dual_from numeric, p_slip_hours integer, p_version integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := kaoid_private.topup_settings_staff_r28();
  s kaoid_private.topup_settings_r28;
  v_id text := nullif(regexp_replace(coalesce(p_promptpay_id, ''), '[\s-]', '', 'g'), '');
  v_name text := nullif(btrim(coalesce(p_receiver_name, '')), '');
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  select * into s from kaoid_private.topup_settings_r28 where id for update;
  if p_version is distinct from s.version then
    raise exception 'settings_changed' using errcode = '40001';
  end if;
  if p_enabled is null or p_min is null or p_max is null or p_daily is null or p_dual_from is null
     or p_slip_hours is null
     or p_min <> round(p_min, 2) or p_max <> round(p_max, 2) or p_daily <> round(p_daily, 2)
     or p_dual_from <> round(p_dual_from, 2) then
    raise exception 'invalid_settings' using errcode = '22023';
  end if;
  if p_promptpay_type is not null and p_promptpay_type not in ('phone', 'national_id', 'ewallet') then
    raise exception 'invalid_promptpay' using errcode = '22023';
  end if;
  if (p_promptpay_type is null) <> (v_id is null)
     or (v_id is not null and v_id !~ case p_promptpay_type when 'phone' then '^0[0-9]{9}$'
                                                            when 'national_id' then '^[0-9]{13}$'
                                                            else '^[0-9]{15}$' end) then
    raise exception 'invalid_promptpay' using errcode = '22023';
  end if;
  if char_length(coalesce(v_name, '')) > 120 then
    raise exception 'invalid_settings' using errcode = '22023';
  end if;
  if p_enabled and (v_id is null or v_name is null) then
    raise exception 'receiver_required' using errcode = '22023';
  end if;
  begin
    update kaoid_private.topup_settings_r28
       set enabled = p_enabled, promptpay_type = p_promptpay_type, promptpay_id = v_id, receiver_name = v_name,
           min_amount = p_min, max_amount = p_max, daily_max = p_daily, dual_review_from = p_dual_from,
           slip_hours = p_slip_hours, version = version + 1, updated_by = u, updated_at = now()
     where id
    returning * into s;
  exception when check_violation then
    raise exception 'invalid_settings' using errcode = '22023';
  end;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'finance.topup.settings', 'topup_settings_r28', null,
          'v' || s.version || ' ' || case when s.enabled then 'on' else 'off' end || ' '
          || coalesce(s.promptpay_type, '-') || ' ' || coalesce(kaoid_private.promptpay_masked_r28(s.promptpay_type, s.promptpay_id), '-')
          || ' min ' || s.min_amount || ' max ' || s.max_amount || ' day ' || s.daily_max
          || ' dual ' || s.dual_review_from || ' ' || s.slip_hours || 'h');
  return kaoid_private.topup_settings_json_r28(s);
end $$;

-- Which Admin Hub tools the signed-in staff member can open (adds top-ups to R24-R26).
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
  v_issues boolean := kaoid_private.staff_permission_r24('marketplace.orders.resolve');
  v_topups boolean := kaoid_private.staff_permission_r24('wallet.deposit.approve');
  v_topup_settings boolean := kaoid_private.staff_permission_r24('wallet.deposit.settings');
begin
  return jsonb_build_object(
    'withdrawals', v_withdrawals,
    'contents', v_contents,
    'reviews', v_reviews,
    'order_issues', v_issues,
    'topups', v_topups,
    'topup_settings', v_topup_settings,
    'pending_withdrawals', case when v_withdrawals then
      (select count(*) from public.withdraw_requests r where r.withdraw_status = 'pending') end,
    'pending_review_reports', case when v_reviews then
      (select count(distinct rr.review_id) from secondhand.review_reports rr where rr.report_status = 'pending') end,
    'open_order_issues', case when v_issues then
      (select count(*) from secondhand.order_issues i where i.issue_status = 'open') end,
    'pending_topups', case when v_topups then
      (select count(*) from public.topup_requests t where t.status in ('pending_review', 'awaiting_second')) end);
end $$;

-- ---------------------------------------------------------------------------
-- Public wrappers
-- ---------------------------------------------------------------------------
create or replace function public.topup_info_r28()
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.topup_info_r28(); $$;
create or replace function public.topup_create_r28(p_amount numeric, p_source text)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.topup_create_r28(p_amount, p_source); $$;
create or replace function public.topup_attach_slip_r28(p_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.topup_attach_slip_r28(p_id); $$;
create or replace function public.topup_cancel_r28(p_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.topup_cancel_r28(p_id); $$;
create or replace function public.topup_history_r28(p_before timestamptz default null, p_limit integer default 20)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.topup_history_r28(p_before, p_limit); $$;
create or replace function public.topup_queue_r28(p_status text default 'pending_review', p_before timestamptz default null)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.topup_queue_r28(p_status, p_before); $$;
create or replace function public.topup_detail_r28(p_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.topup_detail_r28(p_id); $$;
create or replace function public.topup_review_r28(p_id uuid, p_approve boolean, p_payer_confirmed boolean default false,
                                                   p_reference text default null, p_reason text default null)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.topup_review_r28(p_id, p_approve, p_payer_confirmed, p_reference, p_reason); $$;
create or replace function public.topup_settings_r28()
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.topup_settings_read_r28(); $$;
create or replace function public.topup_settings_save_r28(
  p_enabled boolean, p_promptpay_type text, p_promptpay_id text, p_receiver_name text, p_min numeric,
  p_max numeric, p_daily numeric, p_dual_from numeric, p_slip_hours integer, p_version integer)
returns jsonb language sql security invoker set search_path = ''
as $$ select kaoid_private.topup_settings_save_r28(p_enabled, p_promptpay_type, p_promptpay_id, p_receiver_name, p_min,
                                                     p_max, p_daily, p_dual_from, p_slip_hours, p_version); $$;

-- ---------------------------------------------------------------------------
-- Notice texts (staff edit them in the Admin Hub)
-- ---------------------------------------------------------------------------
insert into public.system_contents(content_key, app_code, category, title, body, meta, sort_order) values
  ('common.notice.topup_approved', 'common', 'notice',
   jsonb_build_object('th', $c$เติมเงินสำเร็จ$c$, 'en', $c$Top-up complete$c$),
   jsonb_build_object('th', $c$เติมเงิน ฿{amount} เข้า KaoSure Wallet แล้ว$c$,
                      'en', $c$฿{amount} was added to your KaoSure Wallet.$c$),
   '{"placeholders": ["amount"]}', 120),
  ('common.notice.topup_rejected', 'common', 'notice',
   jsonb_build_object('th', $c$การเติมเงินไม่ผ่าน$c$, 'en', $c$Top-up declined$c$),
   jsonb_build_object('th', $c$คำขอเติมเงิน ฿{amount} ไม่ผ่านการตรวจสอบ เหตุผล: {reason}$c$,
                      'en', $c$Your ฿{amount} top-up wasn't approved. Reason: {reason}$c$),
   '{"placeholders": ["amount", "reason"]}', 130)
on conflict (content_key) do nothing;

-- ---------------------------------------------------------------------------
-- Expiry job
-- ---------------------------------------------------------------------------
select cron.schedule('kaoid-topup-expiry-r28', '*/10 * * * *', 'select kaoid_private.expire_topups_r28();');

-- ---------------------------------------------------------------------------
-- Grants and app scope
-- ---------------------------------------------------------------------------
revoke all on function kaoid_private.crc16_ccitt_r28(text), kaoid_private.emv_tlv_r28(text, text),
  kaoid_private.promptpay_payload_r28(text, text, numeric), kaoid_private.promptpay_masked_r28(text, text),
  kaoid_private.topup_code_r28(uuid), kaoid_private.topup_json_r28(public.topup_requests),
  kaoid_private.expire_topups_r28(uuid), kaoid_private.topup_member_r28(), kaoid_private.kao_id_active_r28(uuid),
  kaoid_private.topup_today_r28(uuid), kaoid_private.topup_staff_r28(), kaoid_private.topup_member_name_r28(uuid),
  kaoid_private.topup_staff_json_r28(public.topup_requests), kaoid_private.topup_settings_staff_r28(),
  kaoid_private.topup_settings_json_r28(kaoid_private.topup_settings_r28)
  from public, anon, authenticated;

revoke all on function kaoid_private.topup_info_r28(), kaoid_private.topup_create_r28(numeric, text),
  kaoid_private.topup_attach_slip_r28(uuid), kaoid_private.topup_cancel_r28(uuid),
  kaoid_private.topup_history_r28(timestamptz, integer), kaoid_private.topup_queue_r28(text, timestamptz),
  kaoid_private.topup_detail_r28(uuid), kaoid_private.topup_review_r28(uuid, boolean, boolean, text, text),
  kaoid_private.topup_settings_read_r28(),
  kaoid_private.topup_settings_save_r28(boolean, text, text, text, numeric, numeric, numeric, numeric, integer, integer),
  public.topup_info_r28(), public.topup_create_r28(numeric, text), public.topup_attach_slip_r28(uuid),
  public.topup_cancel_r28(uuid), public.topup_history_r28(timestamptz, integer),
  public.topup_queue_r28(text, timestamptz), public.topup_detail_r28(uuid),
  public.topup_review_r28(uuid, boolean, boolean, text, text), public.topup_settings_r28(),
  public.topup_settings_save_r28(boolean, text, text, text, numeric, numeric, numeric, numeric, integer, integer)
  from public, anon;
grant execute on function kaoid_private.topup_info_r28(), kaoid_private.topup_create_r28(numeric, text),
  kaoid_private.topup_attach_slip_r28(uuid), kaoid_private.topup_cancel_r28(uuid),
  kaoid_private.topup_history_r28(timestamptz, integer), kaoid_private.topup_queue_r28(text, timestamptz),
  kaoid_private.topup_detail_r28(uuid), kaoid_private.topup_review_r28(uuid, boolean, boolean, text, text),
  kaoid_private.topup_settings_read_r28(),
  kaoid_private.topup_settings_save_r28(boolean, text, text, text, numeric, numeric, numeric, numeric, integer, integer),
  public.topup_info_r28(), public.topup_create_r28(numeric, text), public.topup_attach_slip_r28(uuid),
  public.topup_cancel_r28(uuid), public.topup_history_r28(timestamptz, integer),
  public.topup_queue_r28(text, timestamptz), public.topup_detail_r28(uuid),
  public.topup_review_r28(uuid, boolean, boolean, text, text), public.topup_settings_r28(),
  public.topup_settings_save_r28(boolean, text, text, text, numeric, numeric, numeric, numeric, integer, integer)
  to authenticated;

-- Secondhand tops up with its app token; staff tools stay first-party only (staff_permission_r24).
update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
                              'public.topup_info_r28', 'public.topup_create_r28', 'public.topup_attach_slip_r28',
                              'public.topup_cancel_r28', 'public.topup_history_r28']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
