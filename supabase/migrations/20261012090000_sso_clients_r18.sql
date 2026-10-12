-- R18: Kao ID as the identity provider for sub-apps (Secondhand, Auction, ...).
-- Supabase Auth's OAuth 2.1 server issues codes and tokens (Authorization Code + PKCE,
-- OIDC id_token signed with the project's asymmetric key). This migration adds the Kao ID
-- side: which registered OAuth clients may act for a member, what they may call, and the
-- live status claims they read.

-- ---------------------------------------------------------------------------
-- Registry
-- ---------------------------------------------------------------------------
create table kaoid_private.app_clients_r18 (
  app_code text primary key check (app_code ~ '^[a-z][a-z0-9_]{2,39}$'),
  oauth_client_id uuid not null unique,
  display_name text not null check (length(btrim(display_name)) between 2 and 80),
  status text not null default 'active' check (status in ('active', 'suspended')),
  first_party boolean not null default false,
  allowed_claims text[] not null default '{}'
    check (allowed_claims <@ array['profile', 'verification', 'business', 'roles']::text[]),
  allowed_rpcs text[] not null default '{}',
  allowed_tables text[] not null default '{}',
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);
alter table kaoid_private.app_clients_r18 enable row level security;
revoke all on table kaoid_private.app_clients_r18 from public, anon, authenticated;

-- First and latest use of each app per member (not a request log).
create table kaoid_private.app_access_r18 (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  app_code text not null references kaoid_private.app_clients_r18(app_code) on delete cascade,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  primary key (profile_id, app_code)
);
alter table kaoid_private.app_access_r18 enable row level security;
revoke all on table kaoid_private.app_access_r18 from public, anon, authenticated;

-- Kao ID functions an app token may never reach, whatever its allow-list says.
create or replace function kaoid_private.oauth_never_r18(p_name text) returns boolean
language sql immutable set search_path = '' as $$
  select p_name ~ '^(app_client|admin|governance|kyc_|business_review|security_|enable_security|revoke_session|sessions_|lifecycle_|prepare_recovery|submit_recovery|reveal_|issue_|enable_mfa|mfa_)'
      or p_name in ('admin_assignments', 'admin_roles', 'company_owners', 'owner_delegations', 'activity_logs',
                    'identity_documents', 'document_files', 'verification_requests', 'verifications',
                    'financial_verifications', 'kao_id_identities', 'approval_requests', 'approval_histories');
$$;

-- The registered app behind the current token; null for Kao ID's own sessions.
create or replace function kaoid_private.current_app_r18() returns kaoid_private.app_clients_r18
language plpgsql stable security definer set search_path = '' as $$
declare
  cid text := nullif(auth.jwt()->>'client_id', '');
  app kaoid_private.app_clients_r18;
begin
  if cid is null then return null; end if;
  select * into app from kaoid_private.app_clients_r18 a
   where a.oauth_client_id::text = cid and a.status = 'active';
  if not found then raise exception 'client_not_allowed' using errcode = '42501'; end if;
  return app;
end $$;

-- ---------------------------------------------------------------------------
-- Request guard: app tokens reach only their allow-listed RPCs and tables
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.oauth_client_guard_r18() returns void
language plpgsql stable security definer set search_path = '' as $$
declare
  app kaoid_private.app_clients_r18;
  path text := trim(both '/' from coalesce(current_setting('request.path', true), ''));
  target text;
begin
  if nullif(auth.jwt()->>'client_id', '') is null then return; end if;
  app := kaoid_private.current_app_r18();
  if path like 'rpc/%' then
    target := substr(path, 5);
    if target in ('kao_id_claims_r18', 'account_access_r10d') then return; end if;
    if target = any(app.allowed_rpcs) and not kaoid_private.oauth_never_r18(target) then return; end if;
  else
    target := split_part(path, '/', 1);
    if target = any(app.allowed_tables) and not kaoid_private.oauth_never_r18(target) then return; end if;
  end if;
  raise exception 'client_scope_denied' using errcode = '42501';
end $$;

alter function kaoid_private.pre_request_r10d() rename to pre_request_before_r18;
revoke all on function kaoid_private.pre_request_before_r18() from public, anon, authenticated;

create or replace function kaoid_private.pre_request_r10d() returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform kaoid_private.oauth_client_guard_r18();
  perform kaoid_private.pre_request_before_r18();
end $$;

