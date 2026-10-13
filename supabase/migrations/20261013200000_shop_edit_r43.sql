-- R43: the shop edit page, the shop banner and the business shop logo.
-- A personal shop's face is the member's market profile (name from Kao ID, avatar and bio in
-- secondhand.member_profiles); only its banner lives on the shop. A business shop keeps its name, logo,
-- description and banner on public.shops. Members never update public.shops directly: every change goes through
-- update_shop_profile, which checks the 'shop' permission and writes the shop audit trail.

-- ---------------------------------------------------------------------------
-- Audit trail
-- ---------------------------------------------------------------------------
alter table secondhand.shop_staff_events drop constraint shop_staff_events_action_check;
alter table secondhand.shop_staff_events add constraint shop_staff_events_action_check
  check (action = any (array['invited', 'invite_cancelled', 'invite_accepted', 'invite_declined', 'invite_expired',
                             'updated', 'removed', 'left', 'shop_updated', 'shop_renamed']));

-- ---------------------------------------------------------------------------
-- Shop media: public read, written only by members holding the shop's 'shop' permission
-- ---------------------------------------------------------------------------
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('secondhand-shop-media', 'secondhand-shop-media', true, 2097152, array['image/jpeg'])
on conflict (id) do nothing;

-- p_folder is the first folder of an object name; anything that is not a shop id is refused without casting errors.
create or replace function secondhand.shop_media_writer_r43(p_folder text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := case when coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then null else auth.uid() end;
  v_shop uuid;
begin
  if u is null or p_folder is null
     or p_folder !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return false;
  end if;
  v_shop := p_folder::uuid;
  return kaoid_private.account_active_r9f()
     and exists (select 1 from public.shops s where s.id = v_shop and s.shop_status = 'active')
     and secondhand.shop_can_r27(v_shop, 'shop', u);
end $$;

revoke all on function secondhand.shop_media_writer_r43(text) from public, anon;
grant execute on function secondhand.shop_media_writer_r43(text) to authenticated;

drop policy if exists secondhand_shop_media_select on storage.objects;
drop policy if exists secondhand_shop_media_insert on storage.objects;
drop policy if exists secondhand_shop_media_delete on storage.objects;
create policy secondhand_shop_media_select on storage.objects for select to authenticated
  using (bucket_id = 'secondhand-shop-media'
         and (select secondhand.shop_media_writer_r43((storage.foldername(name))[1])));
create policy secondhand_shop_media_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'secondhand-shop-media'
              and (select secondhand.shop_media_writer_r43((storage.foldername(name))[1])));
create policy secondhand_shop_media_delete on storage.objects for delete to authenticated
  using (bucket_id = 'secondhand-shop-media'
         and (select secondhand.shop_media_writer_r43((storage.foldername(name))[1])));

