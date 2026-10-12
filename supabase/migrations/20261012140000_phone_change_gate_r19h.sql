-- R19h: phone changes start only in Kao ID.
--
-- Supabase Auth lets any user token (including an app's SSO token) call
-- PUT /auth/v1/user with a new phone. Every SMS goes through the Send SMS hook,
-- so the hook refuses an OTP to a number other than the account's current one
-- unless Kao ID itself (a token without client_id) announced that number in the
-- last 10 minutes. An error from the hook rolls back the pending phone change.

create table kaoid_private.phone_change_intents_r19 (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  phone text not null check (phone ~ '^[1-9][0-9]{7,14}$'),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);
alter table kaoid_private.phone_change_intents_r19 enable row level security;
revoke all on table kaoid_private.phone_change_intents_r19 from public, anon, authenticated;

create or replace function kaoid_private.begin_phone_change_r19(p_phone text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid();
  v_phone text := regexp_replace(coalesce(p_phone, ''), '[\s()+.-]', '', 'g');
  v_expires timestamptz := now() + interval '10 minutes';
begin
  if u is null then raise exception 'authentication_required' using errcode = '42501'; end if;
  if nullif(auth.jwt()->>'client_id', '') is not null then
    raise exception 'kao_id_only' using errcode = '42501';
  end if;
  if coalesce(kaoid_private.account_access_r10d()->>'state', '') <> 'active' then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  if v_phone !~ '^[1-9][0-9]{7,14}$' then
    raise exception 'invalid_phone' using errcode = '22023';
  end if;
  insert into kaoid_private.phone_change_intents_r19(profile_id, phone, created_at, expires_at)
  values (u, v_phone, now(), v_expires)
  on conflict (profile_id) do update set phone = excluded.phone, created_at = excluded.created_at,
    expires_at = excluded.expires_at;
  return jsonb_build_object('expires_at', v_expires);
end $$;

create or replace function public.begin_phone_change_r19(p_phone text) returns jsonb
language sql set search_path = '' as $$ select kaoid_private.begin_phone_change_r19(p_phone); $$;

-- Send SMS hook (Postgres). Delivery is not wired yet, so a permitted SMS still
-- fails with 503 until an SMS provider replaces the final return.
create or replace function kaoid_private.send_sms_hook_r19(event jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := nullif(event->'user'->>'id', '')::uuid;
  v_target text := regexp_replace(coalesce(nullif(event->'sms'->>'phone', ''),
    nullif(event->'user'->>'new_phone', ''), event->'user'->>'phone', ''), '\D', '', 'g');
  v_current text := regexp_replace(coalesce(event->'user'->>'phone', ''), '\D', '', 'g');
begin
  if v_target = '' then
    return jsonb_build_object('error', jsonb_build_object('http_code', 400, 'message', 'Missing phone number.'));
  end if;
  if v_target <> v_current and not exists(
      select 1 from kaoid_private.phone_change_intents_r19 i
       where i.profile_id = v_user and i.phone = v_target and i.expires_at > now()) then
    return jsonb_build_object('error', jsonb_build_object('http_code', 403,
      'message', 'Phone number changes must be started in Kao ID.'));
  end if;
  return jsonb_build_object('error', jsonb_build_object('http_code', 503,
    'message', 'SMS delivery is not configured yet.'));
end $$;

revoke all on function
  kaoid_private.begin_phone_change_r19(text),
  public.begin_phone_change_r19(text),
  kaoid_private.send_sms_hook_r19(jsonb)
from public, anon, authenticated;

grant execute on function kaoid_private.begin_phone_change_r19(text), public.begin_phone_change_r19(text)
  to authenticated;

grant usage on schema kaoid_private to supabase_auth_admin;
grant execute on function kaoid_private.send_sms_hook_r19(jsonb) to supabase_auth_admin;