-- ---------------------------------------------------------------------------
-- Live claims for an app (or Kao ID itself)
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.kyc_status_r18(p_profile uuid) returns text
language sql stable security definer set search_path = '' as $$
  select case
    when exists(select 1 from public.identity_documents d
                 where d.owner_id = p_profile and d.deleted_at is null
                   and d.document_type in ('thai_national_id', 'passport', 'residence_card')
                   and d.status = 'approved' and (d.expiry_date is null or d.expiry_date >= current_date))
      then 'approved'
    when exists(select 1 from public.identity_documents d
                 where d.owner_id = p_profile and d.deleted_at is null
                   and d.document_type in ('thai_national_id', 'passport', 'residence_card')
                   and d.status = 'pending_review')
      then 'pending'
    else coalesce((select case d.status when 'rejected' then 'rejected' else 'expired' end
                     from public.identity_documents d
                    where d.owner_id = p_profile and d.deleted_at is null
                      and d.document_type in ('thai_national_id', 'passport', 'residence_card')
                    order by d.created_at desc limit 1), 'not_submitted')
  end;
$$;

create or replace function kaoid_private.kao_id_claims_r18() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid();
  app kaoid_private.app_clients_r18 := kaoid_private.current_app_r18();
  claims text[];
  p public.profiles%rowtype;
  a auth.users%rowtype;
  result jsonb;
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  claims := case when app.app_code is null then array['profile', 'verification', 'business', 'roles']
                 else app.allowed_claims end;
  select * into p from public.profiles where id = u;
  select * into a from auth.users where id = u;

  result := jsonb_build_object(
    'sub', u,
    'app', app.app_code,
    'account_state', kaoid_private.account_access_r10d()->>'state',
    'kao_id', (select k.kao_id from public.kao_id_identities k
                where k.profile_id = u and k.identity_type = 'personal' and k.status = 'active'
                order by k.issued_at desc nulls last limit 1),
    'locale', p.language_code,
    'checked_at', now());

  if 'profile' = any(claims) then
    result := result || jsonb_build_object('profile', jsonb_build_object(
      'display_name', p.display_name, 'username', p.username, 'avatar_url', p.avatar_url,
      'country_code', p.country_code));
  end if;

  if 'verification' = any(claims) then
    result := result || jsonb_build_object('verification', jsonb_build_object(
      'email', a.email_confirmed_at is not null,
      'phone', a.phone_confirmed_at is not null,
      'kyc', kaoid_private.kyc_status_r18(u),
      'bank', coalesce(public.is_identity_financially_verified('personal', u, null), false),
      'kao_id_active', exists(select 1 from public.kao_id_identities k
                               where k.profile_id = u and k.identity_type = 'personal' and k.status = 'active')));
  end if;

  if 'business' = any(claims) then
    result := result || jsonb_build_object('business', (
      select coalesce(jsonb_agg(jsonb_build_object(
          'organization_id', o.id, 'name', o.name, 'status', o.status, 'role', m.role,
          'business_kao_id', (select k.kao_id from public.kao_id_identities k
                               where k.organization_id = o.id and k.status = 'active' limit 1),
          'bank', coalesce(public.is_identity_financially_verified('business', u, o.id), false))
          order by o.name), '[]'::jsonb)
        from public.organization_members m join public.organizations o on o.id = m.organization_id
       where m.profile_id = u and m.status = 'active'
         and (m.ends_at is null or m.ends_at > now())));
  end if;

  if 'roles' = any(claims) then
    result := result || jsonb_build_object('roles', (
      select coalesce(jsonb_agg(distinct r.code), '[]'::jsonb)
        from public.admin_assignments s join public.admin_roles r on r.id = s.role_id
       where s.profile_id = u and s.is_active and r.is_active
         and s.starts_at <= now() and (s.expires_at is null or s.expires_at > now()))
      || case when exists(select 1 from public.company_owners o where o.profile_id = u)
              then '["owner"]'::jsonb else '[]'::jsonb end);
  end if;

  if app.app_code is not null then
    insert into kaoid_private.app_access_r18(profile_id, app_code) values (u, app.app_code)
    on conflict (profile_id, app_code) do update set last_seen_at = now()
     where kaoid_private.app_access_r18.last_seen_at < now() - interval '5 minutes';
  end if;
  return result;
end $$;

create or replace function public.kao_id_claims_r18() returns jsonb
language sql set search_path = '' as $$ select kaoid_private.kao_id_claims_r18(); $$;

