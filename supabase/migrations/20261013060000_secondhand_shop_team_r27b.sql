-- R27b (1/3): corporate shops run by a team.
-- Sale proceeds of a business shop go to the organization's wallet; only the organization's owner or finance
-- role may withdraw them, to the organization's verified bank account. Everyone acting for a business shop
-- (organization admins and invited shop staff) must hold an active personal Kao ID, so every action is traceable.
-- Staff are invited by Kao ID, invitations expire after 7 days, and every change is written to shop_staff_events.

alter table public.wallets alter column profile_id drop not null;
alter table public.wallets add column organization_id uuid references public.organizations(id) on delete restrict;
alter table public.wallets add constraint wallets_one_owner_r27b check (num_nonnulls(profile_id, organization_id) = 1);
alter table public.wallets add constraint wallets_organization_unique_r27b unique (organization_id);

-- chk_bank_account_owner_exactly_one already requires one owner; organization accounts carry no profile.
alter table public.bank_accounts alter column profile_id drop not null;

alter table public.withdraw_requests add column organization_id uuid references public.organizations(id) on delete restrict;
drop index public.withdraw_requests_one_pending_r24;
create unique index withdraw_requests_one_pending_r27b on public.withdraw_requests(wallet_id)
  where withdraw_status = 'pending';
create index withdraw_requests_organization_r27b on public.withdraw_requests(organization_id, created_at desc)
  where organization_id is not null;

-- shop_staff is written only through the RPCs below.
drop policy if exists "Authenticated users can read shop staff" on public.shop_staff;
drop policy if exists "Shop owners can add staff" on public.shop_staff;
drop policy if exists "Shop owners can remove staff" on public.shop_staff;
drop policy if exists "Shop owners can update staff" on public.shop_staff;
revoke all on table public.shop_staff from public, anon, authenticated;

create table secondhand.shop_staff_invites (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  invited_by uuid not null references public.profiles(id) on delete restrict,
  can_manage_products boolean not null default false,
  can_manage_orders boolean not null default false,
  can_manage_chat boolean not null default false,
  can_manage_staff boolean not null default false,
  can_manage_shop boolean not null default false,
  invite_status text not null default 'pending'
    check (invite_status in ('pending', 'accepted', 'declined', 'cancelled', 'expired')),
  expires_at timestamptz not null default now() + interval '7 days',
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  constraint shop_staff_invites_some_permission check (
    can_manage_products or can_manage_orders or can_manage_chat or can_manage_staff or can_manage_shop)
);
create unique index shop_staff_invites_pending_r27b on secondhand.shop_staff_invites(shop_id, profile_id)
  where invite_status = 'pending';
create index shop_staff_invites_profile_r27b on secondhand.shop_staff_invites(profile_id, created_at desc);
alter table secondhand.shop_staff_invites enable row level security;
revoke all on table secondhand.shop_staff_invites from public, anon, authenticated;
grant all on table secondhand.shop_staff_invites to service_role;

