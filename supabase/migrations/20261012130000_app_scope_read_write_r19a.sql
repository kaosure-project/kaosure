-- R19a: app tokens are scoped by schema and by read/write.
--
-- Allow-list entries are schema-qualified:
--   allowed_rpcs   'public.create_personal_shop'
--   allowed_tables 'public.products'          read (GET/HEAD) only
--                  'public.favorites:write'   read and write (POST/PATCH/PUT/DELETE)
-- Kao ID's own profile row is read-only for every app token, and the dormant
-- "anyone may write" policies on money tables are removed.

-- ---------------------------------------------------------------------------
-- Allow-list format
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.app_scope_entry_ok_r19a(p_entry text, p_kind text) returns boolean
language sql immutable set search_path = '' as $$
  select coalesce(
    case p_kind
      when 'rpc' then p_entry ~ '^[a-z_][a-z0-9_]{0,62}\.[a-z_][a-z0-9_]{0,62}$'
      else p_entry ~ '^[a-z_][a-z0-9_]{0,62}\.[a-z_][a-z0-9_]{0,62}(:write)?$'
    end
    and split_part(p_entry, '.', 1) not in ('auth', 'storage', 'kaoid_private', 'extensions', 'vault',
      'pgsodium', 'realtime', 'graphql', 'graphql_public', 'supabase_functions', 'supabase_migrations',
      'net', 'cron', 'pg_catalog', 'information_schema')
    and not kaoid_private.oauth_never_r18(split_part(split_part(p_entry, ':', 1), '.', 2)),
    false);
$$;

create or replace function kaoid_private.app_scope_list_ok_r19a(p_entries text[], p_kind text) returns boolean
language sql immutable set search_path = '' as $$
  select cardinality(coalesce(p_entries, '{}')) <= 100
     and coalesce(bool_and(kaoid_private.app_scope_entry_ok_r19a(e, p_kind)), true)
    from unnest(coalesce(p_entries, '{}')) e;
$$;

-- Bare names from older registries mean the public schema.
create or replace function kaoid_private.app_scope_entries_r19a(p_names text[]) returns text[]
language sql immutable set search_path = '' as $$
  select coalesce(array_agg(distinct case when n like '%.%' then n else 'public.' || n end order by
                   case when n like '%.%' then n else 'public.' || n end), '{}')
    from (select lower(btrim(x)) n from unnest(coalesce(p_names, '{}')) x where btrim(x) <> '') s;
$$;

update kaoid_private.app_clients_r18
   set allowed_rpcs = kaoid_private.app_scope_entries_r19a(allowed_rpcs),
       allowed_tables = kaoid_private.app_scope_entries_r19a(allowed_tables),
       updated_at = now();

