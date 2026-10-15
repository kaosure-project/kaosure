-- R48: Custom Access Token hook. Every Kao ID access token carries a small `kao`
-- claim so sub-apps on other Supabase projects (Secondhand) can gate access without
-- reading Kao ID personal data. Money operations must still ask Kao ID live.
--
-- kao.v        claim format version
-- kao.account  profiles.account_status ('active', 'closed', 'suspended', 'banned',
--              'temporarily_locked') or 'unavailable'
-- kao.email    email confirmed
-- kao.phone    phone confirmed
-- kao.kyc      kyc_status_r18: 'approved', 'pending', 'rejected', 'expired', 'not_submitted'
-- kao.bank     personal bank account financially verified
-- kao.kao_id   personal Kao ID issued and active

create or replace function kaoid_private.custom_access_token_hook_r48(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user uuid := nullif(event->>'user_id', '')::uuid;
  v_status text;
  v_deleted timestamptz;
  v_email boolean;
  v_phone boolean;
begin
  if v_user is null then
    return event;
  end if;

  begin
    select p.account_status, p.deleted_at into v_status, v_deleted
      from public.profiles p where p.id = v_user;
    select u.email_confirmed_at is not null, u.phone_confirmed_at is not null
      into v_email, v_phone
      from auth.users u where u.id = v_user;

    return jsonb_set(event, '{claims,kao}', jsonb_build_object(
      'v', 1,
      'account', case
        when v_status is null or v_deleted is not null then 'unavailable'
        when v_status in ('active', 'closed', 'suspended', 'banned', 'temporarily_locked') then v_status
        else 'unavailable' end,
      'email', coalesce(v_email, false),
      'phone', coalesce(v_phone, false),
      'kyc', kaoid_private.kyc_status_r18(v_user),
      'bank', coalesce(public.is_identity_financially_verified('personal', v_user, null), false),
      'kao_id', exists(select 1 from public.kao_id_identities k
                        where k.profile_id = v_user and k.identity_type = 'personal'
                          and k.status = 'active')));
  exception when others then
    -- A claims failure must never block sign-in; sub-apps treat a missing `kao` claim as not ready.
    return event;
  end;
end
$$;

revoke all on function kaoid_private.custom_access_token_hook_r48(jsonb) from public, anon, authenticated;
grant usage on schema kaoid_private to supabase_auth_admin;
grant execute on function kaoid_private.custom_access_token_hook_r48(jsonb) to supabase_auth_admin;