create table secondhand.shop_staff_events (
  id bigint generated always as identity primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  target_id uuid references public.profiles(id) on delete set null,
  action text not null check (action in ('invited', 'invite_cancelled', 'invite_accepted', 'invite_declined',
                                         'invite_expired', 'updated', 'removed', 'left')),
  detail jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index shop_staff_events_shop_r27b on secondhand.shop_staff_events(shop_id, created_at desc);
alter table secondhand.shop_staff_events enable row level security;
revoke all on table secondhand.shop_staff_events from public, anon, authenticated;
grant all on table secondhand.shop_staff_events to service_role;

-- Permissions: products, orders, chat, staff, shop, finance.
create or replace function secondhand.shop_can_r27(p_shop uuid, p_perm text, p_uid uuid default auth.uid())
returns boolean
language sql
stable security definer
set search_path to ''
as $$
  select p_uid is not null and coalesce((
    select case
      when s.seller_identity_type = 'personal' then
        s.owner_id = p_uid and p_perm in ('products', 'orders', 'chat', 'staff', 'shop', 'finance')
      else
        exists (select 1 from public.profiles p
                 where p.id = p_uid and p.account_status = 'active' and p.deleted_at is null)
        and exists (select 1 from public.kao_id_identities k
                     where k.profile_id = p_uid and k.organization_id is null
                       and k.identity_type = 'personal' and k.status = 'active')
        and (exists (select 1 from public.organization_members om
                      where om.organization_id = s.organization_id and om.profile_id = p_uid
                        and om.status = 'active' and (om.ends_at is null or om.ends_at > now())
                        and case when p_perm = 'finance' then om.role in ('owner', 'finance')
                                 when p_perm in ('products', 'orders', 'chat', 'staff', 'shop')
                                   then om.role in ('owner', 'director', 'authorized_person', 'admin')
                                 else false end)
             or exists (select 1 from public.shop_staff ss
                         where ss.shop_id = s.id and ss.profile_id = p_uid and ss.is_active
                           and case p_perm when 'products' then ss.can_manage_products
                                           when 'orders' then ss.can_manage_orders
                                           when 'chat' then ss.can_manage_chat
                                           when 'staff' then ss.can_manage_staff
                                           when 'shop' then ss.can_manage_shop
                                           else false end))
    end
    from public.shops s
   where s.id = p_shop), false);
$$;

create or replace function secondhand.shop_perms_r27(p_shop uuid, p_uid uuid default auth.uid())
returns jsonb
language sql
stable security definer
set search_path to ''
as $$
  select jsonb_object_agg(x.perm, secondhand.shop_can_r27(p_shop, x.perm, p_uid))
    from unnest(array['products', 'orders', 'chat', 'staff', 'shop', 'finance']) x(perm);
$$;

-- Whether the shop may put items on sale now.
create or replace function secondhand.shop_sell_status_r27(p_shop uuid)
returns jsonb
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  s public.shops;
  v_status jsonb;
  v_kao_id boolean;
  v_bank boolean;
begin
  select * into s from public.shops where id = p_shop;
  if not found then
    return jsonb_build_object('kind', null, 'can_list', false);
  end if;
  if s.seller_identity_type = 'personal' then
    v_status := secondhand.seller_status_r20f(s.owner_id);
    return v_status || jsonb_build_object('kind', 'personal', 'shop_active', s.shop_status = 'active',
                                          'can_list', (v_status->>'can_list')::boolean and s.shop_status = 'active');
  end if;
  v_kao_id := exists (select 1 from public.kao_id_identities k
                       where k.organization_id = s.organization_id and k.profile_id is null
                         and k.identity_type = 'business' and k.status = 'active');
  v_bank := (secondhand.org_payout_bank_r27(s.organization_id)).id is not null;
  return jsonb_build_object(
    'kind', 'business',
    'kao_id', v_kao_id,
    'bank', v_bank,
    'organization_active', exists (select 1 from public.organizations o
                                     where o.id = s.organization_id and o.status = 'active'),
    'shop_active', s.shop_status = 'active',
    'can_list', v_kao_id and v_bank and s.shop_status = 'active'
                and exists (select 1 from public.organizations o where o.id = s.organization_id and o.status = 'active'));
end $$;

create or replace function secondhand.org_payout_bank_r27(p_organization_id uuid)
returns public.bank_accounts
language sql
stable security definer
set search_path to ''
as $$
  select ba.*
    from public.financial_verifications fv
    join public.bank_accounts ba on ba.id = fv.bank_account_id
   where fv.identity_type = 'business' and fv.organization_id = p_organization_id and fv.profile_id is null
     and fv.status = 'approved' and fv.name_match_status = 'matched'
     and ba.organization_id = p_organization_id and ba.profile_id is null
     and ba.is_verified and ba.is_active and ba.deleted_at is null and ba.status = 'verified'
   order by ba.verified_at desc nulls last, ba.created_at desc
   limit 1;
$$;

-- The wallet a shop's sales settle into: the owner's for a personal shop, the organization's for a business shop.
create or replace function secondhand.shop_wallet_r27(p_shop uuid)
returns uuid
language plpgsql
security definer
set search_path to ''
as $$
declare
  s public.shops;
  v_id uuid;
begin
  select * into strict s from public.shops where id = p_shop;
  if s.seller_identity_type = 'personal' then
    insert into public.wallets(profile_id) values (s.owner_id) on conflict (profile_id) do nothing;
    select w.id into strict v_id from public.wallets w where w.profile_id = s.owner_id;
  else
    insert into public.wallets(organization_id) values (s.organization_id) on conflict (organization_id) do nothing;
    select w.id into strict v_id from public.wallets w where w.organization_id = s.organization_id;
  end if;
  return v_id;
end $$;

create or replace function secondhand.wallet_pending_release_r27(p_wallet uuid)
returns numeric
language sql
stable security definer
set search_path to ''
as $$
  select coalesce(sum(o.total_amount), 0)::numeric(12,2)
    from public.orders o
    join secondhand.order_details d on d.order_id = o.id
    join public.escrow_transactions e on e.id = d.escrow_id
   where e.seller_wallet_id = p_wallet and d.payment_method = 'wallet'
     and o.escrow_status = 'holding' and o.order_status in ('paid', 'shipped');
$$;

create or replace function secondhand.pending_release_r24(p_profile_id uuid)
returns numeric
language sql
stable security definer
set search_path to ''
as $$
  select coalesce(secondhand.wallet_pending_release_r27(
           (select w.id from public.wallets w where w.profile_id = p_profile_id)), 0)::numeric(12,2);
$$;

create or replace function secondhand.shop_event_r27(p_shop uuid, p_actor uuid, p_target uuid, p_action text,
                                                     p_detail jsonb default '{}'::jsonb)
returns void
language sql
security definer
set search_path to ''
as $$
  insert into secondhand.shop_staff_events(shop_id, actor_id, target_id, action, detail)
  values (p_shop, p_actor, p_target, p_action, coalesce(p_detail, '{}'::jsonb));
$$;

create or replace function secondhand.staff_perms_json_r27(p_products boolean, p_orders boolean, p_chat boolean,
                                                           p_staff boolean, p_shop boolean)
returns jsonb
language sql
immutable
set search_path to ''
as $$
  select jsonb_build_object('products', coalesce(p_products, false), 'orders', coalesce(p_orders, false),
                            'chat', coalesce(p_chat, false), 'staff', coalesce(p_staff, false),
                            'shop', coalesce(p_shop, false));
$$;

-- A member may only hand out permissions they hold themselves.
create or replace function secondhand.staff_grant_check_r27(p_shop uuid, p_actor uuid, p_perms jsonb)
returns void
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  k text;
begin
  if not exists (select 1 from jsonb_each_text(p_perms) x where x.value = 'true') then
    raise exception 'no_permissions' using errcode = '22023';
  end if;
  for k in select x.key from jsonb_each_text(p_perms) x where x.value = 'true' loop
    if not secondhand.shop_can_r27(p_shop, k, p_actor) then
      raise exception 'permission_not_grantable' using errcode = '42501';
    end if;
  end loop;
end $$;

create or replace function secondhand.business_shop_for_staff_r27(p_shop uuid, p_actor uuid)
returns public.shops
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  s public.shops;
begin
  select * into s from public.shops where id = p_shop;
  if not found or s.seller_identity_type <> 'business' or not secondhand.shop_can_r27(p_shop, 'staff', p_actor) then
    raise exception 'shop_not_found' using errcode = '22023';
  end if;
  return s;
end $$;

create or replace function secondhand.invite_json_r27(i secondhand.shop_staff_invites)
returns jsonb
language sql
stable security definer
set search_path to ''
as $$
  select jsonb_build_object(
    'id', i.id, 'shop_id', i.shop_id,
    'shop_name', (select s.shop_name from public.shops s where s.id = i.shop_id),
    'organization_name', (select o.name from public.shops s join public.organizations o on o.id = s.organization_id
                           where s.id = i.shop_id),
    'member_name', secondhand.member_name_r22(i.profile_id),
    'kao_id', (select k.kao_id from public.kao_id_identities k where k.profile_id = i.profile_id),
    'invited_by_name', secondhand.member_name_r22(i.invited_by),
    'permissions', secondhand.staff_perms_json_r27(i.can_manage_products, i.can_manage_orders, i.can_manage_chat,
                                                   i.can_manage_staff, i.can_manage_shop),
    'status', case when i.invite_status = 'pending' and i.expires_at <= now() then 'expired' else i.invite_status end,
    'expires_at', i.expires_at, 'created_at', i.created_at);
$$;

create or replace function secondhand.invite_shop_staff(p_shop_id uuid, p_kao_id text, p_products boolean,
                                                        p_orders boolean, p_chat boolean, p_staff boolean,
                                                        p_shop boolean)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  s public.shops := secondhand.business_shop_for_staff_r27(p_shop_id, u);
  v_perms jsonb := secondhand.staff_perms_json_r27(p_products, p_orders, p_chat, p_staff, p_shop);
  v_member uuid;
  i secondhand.shop_staff_invites;
begin
  perform secondhand.staff_grant_check_r27(p_shop_id, u, v_perms);
  select k.profile_id into v_member
    from public.kao_id_identities k
    join public.profiles p on p.id = k.profile_id and p.account_status = 'active' and p.deleted_at is null
   where k.kao_id = upper(btrim(coalesce(p_kao_id, ''))) and k.identity_type = 'personal'
     and k.organization_id is null and k.status = 'active';
  if v_member is null then
    raise exception 'member_not_found' using errcode = '22023';
  end if;
  if v_member = u then
    raise exception 'cannot_invite_self' using errcode = '22023';
  end if;
  if exists (select 1 from public.shop_staff ss where ss.shop_id = s.id and ss.profile_id = v_member and ss.is_active) then
    raise exception 'already_staff' using errcode = '23505';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('shop_staff_invite:' || s.id::text, 0));
  update secondhand.shop_staff_invites x set invite_status = 'expired'
   where x.shop_id = s.id and x.invite_status = 'pending' and x.expires_at <= now();
  if exists (select 1 from secondhand.shop_staff_invites x
              where x.shop_id = s.id and x.profile_id = v_member and x.invite_status = 'pending') then
    raise exception 'invite_pending' using errcode = '23505';
  end if;
  if (select count(*) from secondhand.shop_staff_invites x where x.shop_id = s.id and x.invite_status = 'pending') >= 20 then
    raise exception 'too_many_invites' using errcode = '22023';
  end if;

  insert into secondhand.shop_staff_invites(shop_id, profile_id, invited_by, can_manage_products, can_manage_orders,
                                            can_manage_chat, can_manage_staff, can_manage_shop)
  values (s.id, v_member, u, (v_perms->>'products')::boolean, (v_perms->>'orders')::boolean,
          (v_perms->>'chat')::boolean, (v_perms->>'staff')::boolean, (v_perms->>'shop')::boolean)
  returning * into i;
  perform secondhand.shop_event_r27(s.id, u, v_member, 'invited', jsonb_build_object('permissions', v_perms));
  insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
  values (v_member,
          kaoid_private.content_message_r24('secondhand.notice.shop_staff_invite', 'title', null,
                                            'คำเชิญเป็นทีมงานร้านค้า'),
          kaoid_private.content_message_r24('secondhand.notice.shop_staff_invite', 'body',
            jsonb_build_object('shop', s.shop_name, 'name', secondhand.member_name_r22(u)),
            '{name} เชิญคุณเป็นทีมงานร้าน {shop} ตอบรับได้ภายใน 7 วัน'),
          'shop_staff_invite', i.id, '/shops/invites', 'shop_staff_invite:' || i.id);
  return secondhand.invite_json_r27(i);