-- p_kind is 'logo' or 'banner'; the file must sit in the shop's own folder.
create or replace function secondhand.shop_media_url_ok(p_shop uuid, p_url text, p_kind text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select p_url is null
      or (p_kind in ('logo', 'banner')
          and char_length(p_url) <= 1024
          and p_url ~ ('^https://[a-z0-9.-]+(:[0-9]+)?/storage/v1/object/public/secondhand-shop-media/[0-9a-f-]{36}/'
                       || p_kind || '-[A-Za-z0-9_-]{1,100}\.jpg$')
          and split_part(split_part(p_url, '/secondhand-shop-media/', 2), '/', 1) = p_shop::text);
$$;

alter table public.shops drop constraint if exists shops_logo_url_r43;
alter table public.shops drop constraint if exists shops_banner_url_r43;
alter table public.shops add constraint shops_logo_url_r43
  check (secondhand.shop_media_url_ok(id, logo_url, 'logo'));
alter table public.shops add constraint shops_banner_url_r43
  check (secondhand.shop_media_url_ok(id, banner_url, 'banner'));

-- ---------------------------------------------------------------------------
-- Shop settings
-- ---------------------------------------------------------------------------
create or replace function secondhand.shop_settings_r43(p_shop uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'shop_id', s.id,
    'kind', s.seller_identity_type,
    'shop_name', case when s.seller_identity_type = 'personal'
                      then coalesce(nullif(btrim(m.display_name), ''), s.shop_name) else s.shop_name end,
    'avatar_url', case when s.seller_identity_type = 'personal' then m.avatar_url else s.logo_url end,
    'bio', case when s.seller_identity_type = 'personal' then m.bio else s.description end,
    'banner_url', s.banner_url,
    'renamed_at', x.renamed_at,
    'rename_available_at', x.renamed_at + interval '30 days',
    'can_rename', s.seller_identity_type = 'business'
                  and (x.renamed_at is null or x.renamed_at + interval '30 days' <= now()))
    from public.shops s
    left join secondhand.member_profiles m on m.profile_id = s.owner_id
   cross join lateral (select max(e.created_at) as renamed_at
                         from secondhand.shop_staff_events e
                        where e.shop_id = s.id and e.action = 'shop_renamed') x
   where s.id = p_shop
$$;

revoke all on function secondhand.shop_settings_r43(uuid) from public, anon, authenticated;

-- p_shop_id null: the caller's personal shop, or null when the member has not opened one yet.
create or replace function secondhand.get_shop_settings(p_shop_id uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := case when coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then null else auth.uid() end;
  v_shop uuid := p_shop_id;
begin
  if u is null or not kaoid_private.account_active_r9f() then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if v_shop is null then
    select s.id into v_shop from public.shops s
     where s.owner_id = u and s.seller_identity_type = 'personal'
     order by s.created_at limit 1;
    if v_shop is null then
      return null;
    end if;
  end if;
  if not exists (select 1 from public.shops s where s.id = v_shop) then
    raise exception 'Shop not found' using errcode = '22023';
  end if;
  if not secondhand.shop_can_r27(v_shop, 'shop', u) then
    raise exception 'Not allowed' using errcode = '42501';
  end if;
  return secondhand.shop_settings_r43(v_shop);
end $$;

revoke all on function secondhand.get_shop_settings(uuid) from public, anon;
grant execute on function secondhand.get_shop_settings(uuid) to authenticated;

-- p_changes holds only the fields being changed: shop_name, description and logo_url (business shops) and
-- banner_url. A business shop is renamed at most once per 30 days. replaced_paths lists the shop's old media
-- files for the app to delete.
create or replace function secondhand.update_shop_profile(p_shop_id uuid, p_changes jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := case when coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then null else auth.uid() end;
  s public.shops;
  v_name text;
  v_description text;
  v_url text;
  v_renamed boolean := false;
  v_changed text[] := '{}';
  v_replaced text[] := '{}';
begin
  if u is null or not kaoid_private.account_active_r9f() then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_changes is null or jsonb_typeof(p_changes) <> 'object'
     or exists (select 1 from jsonb_each(p_changes) e
                 where e.key not in ('shop_name', 'description', 'logo_url', 'banner_url')
                    or jsonb_typeof(e.value) not in ('string', 'null')) then
    raise exception 'invalid_changes' using errcode = '22023';
  end if;

  select * into s from public.shops where id = p_shop_id for update;
  if not found then
    raise exception 'Shop not found' using errcode = '22023';
  end if;
  if not secondhand.shop_can_r27(s.id, 'shop', u) then
    raise exception 'Not allowed' using errcode = '42501';
  end if;
  if s.shop_status <> 'active' then
    raise exception 'Shop is not active' using errcode = '42501';
  end if;
  if s.seller_identity_type = 'personal' and p_changes ?| array['shop_name', 'description', 'logo_url'] then
    raise exception 'personal_shop_uses_market_profile' using errcode = '22023';
  end if;

  if p_changes ? 'shop_name' then
    v_name := btrim(p_changes->>'shop_name');
    if v_name is null or char_length(v_name) not between 1 and 60 or v_name ~ '[[:cntrl:]]' then
      raise exception 'Shop name is invalid' using errcode = '22023';
    end if;
    if v_name is distinct from s.shop_name then
      if exists (select 1 from secondhand.shop_staff_events e
                  where e.shop_id = s.id and e.action = 'shop_renamed'
                    and e.created_at > now() - interval '30 days') then
        raise exception 'shop_rename_too_soon' using errcode = '22023';
      end if;
      update public.shops set shop_name = v_name where id = s.id;
      v_renamed := true;
      perform secondhand.shop_event_r27(s.id, u, null, 'shop_renamed',
                                        jsonb_build_object('from', s.shop_name, 'to', v_name));
    end if;
  end if;

  if p_changes ? 'description' then
    v_description := nullif(btrim(p_changes->>'description'), '');
    if char_length(v_description) > 500 then
      raise exception 'Shop description is too long' using errcode = '22023';
    end if;
    if v_description is distinct from s.description then
      update public.shops set description = v_description where id = s.id;
      v_changed := array_append(v_changed, 'description');
    end if;
  end if;

  if p_changes ? 'logo_url' then
    v_url := p_changes->>'logo_url';
    if not secondhand.shop_media_url_ok(s.id, v_url, 'logo') then
      raise exception 'Photo is invalid' using errcode = '22023';
    end if;
    if v_url is distinct from s.logo_url then
      update public.shops set logo_url = v_url where id = s.id;
      v_changed := array_append(v_changed, 'logo_url');
      if s.logo_url is not null then
        v_replaced := v_replaced || split_part(s.logo_url, '/secondhand-shop-media/', 2);
      end if;
    end if;
  end if;

  if p_changes ? 'banner_url' then
    v_url := p_changes->>'banner_url';
    if not secondhand.shop_media_url_ok(s.id, v_url, 'banner') then
      raise exception 'Photo is invalid' using errcode = '22023';
    end if;
    if v_url is distinct from s.banner_url then
      update public.shops set banner_url = v_url where id = s.id;
      v_changed := array_append(v_changed, 'banner_url');
      if s.banner_url is not null then
        v_replaced := v_replaced || split_part(s.banner_url, '/secondhand-shop-media/', 2);
      end if;
    end if;
  end if;

  if cardinality(v_changed) > 0 then
    perform secondhand.shop_event_r27(s.id, u, null, 'shop_updated', jsonb_build_object('fields', v_changed));
  end if;
  if cardinality(v_changed) > 0 or v_renamed then
    update public.shops set updated_at = now() where id = s.id;
  end if;

  return secondhand.shop_settings_r43(s.id) || jsonb_build_object('replaced_paths', to_jsonb(v_replaced));
end $$;

revoke all on function secondhand.update_shop_profile(uuid, jsonb) from public, anon;
grant execute on function secondhand.update_shop_profile(uuid, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- The shop page: banner, business logo, and the edit button for whoever may edit
-- ---------------------------------------------------------------------------
create or replace function secondhand.seller_card_r20d(p_shop_id uuid)
returns jsonb
language sql
stable security definer
set search_path to ''
as $$
  select jsonb_build_object(
    'shop_id', s.id,
    'shop_name', s.shop_name,
    'shop_slug', s.shop_slug,
    'shop_description', s.description,
    'province', s.province,
    'joined_at', s.created_at,
    'kind', s.seller_identity_type,
    'display_name', case when s.seller_identity_type = 'personal'
                         then coalesce(nullif(btrim(m.display_name), ''), s.shop_name) else s.shop_name end,
    'avatar_url', case when s.seller_identity_type = 'personal' then m.avatar_url else s.logo_url end,
    'banner_url', s.banner_url,
    'bio', case when s.seller_identity_type = 'personal' then m.bio else s.description end,
    'is_verified', case when s.seller_identity_type = 'personal'
                        then coalesce((secondhand.seller_status_r20f(s.owner_id)->>'verified')::boolean, false)
                        else coalesce((secondhand.shop_sell_status_r27(s.id)->>'can_list')::boolean, false) end,
    'follower_count', (select count(*) from public.followers f where f.shop_id = s.id),
    'sold_count', (select count(*) from public.orders o where o.shop_id = s.id and o.order_status = 'completed'),
    'on_sale_count', (select count(*) from public.products p
                       join public.categories c on c.id = p.category_id and c.is_active
                      where p.shop_id = s.id and p.status = 'active' and p.is_active and p.stock > 0)
  ) || secondhand.shop_rating_r42(s.id)
  from public.shops s
  left join secondhand.member_profiles m on m.profile_id = s.owner_id
  where s.id = p_shop_id
$$;

revoke all on function secondhand.seller_card_r20d(uuid) from public, anon, authenticated;

-- block_id: the viewer's own block of the owner, for "เลิกบล็อก". blocked: a block either way, so no following.
-- can_edit: the viewer holds the shop's 'shop' permission (the owner, or business staff allowed to manage it).
create or replace function secondhand.get_shop_profile(p_shop_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select secondhand.seller_card_r20d(s.id)
         || jsonb_build_object(
              'is_owner', v.u is not null and s.owner_id = v.u,
              'can_edit', v.u is not null and s.shop_status = 'active' and secondhand.shop_can_r27(s.id, 'shop', v.u),
              'shipping', secondhand.shop_shipping_r36(s.id),
              'sold_items_count', (select count(*) from public.products p
                                    where p.shop_id = s.id and p.status = 'sold' and p.is_active),
              'block_id', (select b.id from public.user_blocks b
                            where b.blocker_profile_id = v.u and b.blocked_profile_id = s.owner_id and b.is_active
                              and (b.expires_at is null or b.expires_at > now())),
              'blocked', v.u is not null and secondhand.blocked_between_r21b(v.u, s.owner_id),
              'reported', v.u is not null and exists (select 1 from secondhand.shop_reports r
                                                        where r.shop_id = s.id and r.reporter_id = v.u)
            )
    from public.shops s
   cross join (select case when coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then null
                           else auth.uid() end as u) v
   where s.id = p_shop_id
     and (s.shop_status = 'active' or (v.u is not null and s.owner_id = v.u))
$$;

revoke all on function secondhand.get_shop_profile(uuid) from public;
grant execute on function secondhand.get_shop_profile(uuid) to anon, authenticated;

update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
         'secondhand.get_shop_settings', 'secondhand.update_shop_profile']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
