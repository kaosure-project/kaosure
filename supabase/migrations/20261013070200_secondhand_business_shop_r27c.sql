-- R27c (3/3): a verified company opens its Secondhand shop.
-- The owner, a director, an authorized person or an admin of an organization with an active business Kao ID
-- may open the organization's single business shop. Listing still needs the verified company bank
-- (secondhand.shop_sell_status_r27).

create or replace function secondhand.open_business_shop(p_organization_id uuid, p_shop_name text,
                                                         p_description text default null)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  v_name text := btrim(coalesce(p_shop_name, ''));
  s public.shops;
begin
  if not exists (select 1 from public.kao_id_identities k
                  where k.profile_id = u and k.identity_type = 'personal' and k.organization_id is null
                    and k.status = 'active') then
    raise exception 'kao_id_required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.organization_members m
                   join public.organizations o on o.id = m.organization_id and o.status = 'active'
                  where m.organization_id = p_organization_id and m.profile_id = u and m.status = 'active'
                    and (m.ends_at is null or m.ends_at > now())
                    and m.role in ('owner', 'director', 'authorized_person', 'admin')) then
    raise exception 'org_role_required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.kao_id_identities k
                  where k.organization_id = p_organization_id and k.identity_type = 'business'
                    and k.profile_id is null and k.status = 'active') then
    raise exception 'business_kao_id_required' using errcode = '42501';
  end if;
  if length(v_name) not between 2 and 80 or v_name ~ '[[:cntrl:]]' then
    raise exception 'invalid_shop_name' using errcode = '22023';
  end if;
  if length(coalesce(p_description, '')) > 1000 then
    raise exception 'invalid_description' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('business-shop:' || p_organization_id, 274));
  if exists (select 1 from public.shops where organization_id = p_organization_id
                and seller_identity_type = 'business') then
    raise exception 'shop_exists' using errcode = '23505';
  end if;
  insert into public.shops(owner_id, organization_id, seller_identity_type, shop_name, shop_slug, description)
  values (u, p_organization_id, 'business', v_name, 'biz-' || replace(p_organization_id::text, '-', ''),
          nullif(btrim(coalesce(p_description, '')), ''))
  returning * into s;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'secondhand.business_shop.open', 'shops', s.id, null);
  return jsonb_build_object('shop_id', s.id, 'shop_name', s.shop_name, 'kind', 'business',
                            'organization_id', p_organization_id,
                            'sell_status', secondhand.shop_sell_status_r27(s.id));
end $$;

-- Shops this member can act for, their open invitations, and verified organizations that can still open a shop.
create or replace function secondhand.my_shops()
returns jsonb
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
begin
  return jsonb_build_object(
    'shops', coalesce((
      select jsonb_agg(jsonb_build_object(
               'shop_id', s.id, 'shop_name', s.shop_name, 'kind', s.seller_identity_type,
               'shop_status', s.shop_status,
               'organization_id', s.organization_id,
               'organization_name', (select o.name from public.organizations o where o.id = s.organization_id),
               'permissions', x.perms,
               'sell_status', secondhand.shop_sell_status_r27(s.id),
               'to_ship', case when (x.perms->>'orders')::boolean then
                 (select count(*) from public.orders o where o.shop_id = s.id and o.order_status = 'paid') end,
               'open_questions', case when (x.perms->>'chat')::boolean then
                 (select count(*) from secondhand.listing_questions q join public.products p on p.id = q.product_id
                   where p.shop_id = s.id and q.answer is null and not q.is_hidden and p.status = 'active') end)
             order by s.seller_identity_type desc, s.created_at)
        from public.shops s
        cross join lateral (select secondhand.shop_perms_r27(s.id, u) as perms) x
       where ((s.seller_identity_type = 'personal' and s.owner_id = u)
              or (s.seller_identity_type = 'business'
                  and (exists (select 1 from public.organization_members om
                                where om.organization_id = s.organization_id and om.profile_id = u
                                  and om.status = 'active')
                       or exists (select 1 from public.shop_staff ss
                                   where ss.shop_id = s.id and ss.profile_id = u and ss.is_active))))
         and exists (select 1 from jsonb_each_text(x.perms) p where p.value = 'true')), '[]'::jsonb),
    'invites', coalesce((
      select jsonb_agg(secondhand.invite_json_r27(i) order by i.created_at desc)
        from secondhand.shop_staff_invites i
       where i.profile_id = u and i.invite_status = 'pending' and i.expires_at > now()), '[]'::jsonb),
    'can_open', coalesce((
      select jsonb_agg(jsonb_build_object('organization_id', o.id, 'organization_name', o.name,
                                          'business_kao_id', k.kao_id) order by m.created_at)
        from public.organization_members m
        join public.organizations o on o.id = m.organization_id and o.status = 'active'
        join public.kao_id_identities k on k.organization_id = o.id and k.identity_type = 'business'
                                       and k.status = 'active'
       where m.profile_id = u and m.status = 'active' and (m.ends_at is null or m.ends_at > now())
         and m.role in ('owner', 'director', 'authorized_person', 'admin')
         and not exists (select 1 from public.shops s
                          where s.organization_id = o.id and s.seller_identity_type = 'business')), '[]'::jsonb));
end $$;

revoke all on function secondhand.open_business_shop(uuid, text, text) from public, anon, authenticated;
grant execute on function secondhand.open_business_shop(uuid, text, text) to authenticated;