update kaoid_private.app_clients_r18
   set allowed_tables = array(
         select case when t in ('public.favorites', 'public.followers', 'public.recently_viewed', 'public.notifications')
                     then t || ':write' else t end
           from unnest(allowed_tables) t order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';

alter table kaoid_private.app_clients_r18
  add constraint app_clients_r18_rpcs_scoped check (kaoid_private.app_scope_list_ok_r19a(allowed_rpcs, 'rpc')),
  add constraint app_clients_r18_tables_scoped check (kaoid_private.app_scope_list_ok_r19a(allowed_tables, 'table'));

-- ---------------------------------------------------------------------------
-- Request guard: schema from Accept-Profile / Content-Profile, write needs :write
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.oauth_client_guard_r18() returns void
language plpgsql stable security definer set search_path = '' as $$
declare
  app kaoid_private.app_clients_r18;
  path text := trim(both '/' from coalesce(current_setting('request.path', true), ''));
  method text := upper(coalesce(nullif(current_setting('request.method', true), ''), 'GET'));
  headers jsonb := coalesce(nullif(current_setting('request.headers', true), ''), '{}')::jsonb;
  reading boolean;
  schema_name text;
  target text;
begin
  if nullif(auth.jwt()->>'client_id', '') is null then return; end if;
  app := kaoid_private.current_app_r18();
  reading := method in ('GET', 'HEAD');
  schema_name := lower(coalesce(
    nullif(btrim(headers->>(case when reading then 'accept-profile' else 'content-profile' end)), ''),
    'public'));
  if path like 'rpc/%' then
    target := substr(path, 5);
    if schema_name = 'public' and target in ('kao_id_claims_r18', 'account_access_r10d') then return; end if;
    if schema_name || '.' || target = any(app.allowed_rpcs)
       and kaoid_private.app_scope_entry_ok_r19a(schema_name || '.' || target, 'rpc') then
      return;
    end if;
  else
    target := schema_name || '.' || split_part(path, '/', 1);
    if kaoid_private.app_scope_entry_ok_r19a(target, 'table')
       and (target || ':write' = any(app.allowed_tables)
            or (reading and target = any(app.allowed_tables))) then
      return;
    end if;
  end if;
  raise exception 'client_scope_denied' using errcode = '42501';
end $$;

-- ---------------------------------------------------------------------------
-- Registry save: same signature, qualified names
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.app_client_save_r18(
  p_app_code text, p_client_id uuid, p_display_name text, p_first_party boolean,
  p_claims text[], p_rpcs text[], p_tables text[]
) returns void language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid();
  v_code text := lower(btrim(p_app_code));
  v_name text := btrim(p_display_name);
  v_rpcs text[] := kaoid_private.app_scope_entries_r19a(p_rpcs);
  v_tables text[] := kaoid_private.app_scope_entries_r19a(p_tables);
  v_claims text[] := array(select distinct x from unnest(coalesce(p_claims, '{}')) x);
begin
  perform kaoid_private.require_registry_owner_r18();
  if v_code is null or v_code !~ '^[a-z][a-z0-9_]{2,39}$' or p_client_id is null
     or v_name is null or length(v_name) not between 2 and 80 or p_first_party is null
     or not (v_claims <@ array['profile', 'verification', 'business', 'roles']::text[])
     or not kaoid_private.app_scope_list_ok_r19a(v_rpcs, 'rpc')
     or not kaoid_private.app_scope_list_ok_r19a(v_tables, 'table') then
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

-- ---------------------------------------------------------------------------
-- Kao ID profile: never writable with an app token, whatever the allow-list says
-- ---------------------------------------------------------------------------
create policy kao_id_profile_insert_r19a on public.profiles as restrictive for insert to authenticated
  with check ((select nullif(auth.jwt()->>'client_id', '')) is null);
create policy kao_id_profile_update_r19a on public.profiles as restrictive for update to authenticated
  using ((select nullif(auth.jwt()->>'client_id', '')) is null)
  with check ((select nullif(auth.jwt()->>'client_id', '')) is null);
create policy kao_id_profile_delete_r19a on public.profiles as restrictive for delete to authenticated
  using ((select nullif(auth.jwt()->>'client_id', '')) is null);

-- ---------------------------------------------------------------------------
-- Money tables: writes only through server-side functions
-- ---------------------------------------------------------------------------
drop policy if exists "System can create escrow" on public.escrow_transactions;
drop policy if exists "System can update escrow" on public.escrow_transactions;
drop policy if exists "Users can create orders" on public.orders;
drop policy if exists "Users can update own orders" on public.orders;
drop policy if exists "Users can create withdraw" on public.withdraw_requests;

revoke insert, update, delete, truncate on table
  public.orders, public.escrow_transactions, public.payment_transactions, public.withdraw_requests,
  public.wallets, public.wallet_transactions, public.payment_methods
from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
revoke all on function
  kaoid_private.app_scope_entry_ok_r19a(text, text),
  kaoid_private.app_scope_list_ok_r19a(text[], text),
  kaoid_private.app_scope_entries_r19a(text[])
from public, anon, authenticated;