-- Display data for the consent screen and the member's connected apps.
create or replace function kaoid_private.app_directory_r18() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'app_code', a.app_code, 'client_id', a.oauth_client_id, 'display_name', a.display_name,
      'status', a.status, 'first_party', a.first_party, 'claims', to_jsonb(a.allowed_claims),
      'last_seen_at', x.last_seen_at) order by a.display_name), '[]'::jsonb)
    from kaoid_private.app_clients_r18 a
    left join kaoid_private.app_access_r18 x on x.app_code = a.app_code and x.profile_id = auth.uid()
   where auth.uid() is not null and nullif(auth.jwt()->>'client_id', '') is null;
$$;
create or replace function public.app_directory_r18() returns jsonb
language sql set search_path = '' as $$ select kaoid_private.app_directory_r18(); $$;

-- ---------------------------------------------------------------------------
-- Owner registry management
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.require_registry_owner_r18() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if nullif(auth.jwt()->>'client_id', '') is not null or not kaoid_private.company_owner_authority() then
    raise exception 'owner_required' using errcode = '42501';
  end if;
  perform kaoid_private.require_fresh_mfa_r14a();
end $$;

create or replace function kaoid_private.app_clients_list_r18() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform kaoid_private.require_registry_owner_r18();
  return (select coalesce(jsonb_agg(jsonb_build_object(
      'app_code', a.app_code, 'client_id', a.oauth_client_id, 'display_name', a.display_name,
      'status', a.status, 'first_party', a.first_party, 'claims', to_jsonb(a.allowed_claims),
      'rpcs', to_jsonb(a.allowed_rpcs), 'tables', to_jsonb(a.allowed_tables),
      'oauth_name', c.client_name, 'redirect_uris', c.redirect_uris, 'client_type', c.client_type,
      'oauth_registered', c.id is not null and c.deleted_at is null,
      'members', (select count(*) from kaoid_private.app_access_r18 x where x.app_code = a.app_code),
      'updated_at', a.updated_at) order by a.display_name), '[]'::jsonb)
    from kaoid_private.app_clients_r18 a left join auth.oauth_clients c on c.id = a.oauth_client_id);
end $$;

create or replace function kaoid_private.app_client_save_r18(
  p_app_code text, p_client_id uuid, p_display_name text, p_first_party boolean,
  p_claims text[], p_rpcs text[], p_tables text[]
) returns void language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid();
  v_code text := lower(btrim(p_app_code));
  v_name text := btrim(p_display_name);
  v_rpcs text[] := array(select distinct lower(btrim(x)) from unnest(coalesce(p_rpcs, '{}')) x where btrim(x) <> '');
  v_tables text[] := array(select distinct lower(btrim(x)) from unnest(coalesce(p_tables, '{}')) x where btrim(x) <> '');
  v_claims text[] := array(select distinct x from unnest(coalesce(p_claims, '{}')) x);
begin
  perform kaoid_private.require_registry_owner_r18();
  if v_code is null or v_code !~ '^[a-z][a-z0-9_]{2,39}$' or p_client_id is null
     or v_name is null or length(v_name) not between 2 and 80 or p_first_party is null
     or not (v_claims <@ array['profile', 'verification', 'business', 'roles']::text[])
     or exists(select 1 from unnest(v_rpcs || v_tables) n where n !~ '^[a-z_][a-z0-9_]{0,62}$' or kaoid_private.oauth_never_r18(n))
     or cardinality(v_rpcs) > 100 or cardinality(v_tables) > 100 then
    raise exception 'invalid_app_client' using errcode = '22023';
  end if;
  if not exists(select 1 from auth.oauth_clients c where c.id = p_client_id and c.deleted_at is null) then
    raise exception 'oauth_client_not_found' using errcode = '22023';
  end if;
  if exists(select 1 from kaoid_private.app_clients_r18 a
             where a.oauth_client_id = p_client_id and a.app_code <> v_code) then
    raise exception 'client_already_registered' using errcode = '23505';
  end if;
  insert into kaoid_private.app_clients_r18(app_code, oauth_client_id, display_name, first_party,
    allowed_claims, allowed_rpcs, allowed_tables, created_by, updated_by)
  values (v_code, p_client_id, v_name, p_first_party, v_claims, v_rpcs, v_tables, u, u)
  on conflict (app_code) do update set oauth_client_id = excluded.oauth_client_id,
    display_name = excluded.display_name, first_party = excluded.first_party,
    allowed_claims = excluded.allowed_claims, allowed_rpcs = excluded.allowed_rpcs,
    allowed_tables = excluded.allowed_tables, updated_by = u, updated_at = now();
  insert into public.activity_logs(profile_id, action, target_table, description)
  values (u, 'sso.app.save', 'app_clients_r18', jsonb_build_object('app_code', v_code, 'client_id', p_client_id,
    'claims', v_claims, 'rpcs', v_rpcs, 'tables', v_tables)::text);
