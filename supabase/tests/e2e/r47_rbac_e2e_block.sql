-- R47 checks. Appended after the migration inside one transaction that never commits.
-- own = company owner (MFA session), kyc = the real reviewer moved from kyc_officer to kaoid_admin,
-- tgt = KYC-verified member, tgt2 = member without KYC, apr = second approver (legal_security_admin, MFA session).
do $$
declare
  own uuid := gen_random_uuid();
  tgt uuid := gen_random_uuid();
  tgt2 uuid := gen_random_uuid();
  apr uuid := gen_random_uuid();
  kyc uuid := (select a.profile_id from public.admin_assignments a join public.admin_roles r on r.id = a.role_id
                where r.code = 'kaoid_admin' and a.is_active order by a.created_at limit 1);
  own_s uuid := gen_random_uuid();
  tgt_s uuid := gen_random_uuid();
  tgt2_s uuid := gen_random_uuid();
  apr_s uuid := gen_random_uuid();
  kyc_s uuid := gen_random_uuid();
  own_f uuid := gen_random_uuid();
  apr_f uuid := gen_random_uuid();
  kyc_f uuid := gen_random_uuid();
  g1 uuid; g2 uuid; g3 uuid; g4 uuid; g5 uuid;
  j jsonb;
  b boolean;
  who uuid;
  sess uuid;
  aal text;
  report text := '';
  line text;
  step text;
  steps text[] := array['pg_setup', 'kyc_aal1', 'pg_kyc_mfa', 'kyc_aal2', 'own_perm', 'own_snapshot', 'own_role_bad',
    'own_role_create', 'own_role_perm', 'own_role_owner_only', 'own_role_system', 'own_role_legacy', 'own_grant_nokyc',
    'own_grant_kaoid_nokyc', 'own_grant_cool', 'own_grant_dup', 'tgt_wait', 'own_cancel', 'own_cancel_again',
    'pg_fast_forward', 'own_settle', 'tgt_active', 'own_dangerous_in_use', 'own_safe_in_use', 'pg_approver',
    'own_grant_two', 'own_decide_self', 'apr_aal1', 'apr_queue', 'apr_reject_short', 'apr_approve', 'tgt_marketing',
    'own_grant_two2', 'apr_reject', 'own_grant_two3', 'pg_expire', 'own_expired', 'tgt_denied', 'anon_denied',
    'own_revoke', 'pg_recipients', 'pg_privs', 'pg_logs'];
