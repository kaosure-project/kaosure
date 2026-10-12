-- R21e: "ยืนยันตัวตนแล้ว" means every Kao ID step is done: email, phone,
-- bank account and identity (KYC). Before this, a Kao ID identity plus a bank
-- account was enough, so a member whose phone was not confirmed still showed
-- as verified while Kao ID asked them to confirm their phone.

create or replace function secondhand.seller_status_r20f(p_profile_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_email boolean := false;
  v_phone boolean := false;
  v_bank boolean := false;
  v_kao_id boolean := false;
  v_verified boolean;
  v_can_list boolean;
  v_limit numeric(12,2);
begin
  if p_profile_id is not null then
    select u.email_confirmed_at is not null, u.phone_confirmed_at is not null
      into v_email, v_phone
      from auth.users u where u.id = p_profile_id;
    v_bank := exists (
      select 1
        from public.financial_verifications fv
        join public.bank_accounts ba on ba.id = fv.bank_account_id
       where fv.identity_type = 'personal' and fv.profile_id = p_profile_id and fv.organization_id is null
         and fv.status = 'approved' and fv.name_match_status = 'matched'
         and ba.profile_id = p_profile_id and ba.organization_id is null
         and ba.is_verified and ba.is_active and ba.deleted_at is null and ba.status = 'verified'
         and kaoid_private.bank_holder_name_ok_r20g(p_profile_id, ba.account_name));
    v_kao_id := exists (
      select 1 from public.kao_id_identities k
       where k.profile_id = p_profile_id and k.organization_id is null
         and k.identity_type = 'personal' and k.status = 'active');
  end if;
  v_email := coalesce(v_email, false);
  v_phone := coalesce(v_phone, false);
  v_verified := v_email and v_phone and v_bank and v_kao_id;
  v_can_list := v_email and v_phone and v_bank;
  if not v_verified then
    select s.unverified_max_price into v_limit from secondhand.market_settings s where s.id;
  end if;
  return jsonb_build_object(
    'email', v_email,
    'phone', v_phone,
    'bank', v_bank,
    'kao_id', v_kao_id,
    'verified', v_verified,
    'can_list', v_can_list,
    'price_limit', v_limit
  );
end $$;

revoke all on function secondhand.seller_status_r20f(uuid) from public, anon, authenticated;

-- The public seller card uses the same rule as the member's own page.
create or replace function secondhand.seller_card_r20d(p_shop_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'shop_id', s.id,
    'shop_name', s.shop_name,
    'shop_slug', s.shop_slug,
    'shop_description', s.description,
    'province', s.province,
    'joined_at', s.created_at,
    'display_name', coalesce(nullif(btrim(m.display_name), ''), s.shop_name),
    'avatar_url', m.avatar_url,
    'bio', m.bio,
    'rating', r.seller_rating,
    'review_count', coalesce(r.seller_review_count, 0),
    'good_count', coalesce(r.seller_good_count, 0),
    'bad_count', coalesce(r.seller_bad_count, 0),
    'is_verified', s.seller_identity_type = 'personal'
                   and coalesce((secondhand.seller_status_r20f(s.owner_id)->>'verified')::boolean, false),
    'follower_count', (select count(*) from public.followers f where f.shop_id = s.id),
    'sold_count', (select count(*) from public.orders o where o.shop_id = s.id and o.order_status = 'completed'),
    'on_sale_count', (select count(*) from public.products p
                       join public.categories c on c.id = p.category_id and c.is_active
                      where p.shop_id = s.id and p.status = 'active' and p.is_active and p.stock > 0)
  )
  from public.shops s
  left join secondhand.member_profiles m on m.profile_id = s.owner_id
  left join secondhand.member_ratings r on r.profile_id = s.owner_id
  where s.id = p_shop_id
$$;

revoke all on function secondhand.seller_card_r20d(uuid) from public, anon, authenticated;
