-- SSO R18 checks. Appended after the migration inside one transaction that never commits.
do $$
declare
  owner_user uuid := '9044e32e-24e7-49e2-9aaf-500c48ecce7e';
  other_user uuid := '3bd1dcd3-6ab3-4af5-a83f-2c9883438629';
  owner_session uuid := gen_random_uuid();
  other_session uuid := gen_random_uuid();
  cid uuid := gen_random_uuid();
  stranger uuid := gen_random_uuid();
  report text := '';
  j jsonb;
  step text;
begin
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (owner_session, owner_user, now(), now(), 'aal1'), (other_session, other_user, now(), now(), 'aal1');
  insert into auth.oauth_clients(id, registration_type, redirect_uris, grant_types, client_name, client_type,
    token_endpoint_auth_method, created_at, updated_at)
  values (cid, 'manual', 'http://localhost:5000/auth/callback', 'authorization_code,refresh_token',
    'Secondhand E2E', 'public', 'none', now(), now());

  foreach step in array array['owner_save', 'other_save', 'never_rpc', 'owner_list', 'app_claims',
      'guard_allowed_rpc', 'guard_denied_rpc', 'guard_allowed_table', 'guard_denied_table', 'guard_first_party',
      'app_directory', 'app_list_blocked', 'storage_app_kyc', 'storage_app_avatar', 'storage_app_market',
      'storage_first_party', 'unknown_client', 'suspended', 'legacy_table'] loop
    begin
      report := report || step || ': ';
      -- Default identity: owner on a first-party Kao ID session.
      perform set_config('request.jwt.claims', json_build_object('sub', owner_user, 'role', 'authenticated',
        'session_id', owner_session, 'aal', 'aal1', 'is_anonymous', false)::text, true);
      if step in ('app_claims', 'guard_allowed_rpc', 'guard_denied_rpc', 'guard_allowed_table',
                  'guard_denied_table', 'app_directory', 'app_list_blocked', 'suspended',
                  'storage_app_kyc', 'storage_app_avatar', 'storage_app_market') then
        perform set_config('request.jwt.claims', json_build_object('sub', owner_user, 'role', 'authenticated',
          'session_id', owner_session, 'aal', 'aal1', 'is_anonymous', false, 'client_id', cid)::text, true);
      elsif step = 'unknown_client' then
        perform set_config('request.jwt.claims', json_build_object('sub', owner_user, 'role', 'authenticated',
          'session_id', owner_session, 'aal', 'aal1', 'is_anonymous', false, 'client_id', stranger)::text, true);
      elsif step = 'other_save' then
        perform set_config('request.jwt.claims', json_build_object('sub', other_user, 'role', 'authenticated',
          'session_id', other_session, 'aal', 'aal1', 'is_anonymous', false)::text, true);
      end if;
      if step = 'suspended' then
        update kaoid_private.app_clients_r18 set status = 'suspended' where app_code = 'secondhand_web';
      end if;
      perform set_config('role', 'authenticated', true);

      case step
        when 'owner_save' then
          perform public.app_client_save_r18('secondhand_web', cid, 'KaoSure Secondhand', true,
            array['profile', 'verification', 'business'], array['get_my_seller_readiness', 'create_personal_shop'],
            array['products', 'shops', 'categories']);
          report := report || 'saved';
        when 'other_save' then
          perform public.app_client_save_r18('auction_web', cid, 'Auction', false, '{}', '{}', '{}');
          report := report || 'UNEXPECTED_OK';
        when 'never_rpc' then
          perform public.app_client_save_r18('secondhand_web', cid, 'KaoSure Secondhand', true,
            array['profile'], array['kyc_review_queue_r7c'], '{}');
          report := report || 'UNEXPECTED_OK';
        when 'owner_list' then
          j := public.app_clients_list_r18();
          report := report || 'count=' || jsonb_array_length(j) || ', registered=' || (j->0->>'oauth_registered')
            || ', oauthName=' || (j->0->>'oauth_name') || ', tables=' || (j->0->'tables')::text;
        when 'app_claims' then
          j := public.kao_id_claims_r18();
          report := report || 'app=' || (j->>'app') || ', state=' || (j->>'account_state')
            || ', kaoId=' || coalesce(j->>'kao_id', 'null') || ', keys=' || (select string_agg(k, ',' order by k) from jsonb_object_keys(j) k)
            || ', verification=' || coalesce((j->'verification')::text, 'null');
        when 'guard_allowed_rpc' then
          perform set_config('request.path', '/rpc/get_my_seller_readiness', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'allowed';
        when 'guard_denied_rpc' then
          perform set_config('request.path', '/rpc/kyc_review_queue_r7c', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'UNEXPECTED_OK';
        when 'guard_allowed_table' then
          perform set_config('request.path', '/products', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'allowed';
        when 'guard_denied_table' then
          perform set_config('request.path', '/identity_documents', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'UNEXPECTED_OK';
        when 'guard_first_party' then
          perform set_config('request.path', '/identity_documents', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'allowed';
        when 'app_directory' then
          j := public.app_directory_r18();
          report := report || 'items=' || jsonb_array_length(j);
        when 'app_list_blocked' then
          j := public.app_clients_list_r18();
          report := report || 'UNEXPECTED_OK';
        when 'storage_app_kyc' then
          insert into storage.objects(bucket_id, name, owner_id)
          values ('identity-documents', owner_user::text || '/sso-e2e.jpg', owner_user::text);
          report := report || 'UNEXPECTED_OK';
        when 'storage_app_avatar' then
          insert into storage.objects(bucket_id, name, owner_id)
          values ('avatars', owner_user::text || '/sso-e2e.jpg', owner_user::text);
          report := report || 'UNEXPECTED_OK';
        when 'storage_app_market' then
          insert into storage.objects(bucket_id, name, owner_id)
          values ('marketplace-product-images', owner_user::text || '/sso-e2e.jpg', owner_user::text);
          report := report || 'inserted';
        when 'storage_first_party' then
          insert into storage.objects(bucket_id, name, owner_id)
          values ('identity-documents', owner_user::text || '/sso-e2e-first.jpg', owner_user::text);
          report := report || 'inserted';
        when 'unknown_client' then
          perform set_config('request.path', '/products', true);
          perform kaoid_private.pre_request_r10d();
          report := report || 'UNEXPECTED_OK';
        when 'suspended' then
          j := public.kao_id_claims_r18();
          report := report || 'UNEXPECTED_OK';
        when 'legacy_table' then
          perform 1 from public.oauth_clients limit 1;
          report := report || 'UNEXPECTED_OK';
      end case;
      perform set_config('role', 'postgres', true);
      if step = 'app_claims' then
        report := report || ', accessRows=' || (select count(*) from kaoid_private.app_access_r18 where profile_id = owner_user);
      end if;
      if step = 'owner_save' then
        report := report || ', log=' || (select count(*) from public.activity_logs where action = 'sso.app.save');
      end if;
      report := report || ' | ';
    exception when others then
      perform set_config('role', 'postgres', true);
      report := report || 'ERR ' || sqlerrm || ' | ';
    end;
  end loop;
  raise exception 'E2E_REPORT %', report;
end $$;