begin
  insert into auth.users(id, instance_id, aud, role, email, phone, raw_app_meta_data, raw_user_meta_data,
                         created_at, updated_at, is_anonymous, email_confirmed_at, phone_confirmed_at)
  select x.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'e2e-r47-' || x.tag || '-' || left(x.id::text, 8) || '@example.invalid',
         '6684' || lpad((random() * 1e7)::int::text, 7, '0'),
         '{"provider":"email","providers":["email"]}', jsonb_build_object('display_name', x.name),
         now(), now(), false, now(), now()
    from (values (own, 'own', 'R47 Owner'), (tgt, 'tgt', 'R47 Staff'), (tgt2, 'tgt2', 'R47 No KYC'),
                 (apr, 'apr', 'R47 Approver')) x(id, tag, name);
  insert into auth.mfa_factors(id, user_id, friendly_name, factor_type, status, created_at, updated_at)
  values (own_f, own, 'e2e', 'totp', 'verified', now(), now()), (apr_f, apr, 'e2e', 'totp', 'verified', now(), now());
  insert into auth.sessions(id, user_id, created_at, updated_at, aal, factor_id)
  values (own_s, own, now(), now(), 'aal2', own_f), (tgt_s, tgt, now(), now(), 'aal1', null),
         (tgt2_s, tgt2, now(), now(), 'aal1', null), (apr_s, apr, now(), now(), 'aal2', apr_f),
         (kyc_s, kyc, now(), now(), 'aal1', null);
  update public.company_owners set profile_id = own;

  foreach step in array steps loop
    begin
      report := report || step || ': ';
      line := '';
      who := case when step like 'own_%' then own when step like 'tgt_%' then tgt when step like 'apr_%' then apr
                  when step like 'kyc_%' then kyc else own end;
      sess := case when step like 'own_%' then own_s when step like 'tgt_%' then tgt_s when step like 'apr_%' then apr_s
                   when step like 'kyc_%' then kyc_s else own_s end;
      aal := case when step in ('kyc_aal1', 'apr_aal1') or step like 'tgt_%' then 'aal1' else 'aal2' end;
      if step = 'apr_aal1' then
        update auth.sessions set aal = 'aal1' where id = apr_s;
      elsif step like 'apr_%' then
        update auth.sessions set aal = 'aal2' where id = apr_s;
      end if;
      perform set_config('request.jwt.claims', json_build_object('sub', who, 'role', 'authenticated',
        'session_id', sess, 'aal', aal, 'is_anonymous', false)::text, true);
      perform set_config('role', case when step like 'pg_%' then 'postgres' when step like 'anon_%' then 'anon'
                                      else 'authenticated' end, true);
      if step like 'anon_%' then
        perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
      end if;

      case step
        when 'pg_setup' then
          perform kaoid_private.grant_kao_id_r27a(tgt);
          perform kaoid_private.grant_kao_id_r27a(apr);
          update public.verifications set status = 'approved' where profile_id in (tgt, apr);
          insert into public.verifications(profile_id, status)
          select x, 'approved' from unnest(array[tgt, apr]) x
           where not exists (select 1 from public.verifications v where v.profile_id = x);
          line := line || 'perms=' || (select count(*) from public.permissions)
            || ' new=' || (select count(*) from public.permissions where created_at >= now() - interval '1 minute')
            || ' line_roles=' || (select count(*) from public.admin_roles where is_system and is_active)
            || ' legacy_off=' || (select count(*) from public.admin_roles where code in ('admin', 'super_admin', 'support', 'kyc_officer') and not is_active)
            || ' kaoid_admin_holders=' || (select count(*) from public.admin_assignments a join public.admin_roles r on r.id = a.role_id where r.code = 'kaoid_admin' and a.is_active)
            || ' kyc_officer_active=' || (select count(*) from public.admin_assignments a join public.admin_roles r on r.id = a.role_id where r.code = 'kyc_officer' and a.is_active)
            || ' migrate_logs=' || (select count(*) from public.activity_logs where action = 'governance.role.migrate')
            || ' policy=' || (select minimum_approvals from public.approval_policies where code = 'admin_role_grant_r47')
            || ' owner_only_in_roles=' || (select count(*) from public.role_permissions rp join public.permissions p on p.id = rp.permission_id join public.admin_roles r on r.id = rp.role_id where r.is_active and kaoid_private.owner_only_permission_r47(p.code))
            || ' kyc_has_mfa=' || exists (select 1 from auth.mfa_factors where user_id = kyc and status::text = 'verified');
        when 'kyc_aal1' then
          line := line || 'review=' || kaoid_private.can_review_r7c() || ' admin=' || kaoid_private.admin_active_r13a();
        when 'pg_kyc_mfa' then
          insert into auth.mfa_factors(id, user_id, friendly_name, factor_type, status, created_at, updated_at)
          values (kyc_f, kyc, 'e2e', 'totp', 'verified', now(), now());
          update auth.sessions set aal = 'aal2', factor_id = kyc_f where id = kyc_s;
          line := line || 'ok';
        when 'kyc_aal2' then
          line := line || 'review=' || kaoid_private.can_review_r7c()
            || ' suspend=' || kaoid_private.permission_r13a('kaoid.account.suspend')
            || ' withdraw=' || kaoid_private.permission_r13a('wallet.withdraw.approve')
            || ' queue=' || (public.kyc_review_queue_r7c() is not null)
            || ' tools_grants=' || (kaoid_private.staff_tools_r24()->>'grant_approvals');
        when 'own_perm' then
          line := line || 'features=' || kaoid_private.permission_r13a('features.toggle')
            || ' review=' || kaoid_private.can_review_r7c()
            || ' tools_grants=' || (kaoid_private.staff_tools_r24()->>'grant_approvals');
        when 'own_snapshot' then
          j := public.staff_snapshot_r9b();
          line := line || 'roles=' || jsonb_array_length(j->'roles')
            || ' legacy=' || (select count(*) from jsonb_array_elements(j->'roles') x where (x->>'legacy')::boolean)
            || ' catalogue=' || jsonb_array_length(j->'catalogue')
            || ' owner_only=' || (select count(*) from jsonb_array_elements(j->'catalogue') x where (x->>'owner_only')::boolean)
            || ' approver_ready=' || (j->>'approver_ready')
            || ' kyc_row=' || coalesce((select x->>'currently_assigned' || '/mfa_needed=' || (x->>'needs_mfa')
                 from jsonb_array_elements(j->'assignments') x where x->>'profile_id' = kyc::text and x->>'code' = 'kaoid_admin'), 'missing');
        when 'own_role_bad' then
          perform public.staff_role_create_r47(own, 'ops', 'Ops');
          line := line || 'UNEXPECTED_OK';
        when 'own_role_create' then
          line := line || 'id=' || (public.staff_role_create_r47(own, 'custom_e2e_ops', 'E2E Ops', 'test') is not null);
        when 'own_role_perm' then
          line := line || 'tickets=' || public.staff_role_permission_r47(own, 'custom_e2e_ops', 'support.tickets.view', true)
            || ' hide=' || public.staff_role_permission_r47(own, 'custom_e2e_ops', 'listing.hide', true);
          perform set_config('role', 'postgres', true);
          line := line || ' count=' || (select count(*) from public.role_permissions rp join public.admin_roles r on r.id = rp.role_id where r.code = 'custom_e2e_ops');
        when 'own_role_owner_only' then
          perform public.staff_role_permission_r47(own, 'custom_e2e_ops', 'features.toggle', true);
          line := line || 'UNEXPECTED_OK';
        when 'own_role_system' then
          perform public.staff_role_update_r47(own, 'finance_admin', 'Money', null, true);
          line := line || 'UNEXPECTED_OK';
        when 'own_role_legacy' then
          perform public.staff_role_permission_r47(own, 'admin', 'support.tickets.view', true);
          line := line || 'UNEXPECTED_OK';
        when 'own_grant_nokyc' then
          perform public.staff_assign_r13a(own, tgt2::text, 'catalog_admin');
          line := line || 'UNEXPECTED_OK';
        when 'own_grant_kaoid_nokyc' then
          g1 := public.staff_assign_r13a(own, tgt2::text, 'kaoid_admin');
          perform set_config('role', 'postgres', true);
          line := line || 'mode=' || (select mode from kaoid_private.staff_grants_r47 where id = g1);
        when 'own_grant_cool' then
          g2 := public.staff_assign_r13a(own, tgt::text, 'catalog_admin');
          perform set_config('role', 'postgres', true);
          line := line || (select 'mode=' || g.mode || ' wait_h=' || round(extract(epoch from a.starts_at - now()) / 3600)
            from kaoid_private.staff_grants_r47 g join public.admin_assignments a on a.id = g.assignment_id where g.id = g2);
        when 'own_grant_dup' then
          perform public.staff_assign_r13a(own, tgt::text, 'catalog_admin');
          line := line || 'UNEXPECTED_OK';
        when 'tgt_wait' then
          line := line || 'brands=' || kaoid_private.permission_r13a('catalog.brands.manage')
            || ' admin=' || kaoid_private.admin_active_r13a();
        when 'own_cancel' then
          line := line || 'ok=' || public.staff_grant_cancel_r47(own, g1);
          perform set_config('role', 'postgres', true);
          line := line || ' assignment_active=' || (select a.is_active from kaoid_private.staff_grants_r47 g join public.admin_assignments a on a.id = g.assignment_id where g.id = g1);
        when 'own_cancel_again' then
          perform public.staff_grant_cancel_r47(own, g1);
          line := line || 'UNEXPECTED_OK';
        when 'pg_fast_forward' then
          update public.admin_assignments set starts_at = now() - interval '1 minute'
           where id = (select assignment_id from kaoid_private.staff_grants_r47 where id = g2);
          update kaoid_private.staff_grants_r47 set activate_at = now() - interval '1 minute' where id = g2;
          line := line || 'ok';
        when 'own_settle' then
          j := public.staff_snapshot_r9b();
          line := line || 'status=' || (select x->>'status' from jsonb_array_elements(j->'grants') x where x->>'id' = g2::text)
            || ' g1=' || (select x->>'status' from jsonb_array_elements(j->'grants') x where x->>'id' = g1::text)
            || ' history=' || jsonb_array_length(j->'history');
        when 'tgt_active' then
          line := line || 'brands=' || kaoid_private.permission_r13a('catalog.brands.manage')
            || ' admin=' || kaoid_private.admin_active_r13a()
            || ' hide=' || kaoid_private.permission_r13a('listing.hide');
        when 'own_dangerous_in_use' then
          perform public.staff_role_permission_r47(own, 'catalog_admin', 'listing.hide', true);
          line := line || 'UNEXPECTED_OK';
        when 'own_safe_in_use' then
          line := line || 'on=' || public.staff_role_permission_r47(own, 'catalog_admin', 'support.tickets.view', true)
            || ' off=' || public.staff_role_permission_r47(own, 'catalog_admin', 'support.tickets.view', false)
            || ' off_again=' || public.staff_role_permission_r47(own, 'catalog_admin', 'support.tickets.view', false);
        when 'pg_approver' then
          insert into public.admin_assignments(profile_id, role_id, assigned_by)
          select apr, id, own from public.admin_roles where code = 'legal_security_admin';
          line := line || 'ready=' || kaoid_private.grant_approver_ready_r47(own, tgt);
        when 'own_grant_two' then
          g3 := public.staff_assign_r13a(own, tgt::text, 'marketing_admin');
          perform set_config('role', 'postgres', true);
          line := line || 'mode=' || (select mode from kaoid_private.staff_grants_r47 where id = g3)
            || ' assignment=' || exists (select 1 from public.admin_assignments a join public.admin_roles r on r.id = a.role_id
                                          where a.profile_id = tgt and r.code = 'marketing_admin');
        when 'own_decide_self' then
          perform public.staff_grant_decide_r47(own, g3, true, 'self');
          line := line || 'UNEXPECTED_OK';
        when 'apr_aal1' then
          perform public.staff_grant_queue_r47();
          line := line || 'UNEXPECTED_OK';
        when 'apr_queue' then
          j := public.staff_grant_queue_r47();
          line := line || 'count=' || jsonb_array_length(j) || ' can_decide=' || (j->0->>'can_decide')
            || ' perms=' || jsonb_array_length(j->0->'permissions')
            || ' tools=' || (kaoid_private.staff_tools_r24()->>'pending_grants');
        when 'apr_reject_short' then
          perform public.staff_grant_decide_r47(apr, g3, false, 'x');
          line := line || 'UNEXPECTED_OK';
        when 'apr_approve' then
          line := line || 'activated=' || public.staff_grant_decide_r47(apr, g3, true, 'Checked with HR');
          perform set_config('role', 'postgres', true);
          line := line || ' request=' || (select q.status from kaoid_private.staff_grants_r47 g join public.approval_requests q on q.id = g.approval_request_id where g.id = g3);
        when 'tgt_marketing' then
          line := line || 'banners=' || kaoid_private.permission_r13a('marketing.banners.manage')
            || ' coupons_aal1=' || kaoid_private.permission_r13a('marketing.coupons.manage');
        when 'own_grant_two2' then
          g4 := public.staff_assign_r13a(own, tgt::text, 'cs_operator');
          perform set_config('role', 'postgres', true);
          line := line || 'mode=' || (select mode from kaoid_private.staff_grants_r47 where id = g4);
        when 'apr_reject' then
          line := line || 'activated=' || public.staff_grant_decide_r47(apr, g4, false, 'Not needed now');
          perform set_config('role', 'postgres', true);
          line := line || ' status=' || (select status from kaoid_private.staff_grants_r47 where id = g4)
            || ' assignment=' || exists (select 1 from public.admin_assignments a join public.admin_roles r on r.id = a.role_id
                                          where a.profile_id = tgt and r.code = 'cs_operator');
        when 'own_grant_two3' then
          g5 := public.staff_assign_r13a(own, tgt::text, 'logistics_admin');
          perform set_config('role', 'postgres', true);
          line := line || 'mode=' || (select mode from kaoid_private.staff_grants_r47 where id = g5);
        when 'pg_expire' then
          update public.approval_requests set expires_at = now() - interval '1 minute'
           where id = (select approval_request_id from kaoid_private.staff_grants_r47 where id = g5);
          line := line || 'ok';
        when 'own_expired' then
          j := public.staff_snapshot_r9b();
          perform set_config('role', 'postgres', true);
          line := line || 'status=' || (select x->>'status' from jsonb_array_elements(j->'grants') x where x->>'id' = g5::text)
            || ' request=' || (select q.status from kaoid_private.staff_grants_r47 g join public.approval_requests q on q.id = g.approval_request_id where g.id = g5);
        when 'tgt_denied' then
          begin
            perform public.staff_assign_r13a(tgt, tgt2::text, 'catalog_admin');
            line := line || 'assign=UNEXPECTED_OK';
          exception when others then line := line || 'assign=' || sqlerrm;
          end;
          begin
            perform public.staff_role_create_r47(tgt, 'custom_x1', 'X1');
            line := line || ' create=UNEXPECTED_OK';
          exception when others then line := line || ' create=' || sqlerrm;
          end;
          begin
            perform public.staff_grant_queue_r47();
            line := line || ' queue=UNEXPECTED_OK';
          exception when others then line := line || ' queue=' || sqlerrm;
          end;
        when 'anon_denied' then
          perform public.staff_grant_queue_r47();
          line := line || 'UNEXPECTED_OK';
        when 'own_revoke' then
          perform set_config('role', 'postgres', true);
          j := jsonb_build_object('a', (select assignment_id from kaoid_private.staff_grants_r47 where id = g3));
          perform set_config('role', 'authenticated', true);
          line := line || 'ok=' || public.staff_revoke_r13a(own, (j->>'a')::uuid);
        when 'pg_recipients' then
          line := line || 'kyc=' || exists (select 1 from kaoid_private.review_recipients_r14b(null, null) x where x = kyc)
            || ' owner=' || exists (select 1 from kaoid_private.review_recipients_r14b(null, null) x where x = own)
            || ' tgt=' || exists (select 1 from kaoid_private.review_recipients_r14b(null, null) x where x = tgt)
            || ' ready=' || (kaoid_private.security_status_r14a()->>'ready_reviewers');
        when 'pg_privs' then
          line := line || 'anon_exec=' || (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname in ('public', 'kaoid_private') and p.proname like '%\_r47' and has_function_privilege('anon', p.oid, 'execute'))
            || ' auth_public=' || (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname = 'public' and p.proname like 'staff\_%\_r47' and has_function_privilege('authenticated', p.oid, 'execute'))
            || ' auth_helpers=' || (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname = 'kaoid_private' and p.proname in ('owner_only_permission_r47', 'role_holder_ready_r47',
                'profile_permission_r47', 'grant_approver_ready_r47', 'role_dangerous_in_use_r47', 'staff_grants_settle_r47')
                and has_function_privilege('authenticated', p.oid, 'execute'))
            || ' table_auth=' || has_table_privilege('authenticated', 'kaoid_private.staff_grants_r47', 'select')
            || ' rls=' || (select relrowsecurity from pg_class where oid = 'kaoid_private.staff_grants_r47'::regclass)
            || ' search_path_unset=' || (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname in ('public', 'kaoid_private') and p.proname like '%\_r47' and p.proconfig is null);
        when 'pg_logs' then
          line := line || coalesce((select string_agg(action || '=' || c, ',' order by action) from (
            select action, count(*) c from public.activity_logs where created_at >= now()
               and (action like 'governance.role.%' or action like 'governance.grant.%') group by action) x), 'none');
      end case;
      perform set_config('role', 'postgres', true);
      report := report || coalesce(line, '<null>') || ' | ';
    exception when others then
      perform set_config('role', 'postgres', true);
      report := report || 'ERR ' || sqlstate || ' ' || sqlerrm || ' | ';
    end;
  end loop;
  raise exception 'E2E_REPORT %', report;
end $$;
