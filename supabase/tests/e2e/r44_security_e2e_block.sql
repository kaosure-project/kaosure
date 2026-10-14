-- R44 checks. Appended after the migration inside one transaction that never commits.
do $$
declare
  shop uuid := (select id from public.shops where shop_status = 'active' order by created_at limit 1);
  member uuid := (select owner_id from public.shops where shop_status = 'active' order by created_at limit 1);
  member_session uuid := gen_random_uuid();
  report text := '';
  j jsonb;
  b boolean;
  t text;
  step text;
begin
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (member_session, member, now(), now(), 'aal1');

  foreach step in array array['grants', 'search_path', 'member_seller_check', 'member_identity_check',
      'guest_seller_check', 'definer_chain', 'init_verification', 'owner_still_runs', 'guest_profile_face',
      'guest_seeded_at', 'member_seeded_at', 'member_profile_patch', 'guest_shop_page', 'avatars_bucket',
      'topup_rls'] loop
    begin
      report := report || step || ': ';
      perform set_config('request.jwt.claims', json_build_object('sub', member, 'role', 'authenticated',
        'session_id', member_session, 'aal', 'aal1', 'is_anonymous', false)::text, true);

      case step
        when 'grants' then
          report := report || 'auth_identity=' || has_function_privilege('authenticated',
              'public.is_identity_financially_verified(text,uuid,uuid)', 'execute')
            || ' auth_seller=' || has_function_privilege('authenticated',
              'public.is_seller_financially_verified(uuid)', 'execute')
            || ' anon_seller=' || has_function_privilege('anon', 'public.is_seller_financially_verified(uuid)', 'execute')
            || ' auth_init=' || has_function_privilege('authenticated', 'public.initialize_verification(uuid)', 'execute');
        when 'search_path' then
          report := report || (select string_agg(p.proname || '=' || array_to_string(p.proconfig, ','), ' ' order by p.proname)
            from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname in ('is_identity_financially_verified',
              'is_seller_financially_verified', 'initialize_verification'));
        when 'member_seller_check' then
          perform set_config('role', 'authenticated', true);
          b := public.is_seller_financially_verified(gen_random_uuid());
          report := report || 'UNEXPECTED_OK';
        when 'member_identity_check' then
          perform set_config('role', 'authenticated', true);
          b := public.is_identity_financially_verified('personal', gen_random_uuid(), null);
          report := report || 'UNEXPECTED_OK';
        when 'guest_seller_check' then
          perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
          perform set_config('role', 'anon', true);
          b := public.is_seller_financially_verified(gen_random_uuid());
          report := report || 'UNEXPECTED_OK';
        when 'definer_chain' then
          perform set_config('role', 'authenticated', true);
          j := to_jsonb(public.get_my_seller_readiness());
          report := report || 'readiness_ok keys=' || (select count(*) from jsonb_object_keys(
            case jsonb_typeof(j) when 'object' then j else jsonb_build_object('value', j) end));
        when 'init_verification' then
          perform set_config('role', 'authenticated', true);
          report := report || 'id_returned=' || (public.initialize_verification(member) is not null);
        when 'owner_still_runs' then
          report := report || 'identity=' || public.is_identity_financially_verified('personal', member, null)
            || ' seller=' || public.is_seller_financially_verified(member)
            || ' bad_type=' || public.is_identity_financially_verified('nope', member, null);
        when 'guest_profile_face' then
          perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
          perform set_config('role', 'anon', true);
          select display_name into t from secondhand.member_profiles where profile_id = member;
          report := report || 'name_read=' || (t is not null)
            || ' rows=' || (select count(*) from secondhand.member_profiles where profile_id = member);
        when 'guest_seeded_at' then
          perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
          perform set_config('role', 'anon', true);
          perform seeded_from_kao_id_at from secondhand.member_profiles limit 1;
          report := report || 'UNEXPECTED_OK';
        when 'member_seeded_at' then
          perform set_config('role', 'authenticated', true);
          perform seeded_from_kao_id_at from secondhand.member_profiles where profile_id = member;
          report := report || 'UNEXPECTED_OK';
        when 'member_profile_patch' then
          perform set_config('role', 'authenticated', true);
          update secondhand.member_profiles set bio = bio where profile_id = member
            returning to_jsonb(row(profile_id, display_name, avatar_url, bio)) into j;
          report := report || 'patched=' || (j is not null);
        when 'guest_shop_page' then
          perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
          perform set_config('role', 'anon', true);
          j := secondhand.get_shop_profile(shop);
          report := report || 'profile=' || (j is not null)
            || ' items=' || (secondhand.list_shop_items(shop, 'selling', 'newest', null, 10) is not null);
        when 'avatars_bucket' then
          report := report || (select file_size_limit || ' ' || allowed_mime_types::text
            from storage.buckets where id = 'avatars');
        when 'topup_rls' then
          report := report || 'rls=' || (select relrowsecurity from pg_class
              where oid = 'kaoid_private.topup_settings_r28'::regclass)
            || ' owner_rows=' || (select count(*) from kaoid_private.topup_settings_r28);
      end case;
      perform set_config('role', 'postgres', true);
      report := report || ' | ';
    exception when others then
      perform set_config('role', 'postgres', true);
      report := report || 'ERR ' || sqlstate || ' ' || sqlerrm || ' | ';
    end;
  end loop;
  raise exception 'E2E_REPORT %', report;
end $$;