end $$;

create or replace function secondhand.respond_shop_staff_invite(p_invite_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  i secondhand.shop_staff_invites;
begin
  if p_accept is null then
    raise exception 'invalid_decision' using errcode = '22023';
  end if;
  select * into i from secondhand.shop_staff_invites x where x.id = p_invite_id and x.profile_id = u for update;
  if not found or i.invite_status <> 'pending' then
    raise exception 'invite_not_found' using errcode = '22023';
  end if;
  if i.expires_at <= now() then
    update secondhand.shop_staff_invites set invite_status = 'expired' where id = i.id;
    perform secondhand.shop_event_r27(i.shop_id, u, u, 'invite_expired');
    return jsonb_build_object('id', i.id, 'status', 'expired');
  end if;
  if p_accept and not exists (select 1 from public.kao_id_identities k
                               where k.profile_id = u and k.organization_id is null
                                 and k.identity_type = 'personal' and k.status = 'active') then
    raise exception 'kao_id_required' using errcode = '42501';
  end if;

  update secondhand.shop_staff_invites
     set invite_status = case when p_accept then 'accepted' else 'declined' end, responded_at = now()
   where id = i.id
  returning * into i;
  if p_accept then
    insert into public.shop_staff(shop_id, profile_id, role, can_manage_products, can_manage_orders, can_manage_chat,
                                  can_manage_staff, can_manage_shop, is_active, invited_by)
    values (i.shop_id, u, 'staff', i.can_manage_products, i.can_manage_orders, i.can_manage_chat,
            i.can_manage_staff, i.can_manage_shop, true, i.invited_by)
    on conflict (shop_id, profile_id) do update
      set can_manage_products = excluded.can_manage_products, can_manage_orders = excluded.can_manage_orders,
          can_manage_chat = excluded.can_manage_chat, can_manage_staff = excluded.can_manage_staff,
          can_manage_shop = excluded.can_manage_shop, is_active = true, invited_by = excluded.invited_by,
          updated_at = now();
  end if;
  perform secondhand.shop_event_r27(i.shop_id, u, u, case when p_accept then 'invite_accepted' else 'invite_declined' end);
  return secondhand.invite_json_r27(i);
end $$;

create or replace function secondhand.cancel_shop_staff_invite(p_invite_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  i secondhand.shop_staff_invites;
begin
  select * into i from secondhand.shop_staff_invites x where x.id = p_invite_id for update;
  if not found then
    raise exception 'invite_not_found' using errcode = '22023';
  end if;
  perform secondhand.business_shop_for_staff_r27(i.shop_id, u);
  if i.invite_status <> 'pending' then
    raise exception 'invite_not_found' using errcode = '22023';
  end if;
  update secondhand.shop_staff_invites set invite_status = 'cancelled', responded_at = now() where id = i.id
  returning * into i;
  perform secondhand.shop_event_r27(i.shop_id, u, i.profile_id, 'invite_cancelled');
  return secondhand.invite_json_r27(i);
end $$;

create or replace function secondhand.update_shop_staff(p_shop_id uuid, p_profile_id uuid, p_products boolean,
                                                        p_orders boolean, p_chat boolean, p_staff boolean,
                                                        p_shop boolean)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  s public.shops := secondhand.business_shop_for_staff_r27(p_shop_id, u);
  v_perms jsonb := secondhand.staff_perms_json_r27(p_products, p_orders, p_chat, p_staff, p_shop);
  ss public.shop_staff;
begin
  if p_profile_id = u then
    raise exception 'cannot_edit_self' using errcode = '22023';
  end if;
  perform secondhand.staff_grant_check_r27(p_shop_id, u, v_perms);
  select * into ss from public.shop_staff x where x.shop_id = s.id and x.profile_id = p_profile_id and x.is_active
   for update;
  if not found then
    raise exception 'staff_not_found' using errcode = '22023';
  end if;
  update public.shop_staff
     set can_manage_products = (v_perms->>'products')::boolean, can_manage_orders = (v_perms->>'orders')::boolean,
         can_manage_chat = (v_perms->>'chat')::boolean, can_manage_staff = (v_perms->>'staff')::boolean,
         can_manage_shop = (v_perms->>'shop')::boolean, updated_at = now()
   where id = ss.id;
  perform secondhand.shop_event_r27(s.id, u, p_profile_id, 'updated',
    jsonb_build_object('from', secondhand.staff_perms_json_r27(ss.can_manage_products, ss.can_manage_orders,
                                                                ss.can_manage_chat, ss.can_manage_staff,
                                                                ss.can_manage_shop),
                       'to', v_perms));
  return jsonb_build_object('profile_id', p_profile_id, 'permissions', v_perms);
end $$;

-- Staff with the staff permission remove others; anyone may leave on their own.
create or replace function secondhand.remove_shop_staff(p_shop_id uuid, p_profile_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  s public.shops;
  ss public.shop_staff;
begin
  if p_profile_id = u then
    select * into s from public.shops where id = p_shop_id;
  else
    s := secondhand.business_shop_for_staff_r27(p_shop_id, u);
  end if;
  select * into ss from public.shop_staff x where x.shop_id = p_shop_id and x.profile_id = p_profile_id and x.is_active
   for update;
  if not found then
    raise exception 'staff_not_found' using errcode = '22023';
  end if;
  update public.shop_staff set is_active = false, updated_at = now() where id = ss.id;
  perform secondhand.shop_event_r27(p_shop_id, u, p_profile_id, case when p_profile_id = u then 'left' else 'removed' end);
  if p_profile_id <> u then
    insert into public.notifications(profile_id, title, message, notification_type, target_id, action_url, event_key)
    values (p_profile_id,
            kaoid_private.content_message_r24('secondhand.notice.shop_staff_removed', 'title', null,
                                              'สิ้นสุดการเป็นทีมงานร้านค้า'),
            kaoid_private.content_message_r24('secondhand.notice.shop_staff_removed', 'body',
              jsonb_build_object('shop', s.shop_name), 'คุณไม่ได้เป็นทีมงานร้าน {shop} แล้ว'),
            'shop_staff_removed', p_shop_id, '/shops', 'shop_staff_removed:' || ss.id || ':' || now()::text);
  end if;
  return jsonb_build_object('profile_id', p_profile_id, 'removed', true);
end $$;

create or replace function secondhand.list_shop_staff(p_shop_id uuid)
returns jsonb
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  u uuid := secondhand.order_actor_r22();
  s public.shops := secondhand.business_shop_for_staff_r27(p_shop_id, u);
begin
  return jsonb_build_object(
    'staff', coalesce((
      select jsonb_agg(jsonb_build_object(
               'profile_id', ss.profile_id,
               'member_name', secondhand.member_name_r22(ss.profile_id),
               'kao_id', (select k.kao_id from public.kao_id_identities k where k.profile_id = ss.profile_id),
               'permissions', secondhand.staff_perms_json_r27(ss.can_manage_products, ss.can_manage_orders,
                                                              ss.can_manage_chat, ss.can_manage_staff,
                                                              ss.can_manage_shop),
               'since', ss.created_at) order by ss.created_at)
        from public.shop_staff ss where ss.shop_id = s.id and ss.is_active), '[]'::jsonb),
    'invites', coalesce((
      select jsonb_agg(secondhand.invite_json_r27(i) order by i.created_at desc)
        from secondhand.shop_staff_invites i
       where i.shop_id = s.id and i.invite_status = 'pending' and i.expires_at > now()), '[]'::jsonb),
    'events', coalesce((
      select jsonb_agg(jsonb_build_object(
               'action', e.action, 'actor_name', secondhand.member_name_r22(e.actor_id),
               'target_name', secondhand.member_name_r22(e.target_id), 'detail', e.detail,
               'created_at', e.created_at) order by e.created_at desc, e.id desc)
        from (select * from secondhand.shop_staff_events x where x.shop_id = s.id
               order by x.created_at desc, x.id desc limit 50) e), '[]'::jsonb));
end $$;

-- Shops this member can act for, with what they may do, plus their open invitations.
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
       where i.profile_id = u and i.invite_status = 'pending' and i.expires_at > now()), '[]'::jsonb));