end $$;

create or replace function kaoid_private.app_client_set_status_r18(p_app_code text, p_status text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform kaoid_private.require_registry_owner_r18();
  if p_status is null or p_status not in ('active', 'suspended') then
    raise exception 'invalid_app_client' using errcode = '22023';
  end if;
  update kaoid_private.app_clients_r18 set status = p_status, updated_by = auth.uid(), updated_at = now()
   where app_code = p_app_code;
  if not found then raise exception 'app_client_not_found' using errcode = '22023'; end if;
  insert into public.activity_logs(profile_id, action, target_table, description)
  values (auth.uid(), 'sso.app.status', 'app_clients_r18',
    jsonb_build_object('app_code', p_app_code, 'status', p_status)::text);
end $$;

create or replace function public.app_clients_list_r18() returns jsonb
language sql set search_path = '' as $$ select kaoid_private.app_clients_list_r18(); $$;
create or replace function public.app_client_save_r18(
  p_app_code text, p_client_id uuid, p_display_name text, p_first_party boolean,
  p_claims text[], p_rpcs text[], p_tables text[]
) returns void language sql set search_path = '' as $$
  select kaoid_private.app_client_save_r18(p_app_code, p_client_id, p_display_name, p_first_party,
    p_claims, p_rpcs, p_tables);
$$;
create or replace function public.app_client_set_status_r18(p_app_code text, p_status text) returns void
language sql set search_path = '' as $$ select kaoid_private.app_client_set_status_r18(p_app_code, p_status); $$;

-- ---------------------------------------------------------------------------
-- Storage does not run the PostgREST pre-request hook: keep app tokens out of
-- identity documents and the Kao ID avatar folder.
-- ---------------------------------------------------------------------------
create policy sso_app_storage_r18 on storage.objects as restrictive for all to authenticated
  using (nullif(auth.jwt()->>'client_id', '') is null or bucket_id not in ('identity-documents', 'avatars'))
  with check (nullif(auth.jwt()->>'client_id', '') is null or bucket_id not in ('identity-documents', 'avatars'));

-- ---------------------------------------------------------------------------
-- Legacy OAuth tables (empty, never wired): no client access until removed
-- ---------------------------------------------------------------------------
revoke all on table public.oauth_clients, public.oauth_tokens, public.api_keys, public.sessions
  from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
revoke all on function
  kaoid_private.oauth_never_r18(text),
  kaoid_private.current_app_r18(),
  kaoid_private.oauth_client_guard_r18(),
  kaoid_private.kyc_status_r18(uuid),
  kaoid_private.kao_id_claims_r18(),
  kaoid_private.app_directory_r18(),
  kaoid_private.require_registry_owner_r18(),
  kaoid_private.app_clients_list_r18(),
  kaoid_private.app_client_save_r18(text, uuid, text, boolean, text[], text[], text[]),
  kaoid_private.app_client_set_status_r18(text, text),
  public.kao_id_claims_r18(),
  public.app_directory_r18(),
  public.app_clients_list_r18(),
  public.app_client_save_r18(text, uuid, text, boolean, text[], text[], text[]),
  public.app_client_set_status_r18(text, text)
from public, anon, authenticated;

revoke all on function kaoid_private.pre_request_r10d() from public;
grant execute on function kaoid_private.pre_request_r10d() to anon, authenticated, service_role;

grant execute on function
  kaoid_private.kao_id_claims_r18(),
  kaoid_private.app_directory_r18(),
  kaoid_private.app_clients_list_r18(),
  kaoid_private.app_client_save_r18(text, uuid, text, boolean, text[], text[], text[]),
  kaoid_private.app_client_set_status_r18(text, text),
  public.kao_id_claims_r18(),
  public.app_directory_r18(),
  public.app_clients_list_r18(),
  public.app_client_save_r18(text, uuid, text, boolean, text[], text[], text[]),
  public.app_client_set_status_r18(text, text)
to authenticated;
