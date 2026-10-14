-- R19a checks. Appended after the migration inside one transaction that never commits.
do $$
declare
  owner_user uuid := '9044e32e-24e7-49e2-9aaf-500c48ecce7e';
  owner_session uuid := gen_random_uuid();
  cid uuid := 'f56cdf5a-347a-4847-ad0d-f05b580b007c';
  report text := '';
  j jsonb;
  n int;
  step text;
  app_steps text[] := array['get_products', 'get_profiles', 'patch_profiles', 'post_profiles', 'post_favorites',
    'delete_favorites', 'patch_orders', 'post_orders', 'other_schema', 'private_schema', 'rpc_allowed',
    'rpc_claims', 'rpc_wrong_schema', 'rpc_get_allowed', 'rls_app_profile', 'rls_app_favorites_ok'];
begin
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (owner_session, owner_user, now(), now(), 'aal1');

  report := 'migrated=' || (select allowed_tables::text || ' rpcs=' || allowed_rpcs::text
    from kaoid_private.app_clients_r18 where app_code = 'secondhand_web') || ' | ';

  foreach step in array app_steps || array['first_patch_profiles', 'rls_first_profile', 'save_qualified',
      'list_after_save', 'save_bad_schema', 'save_never', 'save_rpc_write', 'save_private', 'money'] loop
    begin
      report := report || step || ': ';
      perform set_config('request.jwt.claims', json_build_object('sub', owner_user, 'role', 'authenticated',
        'session_id', owner_session, 'aal', 'aal1', 'is_anonymous', false)::text, true);
      if step = any(app_steps) then
        perform set_config('request.jwt.claims', json_build_object('sub', owner_user, 'role', 'authenticated',
          'session_id', owner_session, 'aal', 'aal1', 'is_anonymous', false, 'client_id', cid)::text, true);
      end if;
      perform set_config('request.headers', '{}', true);
      perform set_config('request.method', 'GET', true);
      perform set_config('role', 'authenticated', true);

      case step
        when 'get_products' then
          perform set_config('request.path', '/products', true);
          perform set_config('request.headers', '{"accept-profile":"public"}', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'allowed';
        when 'get_profiles' then
          perform set_config('request.path', '/profiles', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'allowed';
        when 'patch_profiles' then
          perform set_config('request.path', '/profiles', true);
          perform set_config('request.method', 'PATCH', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'UNEXPECTED_OK';
        when 'post_profiles' then
          perform set_config('request.path', '/profiles', true);
          perform set_config('request.method', 'POST', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'UNEXPECTED_OK';
        when 'post_favorites' then
          perform set_config('request.path', '/favorites', true);
          perform set_config('request.method', 'POST', true);
          perform set_config('request.headers', '{"content-profile":"public"}', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'allowed';
        when 'delete_favorites' then
          perform set_config('request.path', '/favorites', true);
          perform set_config('request.method', 'DELETE', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'allowed';
        when 'patch_orders' then
          perform set_config('request.path', '/orders', true);
          perform set_config('request.method', 'PATCH', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'UNEXPECTED_OK';
        when 'post_orders' then
          perform set_config('request.path', '/orders', true);
          perform set_config('request.method', 'POST', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'UNEXPECTED_OK';
        when 'other_schema' then
          perform set_config('request.path', '/products', true);
          perform set_config('request.headers', '{"accept-profile":"secondhand"}', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'UNEXPECTED_OK';
        when 'private_schema' then
          perform set_config('request.path', '/app_clients_r18', true);
          perform set_config('request.headers', '{"accept-profile":"kaoid_private"}', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'UNEXPECTED_OK';
        when 'rpc_allowed' then
          perform set_config('request.path', '/rpc/create_personal_shop', true);
          perform set_config('request.method', 'POST', true);
          perform set_config('request.headers', '{"content-profile":"public"}', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'allowed';
        when 'rpc_claims' then
          perform set_config('request.path', '/rpc/kao_id_claims_r18', true);
          perform set_config('request.method', 'POST', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'allowed';
        when 'rpc_wrong_schema' then
          perform set_config('request.path', '/rpc/create_personal_shop', true);
          perform set_config('request.method', 'POST', true);
          perform set_config('request.headers', '{"content-profile":"secondhand"}', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'UNEXPECTED_OK';
        when 'rpc_get_allowed' then
          perform set_config('request.path', '/rpc/get_my_seller_readiness', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'allowed';
        when 'rls_app_profile' then
          update public.profiles set bio = bio where id = owner_user;
          get diagnostics n = row_count;
          report := report || 'rows=' || n;
        when 'rls_app_favorites_ok' then
          perform 1 from public.favorites where profile_id = owner_user;
          report := report || 'readable';
        when 'first_patch_profiles' then
          perform set_config('request.path', '/profiles', true);
          perform set_config('request.method', 'PATCH', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'allowed';
        when 'rls_first_profile' then
          update public.profiles set bio = bio where id = owner_user;
          get diagnostics n = row_count;
          report := report || 'rows=' || n;
        when 'save_qualified' then
          perform public.app_client_save_r18('secondhand_web', cid, 'KaoSure Secondhand', true,
            array['profile', 'verification', 'business'], array['get_my_seller_readiness', 'public.create_personal_shop'],
            array['products', 'public.favorites:write', 'Public.Shops']);
          report := report || 'saved';
        when 'list_after_save' then
          j := public.app_clients_list_r18();
          report := report || 'tables=' || (j->0->'tables')::text || ' rpcs=' || (j->0->'rpcs')::text;
        when 'save_bad_schema' then
          perform public.app_client_save_r18('secondhand_web', cid, 'KaoSure Secondhand', true,
            array['profile'], '{}', array['auth.users']);
          report := report || 'UNEXPECTED_OK';
        when 'save_never' then
          perform public.app_client_save_r18('secondhand_web', cid, 'KaoSure Secondhand', true,
            array['profile'], '{}', array['public.identity_documents']);
          report := report || 'UNEXPECTED_OK';
        when 'save_rpc_write' then
          perform public.app_client_save_r18('secondhand_web', cid, 'KaoSure Secondhand', true,
            array['profile'], array['public.create_personal_shop:write'], '{}');
          report := report || 'UNEXPECTED_OK';
        when 'save_private' then
          perform public.app_client_save_r18('secondhand_web', cid, 'KaoSure Secondhand', true,
            array['profile'], '{}', array['kaoid_private.app_clients_r18']);
          report := report || 'UNEXPECTED_OK';
        when 'money' then
          perform set_config('role', 'postgres', true);
          report := report || 'openPolicies=' || (select count(*) from pg_policies where schemaname = 'public'
              and policyname in ('System can create escrow', 'System can update escrow', 'Users can create orders',
                                 'Users can update own orders', 'Users can create withdraw'))
            || ' authWrites=' || (select count(*) from information_schema.table_privileges
              where table_schema = 'public' and grantee in ('anon', 'authenticated')
                and privilege_type in ('INSERT', 'UPDATE', 'DELETE')
                and table_name in ('orders', 'escrow_transactions', 'payment_transactions', 'withdraw_requests',
                                   'wallets', 'wallet_transactions', 'payment_methods'));
      end case;
      perform set_config('role', 'postgres', true);
      report := report || ' | ';
    exception when others then
      perform set_config('role', 'postgres', true);
      report := report || 'ERR ' || sqlerrm || ' | ';
    end;
  end loop;
  raise exception 'E2E_REPORT %', report;
end $$;