end $$;

revoke all on function secondhand.shop_can_r27(uuid, text, uuid), secondhand.shop_perms_r27(uuid, uuid),
  secondhand.shop_sell_status_r27(uuid), secondhand.org_payout_bank_r27(uuid), secondhand.shop_wallet_r27(uuid),
  secondhand.wallet_pending_release_r27(uuid), secondhand.shop_event_r27(uuid, uuid, uuid, text, jsonb),
  secondhand.staff_perms_json_r27(boolean, boolean, boolean, boolean, boolean),
  secondhand.staff_grant_check_r27(uuid, uuid, jsonb), secondhand.business_shop_for_staff_r27(uuid, uuid),
  secondhand.invite_json_r27(secondhand.shop_staff_invites)
  from public, anon, authenticated;

revoke all on function secondhand.invite_shop_staff(uuid, text, boolean, boolean, boolean, boolean, boolean),
  secondhand.respond_shop_staff_invite(uuid, boolean), secondhand.cancel_shop_staff_invite(uuid),
  secondhand.update_shop_staff(uuid, uuid, boolean, boolean, boolean, boolean, boolean),
  secondhand.remove_shop_staff(uuid, uuid), secondhand.list_shop_staff(uuid), secondhand.my_shops()
  from public, anon, authenticated;
grant execute on function secondhand.invite_shop_staff(uuid, text, boolean, boolean, boolean, boolean, boolean),
  secondhand.respond_shop_staff_invite(uuid, boolean), secondhand.cancel_shop_staff_invite(uuid),
  secondhand.update_shop_staff(uuid, uuid, boolean, boolean, boolean, boolean, boolean),
  secondhand.remove_shop_staff(uuid, uuid), secondhand.list_shop_staff(uuid), secondhand.my_shops()
  to authenticated;
