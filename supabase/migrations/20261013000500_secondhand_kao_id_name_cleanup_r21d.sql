-- R21d: Kao ID market names read naturally.
--   * Control characters and runs of whitespace become one space, so
--     "E2E<TAB>Shop" stays "E2E Shop" instead of "E2EShop".
--   * A member with neither display name nor username shows as
--     "สมาชิก KaoSure", the name used everywhere else in the market.

create or replace function secondhand.kao_id_name_r21c(p_profile_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(nullif(btrim(left(btrim(regexp_replace(
           coalesce(nullif(btrim(p.display_name), ''), nullif(btrim(p.username), ''), ''),
           '[[:cntrl:][:space:]]+', ' ', 'g')), 60)), ''), 'สมาชิก KaoSure')
    from public.profiles p
   where p.id = p_profile_id
$$;

revoke all on function secondhand.kao_id_name_r21c(uuid) from public, anon, authenticated;

-- The R21c trigger recomputes the name on any update.
update secondhand.member_profiles m
   set display_name = secondhand.kao_id_name_r21c(m.profile_id)
 where m.display_name is distinct from secondhand.kao_id_name_r21c(m.profile_id);
