-- R19b: Secondhand gets its own schema and market profile.
--
-- secondhand.member_profiles is the member's face in the market (name, avatar,
-- bio). It is created once from Kao ID (name only, Y1) and is independent from
-- then on: Kao ID profile edits never change it and the app never writes Kao ID.
-- Avatars live in the app's own bucket because Kao ID deletes replaced avatars.

create schema if not exists secondhand;
revoke all on schema secondhand from public;
grant usage on schema secondhand to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Market profile
-- ---------------------------------------------------------------------------
create or replace function secondhand.avatar_url_ok(p_profile uuid, p_url text) returns boolean
language sql immutable set search_path = '' as $$
  select p_url is null
      or (char_length(p_url) <= 1024
          and p_url ~ '^https://[a-z0-9.-]+(:[0-9]+)?/storage/v1/object/public/secondhand-avatars/[0-9a-f-]{36}/[A-Za-z0-9._-]{1,128}$'
          and split_part(split_part(p_url, '/secondhand-avatars/', 2), '/', 1) = p_profile::text);
$$;

create table secondhand.member_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  display_name text not null
    check (char_length(btrim(display_name)) between 1 and 60 and display_name !~ '[[:cntrl:]]'),
  avatar_url text check (secondhand.avatar_url_ok(profile_id, avatar_url)),
  bio text check (bio is null or (char_length(bio) <= 500)),
  seeded_from_kao_id_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function secondhand.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger member_profiles_touch before update on secondhand.member_profiles
  for each row execute function secondhand.touch_updated_at();

alter table secondhand.member_profiles enable row level security;
revoke all on table secondhand.member_profiles from public, anon, authenticated;
grant select on table secondhand.member_profiles to anon, authenticated;
grant update (display_name, avatar_url, bio) on table secondhand.member_profiles to authenticated;
grant all on table secondhand.member_profiles to service_role;

create policy member_profiles_read on secondhand.member_profiles for select to anon, authenticated
  using (true);
create policy member_profiles_update_own on secondhand.member_profiles for update to authenticated
  using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));
create policy account_closure_r10d on secondhand.member_profiles as restrictive for all to authenticated
  using ((select kaoid_private.data_access_r10d())) with check ((select kaoid_private.data_access_r10d()));

-- Creates the market profile on first use. Only the name is taken from Kao ID;
-- the avatar must already be a copy in the member's secondhand-avatars folder.
create or replace function secondhand.ensure_member_profile(p_avatar_url text default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid();
  r secondhand.member_profiles;
  v_name text;
  v_created boolean := false;
begin
  if u is null then raise exception 'authentication_required' using errcode = '42501'; end if;
  if coalesce(kaoid_private.account_access_r10d()->>'state', '') <> 'active' then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  select * into r from secondhand.member_profiles where profile_id = u;
  if not found then
    select left(btrim(regexp_replace(coalesce(nullif(btrim(p.display_name), ''), nullif(btrim(p.username), ''), ''),
             '[[:cntrl:]]', '', 'g')), 60)
      into v_name from public.profiles p where p.id = u;
    insert into secondhand.member_profiles(profile_id, display_name, avatar_url, seeded_from_kao_id_at)
    values (u, coalesce(nullif(v_name, ''), 'Member'),
            case when secondhand.avatar_url_ok(u, nullif(btrim(p_avatar_url), '')) then nullif(btrim(p_avatar_url), '') end,
            now())
    on conflict (profile_id) do nothing;
    v_created := found;
    select * into r from secondhand.member_profiles where profile_id = u;
  end if;
  return jsonb_build_object('profile_id', r.profile_id, 'display_name', r.display_name,
    'avatar_url', r.avatar_url, 'bio', r.bio, 'created', v_created);
end $$;

revoke all on function secondhand.ensure_member_profile(text) from public, anon, authenticated;
grant execute on function secondhand.ensure_member_profile(text) to authenticated;
revoke all on function secondhand.touch_updated_at() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Market avatars: public read, members write only their own folder
-- ---------------------------------------------------------------------------
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('secondhand-avatars', 'secondhand-avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy secondhand_avatars_select_own on storage.objects for select to authenticated
  using (bucket_id = 'secondhand-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy secondhand_avatars_insert_own on storage.objects for insert to authenticated
  with check (bucket_id = 'secondhand-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy secondhand_avatars_update_own on storage.objects for update to authenticated
  using (bucket_id = 'secondhand-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'secondhand-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy secondhand_avatars_delete_own on storage.objects for delete to authenticated
  using (bucket_id = 'secondhand-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
-- Secondhand token scope
-- ---------------------------------------------------------------------------
update kaoid_private.app_clients_r18
   set allowed_tables = array(select distinct t from unnest(allowed_tables || array['secondhand.member_profiles:write']) t order by 1),
       allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array['secondhand.ensure_member_profile']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
