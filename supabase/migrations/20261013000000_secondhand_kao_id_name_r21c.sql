-- R21c: the market name (and so the personal shop name) comes from Kao ID only.
--   * Members change their name in Kao ID (public.profiles.display_name); the
--     market profile and the personal shop follow automatically.
--   * Secondhand can no longer write member_profiles.display_name; avatar and
--     bio stay editable there.

-- Kao ID display name, else username, cleaned to fit the market profile.
create or replace function secondhand.kao_id_name_r21c(p_profile_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(nullif(left(btrim(regexp_replace(
           coalesce(nullif(btrim(p.display_name), ''), nullif(btrim(p.username), ''), ''),
           '[[:cntrl:]]', '', 'g')), 60), ''), 'Member')
    from public.profiles p
   where p.id = p_profile_id
$$;

revoke all on function secondhand.kao_id_name_r21c(uuid) from public, anon, authenticated;

-- Whatever is written, the stored name is the Kao ID one.
create or replace function secondhand.member_profile_name_r21c() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  new.display_name := coalesce(secondhand.kao_id_name_r21c(new.profile_id), new.display_name);
  return new;
end $$;

revoke all on function secondhand.member_profile_name_r21c() from public, anon, authenticated;

create trigger member_profiles_name_r21c
before insert or update on secondhand.member_profiles
for each row execute function secondhand.member_profile_name_r21c();

revoke update (display_name) on table secondhand.member_profiles from authenticated;

-- A Kao ID name change reaches the market profile, which renames the personal
-- shop (member_profiles_sync_shop_name_r20b). Shops of members who never opened
-- their market profile are renamed directly.
create or replace function secondhand.follow_kao_id_name_r21c() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_name text := secondhand.kao_id_name_r21c(new.id);
begin
  update secondhand.member_profiles m
     set display_name = v_name
   where m.profile_id = new.id;
  if not found then
    update public.shops s
       set shop_name = v_name, updated_at = now()
     where s.owner_id = new.id and s.seller_identity_type = 'personal'
       and s.shop_name is distinct from v_name;
  end if;
  return null;
end $$;

revoke all on function secondhand.follow_kao_id_name_r21c() from public, anon, authenticated;

create trigger profiles_market_name_r21c
after update of display_name, username on public.profiles
for each row
when (old.display_name is distinct from new.display_name or old.username is distinct from new.username)
execute function secondhand.follow_kao_id_name_r21c();
