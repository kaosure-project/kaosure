-- R21b: address book and blocked members.
--   * Deleting the default address hands the default to the most recently
--     updated address of the same type.
--   * public.user_blocks is closed to clients: the old policies let any
--     signed-in member read, add or remove every block. Members now only see
--     their own blocks, and every change goes through the RPCs below.
--   * A block works both ways: neither member can make price offers or ask
--     questions on the other's listings, and open offers between them end.

-- ---------------------------------------------------------------------------
-- Address book
-- ---------------------------------------------------------------------------
create or replace function secondhand.shipping_address_after_delete_r21b() returns trigger
language plpgsql set search_path = '' as $$
begin
  if old.is_default then
    update secondhand.shipping_addresses a set is_default = true
     where a.id = (select b.id from secondhand.shipping_addresses b
                    where b.profile_id = old.profile_id and b.address_type = old.address_type
                    order by b.updated_at desc, b.created_at desc
                    limit 1);
  end if;
  return null;
end $$;

revoke all on function secondhand.shipping_address_after_delete_r21b() from public, anon, authenticated;

create trigger shipping_address_after_delete_r21b
after delete on secondhand.shipping_addresses
for each row execute function secondhand.shipping_address_after_delete_r21b();

-- ---------------------------------------------------------------------------
-- user_blocks: own rows only, writes through RPCs
-- ---------------------------------------------------------------------------
drop policy if exists "Users can create blocks" on public.user_blocks;
drop policy if exists "Users can delete their blocks" on public.user_blocks;
drop policy if exists "Users can read blocks" on public.user_blocks;
drop policy if exists "Admins can update blocks" on public.user_blocks;

alter table public.user_blocks enable row level security;
revoke all on table public.user_blocks from public, anon, authenticated;

create policy user_blocks_own_read_r21b on public.user_blocks
  for select to authenticated
  using (blocker_profile_id = (select auth.uid()));

update public.user_blocks set is_active = true where is_active is null;
alter table public.user_blocks
  alter column is_active set not null,
  add constraint user_blocks_reason_r21b check (reason is null or char_length(reason) <= 200);

create or replace function secondhand.blocked_between_r21b(p_a uuid, p_b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_blocks b
     where ((b.blocker_profile_id = p_a and b.blocked_profile_id = p_b)
         or (b.blocker_profile_id = p_b and b.blocked_profile_id = p_a))
       and b.is_active
       and (b.expires_at is null or b.expires_at > now()))
$$;

revoke all on function secondhand.blocked_between_r21b(uuid, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Blocks stop new offers and questions
-- ---------------------------------------------------------------------------
create or replace function secondhand.refuse_blocked_r21b() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_table_name = 'price_offers' then
    if secondhand.blocked_between_r21b(new.buyer_id, new.seller_id) then
      raise exception 'member_blocked' using errcode = '42501';
    end if;
  elsif secondhand.blocked_between_r21b(new.asker_id, secondhand.listing_owner_r20d(new.product_id)) then
    raise exception 'member_blocked' using errcode = '42501';
  end if;
  return new;
end $$;

revoke all on function secondhand.refuse_blocked_r21b() from public, anon, authenticated;

create trigger price_offers_block_r21b
before insert on secondhand.price_offers
for each row execute function secondhand.refuse_blocked_r21b();

create trigger listing_questions_block_r21b
before insert on secondhand.listing_questions
for each row execute function secondhand.refuse_blocked_r21b();

alter table secondhand.price_offers
  drop constraint price_offers_cancel_reason_check,
  add constraint price_offers_cancel_reason_check
    check (cancel_reason in ('price_changed', 'listing_unavailable', 'listing_sold', 'blocked'));

-- ---------------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------------

-- Blocks the owner of a shop, or the buyer behind an offer on one of the
-- caller's listings. Members never handle each other's profile ids.
create or replace function secondhand.block_member(
  p_shop_id uuid default null,
  p_offer_id uuid default null,
  p_reason text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
  v_target uuid;
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
  v_id uuid;
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  if (p_shop_id is null) = (p_offer_id is null) then
    raise exception 'Choose one member to block';
  end if;

  if p_shop_id is not null then
    select s.owner_id into v_target from public.shops s where s.id = p_shop_id;
  else
    select o.buyer_id into v_target from secondhand.price_offers o where o.id = p_offer_id and o.seller_id = u;
  end if;
  if v_target is null then
    raise exception 'Member not found';
  end if;
  if v_target = u then
    raise exception 'You cannot block yourself';
  end if;
  if char_length(v_reason) > 200 then
    raise exception 'Reason must be at most 200 characters';
  end if;
  if not exists (select 1 from public.user_blocks b where b.blocker_profile_id = u and b.blocked_profile_id = v_target)
     and (select count(*) from public.user_blocks b where b.blocker_profile_id = u) >= 500 then
    raise exception 'block_limit_reached';
  end if;

  insert into public.user_blocks (blocker_profile_id, blocked_profile_id, reason)
  values (u, v_target, v_reason)
  on conflict (blocker_profile_id, blocked_profile_id)
  do update set is_active = true, expires_at = null, reason = excluded.reason
  returning id into v_id;

  update secondhand.price_offers o
     set status = 'cancelled', cancel_reason = 'blocked', updated_at = now()
   where o.status in ('pending', 'accepted')
     and ((o.buyer_id = u and o.seller_id = v_target) or (o.buyer_id = v_target and o.seller_id = u));

  return jsonb_build_object('id', v_id);
end $$;

create or replace function secondhand.unblock_member(p_block_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_unavailable' using errcode = '42501';
  end if;
  delete from public.user_blocks b where b.id = p_block_id and b.blocker_profile_id = u;
  if not found then
    raise exception 'Block not found';
  end if;
  return jsonb_build_object('id', p_block_id);
end $$;

-- The caller's active blocks, newest first. Names come from the market
-- profile only, like everywhere else members see each other.
create or replace function secondhand.list_blocked_members()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  u uuid := auth.uid();
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not kaoid_private.data_access_r10d() then
    raise exception 'Account unavailable' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', b.id,
             'display_name', coalesce(nullif(btrim(m.display_name), ''), 'สมาชิก KaoSure'),
             'avatar_url', m.avatar_url,
             'shop_id', (select s.id from public.shops s
                          where s.owner_id = b.blocked_profile_id and s.seller_identity_type = 'personal'
                          order by s.created_at limit 1),
             'reason', b.reason,
             'created_at', b.created_at)
           order by b.created_at desc)
      from public.user_blocks b
      left join secondhand.member_profiles m on m.profile_id = b.blocked_profile_id
     where b.blocker_profile_id = u and b.is_active
       and (b.expires_at is null or b.expires_at > now())), '[]'::jsonb);
end $$;

revoke all on function secondhand.block_member(uuid, uuid, text) from public, anon, authenticated;
revoke all on function secondhand.unblock_member(uuid) from public, anon, authenticated;
revoke all on function secondhand.list_blocked_members() from public, anon, authenticated;
grant execute on function secondhand.block_member(uuid, uuid, text) to authenticated;
grant execute on function secondhand.unblock_member(uuid) to authenticated;
grant execute on function secondhand.list_blocked_members() to authenticated;

update kaoid_private.app_clients_r18
   set allowed_rpcs = array(select distinct r from unnest(allowed_rpcs || array[
         'secondhand.block_member', 'secondhand.unblock_member', 'secondhand.list_blocked_members']) r order by 1),
       updated_at = now()
 where app_code = 'secondhand_web';
