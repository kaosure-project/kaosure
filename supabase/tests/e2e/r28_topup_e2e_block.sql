-- R28 top-up journey: staff set the PromptPay account, a member with a Kao ID asks to top up from Secondhand and
-- Kao ID, uploads slips, staff approve (single and two-person), reject, catch reused slips and references, and the
-- limits, expiry, cancel and permission rules hold. Everything is rolled back.
do $$
declare
  mem uuid := gen_random_uuid();
  nokid uuid := gen_random_uuid();
  st1 uuid := gen_random_uuid();
  st2 uuid := gen_random_uuid();
  mem_s uuid := gen_random_uuid();
  nokid_s uuid := gen_random_uuid();
  st1_s uuid := gen_random_uuid();
  st2_s uuid := gen_random_uuid();
  cid uuid := 'f56cdf5a-347a-4847-ad0d-f05b580b007c';
  t1 uuid;
  t2 uuid;
  t3 uuid;
  t4 uuid;
  t5 uuid;
  t6 uuid;
  n int;
  report text := '';
  j jsonb;
  t text;
  who uuid;
  sess uuid;
  step text;
  expected text;
  expected_qr text;
  err_ctx text;
  as_postgres text[] := array['setup', 'pg_settings_log', 'pg_wallet1', 'pg_upload2', 'pg_upload2b', 'pg_wallet_rej',
                              'pg_upload3', 'pg_wallet2', 'pg_daily', 'pg_expire', 'pg_grant_st1', 'pg_upload_st1',
                              'pg_bad_status', 'pg_privs', 'pg_invariants'];
  as_nokid text[] := array['n_info', 'n_create'];
  as_st1 text[] := array['st1_settings', 'st1_save_noreceiver', 'st1_save_badphone', 'st1_save', 'st1_save_stale',
                         'st1_tools', 'st1_queue', 'st1_detail', 'st1_slip_read', 'st1_approve_nopayer',
                         'st1_approve_noref', 'st1_approve', 'st1_approve_again', 'st1_approve_dupref',
                         'st1_reject_noreason', 'st1_reject', 'st1_first', 'st1_second_self', 'st1_reject_own_vote',
                         'st1_create', 'st1_attach', 'st1_own_review'];
  as_st2 text[] := array['st2_mismatch', 'st2_nopayer', 'st2_approve', 'st2_tools'];
  as_anon text[] := array['anon_info', 'anon_queue'];
  secondhand_steps text[] := array['guard_sh', 'guard_sh_staff', 'm_create', 'm_upload_bad', 'm_upload', 'm_attach',
                                   'm_history_sh', 'sh_settings'];
  steps text[] := array['setup', 'guard_sh', 'guard_sh_staff', 'm_info_off', 'm_create_off', 'm_settings_denied',
    'st1_settings', 'st1_save_noreceiver', 'st1_save_badphone', 'st1_save', 'st1_save_stale', 'pg_settings_log',
    'sh_settings', 'n_info', 'n_create', 'm_info', 'm_create_small', 'm_create_frac', 'm_create_big', 'm_create',
    'm_create_again', 'm_attach_noslip', 'm_upload_bad', 'm_upload', 'm_attach', 'm_attach_again', 'm_cancel_pending',
    'm_review_self', 'm_direct_select', 'st1_tools', 'st2_tools', 'st1_queue', 'st1_detail', 'st1_slip_read',
    'm_slip_read', 'st1_approve_nopayer', 'st1_approve_noref', 'st1_approve', 'st1_approve_again', 'pg_wallet1',
    'm_info2', 'm_create2', 'pg_upload2', 'm_attach2_dup', 'pg_upload2b', 'm_attach2', 'st1_approve_dupref',
    'st1_reject_noreason', 'st1_reject', 'pg_wallet_rej', 'm_create3', 'pg_upload3', 'm_attach3', 'st1_first',
    'st1_second_self', 'st1_reject_own_vote', 'st2_mismatch', 'st2_nopayer', 'st2_approve', 'pg_wallet2', 'm_info3',
    'pg_daily', 'm_create_daily', 'm_create4', 'm_cancel', 'm_cancel_again', 'm_create5', 'pg_expire',
    'm_upload_expired', 'm_attach5', 'm_history', 'm_history_sh', 'pg_grant_st1', 'st1_create', 'pg_upload_st1',
    'st1_attach', 'st1_own_review', 'anon_info', 'anon_queue', 'pg_bad_status', 'pg_privs', 'pg_invariants'];
begin
  insert into auth.users(id, instance_id, aud, role, email, phone, raw_app_meta_data, raw_user_meta_data,
                         created_at, updated_at, is_anonymous, email_confirmed_at, phone_confirmed_at)
  select x.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'e2e-r28-' || x.tag || '-' || left(x.id::text, 8) || '@example.invalid',
         '6683' || lpad((random() * 1e7)::int::text, 7, '0'),
         '{"provider":"email","providers":["email"]}', jsonb_build_object('display_name', x.name),
         now(), now(), false, now(), now()
    from (values (mem, 'mem', 'Topup Member'), (nokid, 'nokid', 'No Kao ID'), (st1, 'st1', 'Finance One'),
                 (st2, 'st2', 'Finance Two')) x(id, tag, name);
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (mem_s, mem, now(), now(), 'aal1'), (nokid_s, nokid, now(), now(), 'aal1'), (st1_s, st1, now(), now(), 'aal1'),
         (st2_s, st2, now(), now(), 'aal1');
  update public.company_owners set profile_id = st1;

  foreach step in array steps loop
    begin
      report := concat(report, step, ': ');
      who := case when step = any(as_nokid) then nokid when step = any(as_st1) then st1
                  when step = any(as_st2) then st2 else mem end;
      sess := case when step = any(as_nokid) then nokid_s when step = any(as_st1) then st1_s
                   when step = any(as_st2) then st2_s else mem_s end;
      if step = any(as_anon) then
        perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
      elsif step = any(secondhand_steps) then
        perform set_config('request.jwt.claims', json_build_object(
          'sub', who, 'role', 'authenticated', 'session_id', sess,
          'aal', 'aal1', 'is_anonymous', false, 'client_id', cid)::text, true);
      else
        perform set_config('request.jwt.claims', json_build_object(
          'sub', who, 'role', 'authenticated', 'session_id', sess, 'aal', 'aal1', 'is_anonymous', false)::text, true);
      end if;
      perform set_config('request.headers', '{"content-profile":"public"}', true);
      perform set_config('request.method', 'POST', true);
      perform set_config('role', case when step = any(as_anon) then 'anon'
                                      when step = any(as_postgres) then 'postgres' else 'authenticated' end, true);

      case step
        when 'setup' then
          perform kaoid_private.grant_kao_id_r27a(mem);
          insert into public.identity_documents(owner_id, document_type, document_number, full_name, country_code,
                                                issuing_country, status, verified_at)
          values (mem, 'thai_national_id', '1101700203451', 'สมชาย ทดสอบเติมเงิน', 'TH', 'THA', 'approved', now());
          perform kaoid_private.grant_kao_id_r27a(st2);
          update public.verifications set status = 'approved' where profile_id = st2;
          if not found then
            insert into public.verifications(profile_id, status) values (st2, 'approved');
          end if;
          insert into public.admin_assignments(profile_id, role_id, assigned_by)
          select st2, id, st1 from public.admin_roles where code = 'admin';
          insert into auth.mfa_factors(id, user_id, friendly_name, factor_type, status, created_at, updated_at)
          values (gen_random_uuid(), st1, 'e2e', 'totp', 'verified', now(), now()),
                 (gen_random_uuid(), st2, 'e2e', 'totp', 'verified', now(), now());
          expected := '00020101021229370016A000000677010111011300668123456785303764540'
                      || '6500.005802TH6304';
          expected_qr := expected || kaoid_private.crc16_ccitt_r28(expected);
          report := concat(report, 'kao_id=', kaoid_private.kao_id_active_r28(mem),
            ' perms=', (select count(*) from public.permissions where code like 'wallet.deposit.%'),
            ' bucket=', (select public::text || '/' || file_size_limit from storage.buckets where id = 'wallet-slips'),
            ' settings=', (select enabled || '/v' || version from kaoid_private.topup_settings_r28),
            ' crc_vector=', kaoid_private.crc16_ccitt_r28('123456789'),
            ' payload_ok=', kaoid_private.promptpay_payload_r28('phone', '0812345678', 500) = expected_qr,
            ' natid_tag=', substr(kaoid_private.promptpay_payload_r28('national_id', '0105561234560', 1), 13, 29),
            ' cron=', (select count(*) from cron.job where jobname = 'kaoid-topup-expiry-r28'),
            ' policy=', (select dual_review || '/' || mfa_required from kaoid_private.security_policy_r14a));
        when 'guard_sh' then
          foreach t in array array['topup_info_r28', 'topup_create_r28', 'topup_attach_slip_r28', 'topup_cancel_r28',
                                   'topup_history_r28'] loop
            perform set_config('request.path', '/rpc/' || t, true);
            perform kaoid_private.pre_request_r10d();
          end loop;
          report := concat(report, 'allowed');
        when 'guard_sh_staff' then
          foreach t in array array['topup_queue_r28', 'topup_detail_r28', 'topup_review_r28', 'topup_settings_r28',
                                   'topup_settings_save_r28'] loop
            begin
              perform set_config('request.path', '/rpc/' || t, true);
              perform kaoid_private.pre_request_r10d();
              report := concat(report, t, '=UNEXPECTED_OK ');
            exception when others then
              report := concat(report, t, '=blocked ');
            end;
          end loop;
        when 'm_info_off' then
          j := public.topup_info_r28();
          report := concat(report, 'can=', j->>'can_top_up', ' reason=', j->>'reason', ' receiver=',
                           coalesce(j->>'receiver_name', '-'));
        when 'm_create_off' then
          perform public.topup_create_r28(500, 'kaoid');
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_settings_denied' then
          perform public.topup_settings_r28();
          report := concat(report, 'UNEXPECTED_OK');
        when 'st1_settings' then
          j := public.topup_settings_r28();
          report := concat(report, 'enabled=', j->>'enabled', ' v=', j->>'version', ' min=', j->>'min_amount',
                           ' max=', j->>'max_amount', ' day=', j->>'daily_max', ' dual=', j->>'dual_review_from',
                           ' hours=', j->>'slip_hours');
        when 'st1_save_noreceiver' then
          perform public.topup_settings_save_r28(true, null, null, null, 100, 50000, 200000, 50000, 24, 1);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st1_save_badphone' then
          perform public.topup_settings_save_r28(true, 'phone', '12345', 'KaoSure', 100, 50000, 200000, 50000, 24, 1);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st1_save' then
          j := public.topup_settings_save_r28(true, 'phone', '081-234-5678', '  บริษัท เก้าชัวร์ ทดสอบ จำกัด ', 100,
                                              50000, 200000, 50000, 24, 1);
          report := concat(report, 'enabled=', j->>'enabled', ' v=', j->>'version', ' id=', j->>'promptpay_id',
                           ' name=[', j->>'receiver_name', ']');
        when 'st1_save_stale' then
          perform public.topup_settings_save_r28(false, 'phone', '0812345678', 'x', 100, 50000, 200000, 50000, 24, 1);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_settings_log' then
          report := concat(report, (select count(*) || ' [' || max(description) || ']' from public.activity_logs
                                     where action = 'finance.topup.settings' and profile_id = st1));
        when 'sh_settings' then
          perform public.topup_settings_r28();
          report := concat(report, 'UNEXPECTED_OK');
        when 'n_info' then
          j := public.topup_info_r28();
          report := concat(report, 'can=', j->>'can_top_up', ' reason=', j->>'reason');
        when 'n_create' then
          perform public.topup_create_r28(500, 'kaoid');
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_info' then
          j := public.topup_info_r28();
          report := concat(report, 'can=', j->>'can_top_up', ' min=', j->>'min_amount', ' max=', j->>'max_amount',
                           ' day=', j->>'daily_max', ' receiver=', j->>'receiver_name', ' balance=', j->>'balance');
        when 'm_create_small' then
          perform public.topup_create_r28(99, 'kaoid');
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_create_frac' then
          perform public.topup_create_r28(100.005, 'kaoid');
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_create_big' then
          perform public.topup_create_r28(50000.01, 'kaoid');
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_create' then
          j := public.topup_create_r28(500, 'secondhand');
          t1 := (j->>'id')::uuid;
          report := concat(report, j->>'status', ' code=', j->>'code', ' masked=', j->>'promptpay_masked',
                           ' qr_ok=', j->>'qr_payload' = expected_qr,
                           ' source=', j->>'source_app', ' has_full_id=', j::text like '%0812345678%');
        when 'm_create_again' then
          perform public.topup_create_r28(100, 'kaoid');
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_attach_noslip' then
          perform public.topup_attach_slip_r28(t1);
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_upload_bad' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          values ('wallet-slips', mem || '/' || gen_random_uuid() || '/slip.jpg', mem::text,
                  '{"size": 100, "mimetype": "image/jpeg"}');
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_upload' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          values ('wallet-slips', mem || '/' || t1 || '/slip.jpg', mem::text,
                  '{"size": 180000, "mimetype": "image/jpeg", "eTag": "\"etag-one\""}');
          report := concat(report, 'ok');
        when 'm_attach' then
          j := public.topup_attach_slip_r28(t1);
          report := concat(report, j->>'status', ' qr_hidden=', j->>'qr_payload' is null, ' uploaded=',
                           j->>'slip_uploaded_at' is not null);
        when 'm_attach_again' then
          j := public.topup_attach_slip_r28(t1);
          report := concat(report, j->>'status');
        when 'm_cancel_pending' then
          perform public.topup_cancel_r28(t1);
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_review_self' then
          perform public.topup_review_r28(t1, true, true, 'REF-SELF', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_direct_select' then
          perform count(*) from public.topup_requests;
          report := concat(report, 'UNEXPECTED_OK');
        when 'st1_tools' then
          j := public.staff_tools_r24();
          report := concat(report, 'topups=', j->>'topups', ' settings=', j->>'topup_settings', ' pending=',
                           j->>'pending_topups', ' withdrawals=', j->>'withdrawals');
        when 'st2_tools' then
          j := public.staff_tools_r24();
          report := concat(report, 'topups=', j->>'topups', ' settings=', j->>'topup_settings');
        when 'st1_queue' then
          j := public.topup_queue_r28('pending_review', null);
          report := concat(report, 'has_t1=', j @> jsonb_build_array(jsonb_build_object('id', t1)),
                           ' name=', (select e->>'display_name' from jsonb_array_elements(j) e where e->>'id' = t1::text),
                           ' dual=', (select e->>'dual_review' from jsonb_array_elements(j) e where e->>'id' = t1::text));
        when 'st1_detail' then
          j := public.topup_detail_r28(t1);
          report := concat(report, 'member_name=', j->>'member_name', ' kao_id=', j->>'kao_id' is not null,
                           ' active=', j->>'kao_id_active', ' dups=', jsonb_array_length(j->'duplicate_slips'),
                           ' slip=', j->>'slip_path' = mem || '/' || t1 || '/slip.jpg', ' own=', j->>'own_request');
        when 'st1_slip_read' then
          report := concat(report, (select count(*) from storage.objects
                                     where bucket_id = 'wallet-slips' and name = mem || '/' || t1 || '/slip.jpg'));
        when 'm_slip_read' then
          report := concat(report, (select count(*) from storage.objects where bucket_id = 'wallet-slips'));
        when 'st1_approve_nopayer' then
          perform public.topup_review_r28(t1, true, false, 'KBANK-001', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st1_approve_noref' then
          perform public.topup_review_r28(t1, true, true, ' ', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st1_approve' then
          j := public.topup_review_r28(t1, true, true, 'KBANK-001', null);
          report := concat(report, j->>'status', ' ref=', j->>'bank_reference', ' reviewer=', j->>'reviewer_name');
        when 'st1_approve_again' then
          j := public.topup_review_r28(t1, true, true, 'KBANK-001', null);
          report := concat(report, j->>'status');
        when 'pg_wallet1' then
          report := concat(report, (select 'balance=' || balance || ' hold=' || hold_balance from public.wallets
                                     where profile_id = mem),
            ' tx=', (select t2.transaction_type || '/' || t2.transaction_status || '/' || t2.amount || '/'
                            || t2.balance_before || '->' || t2.balance_after
                       from public.wallet_transactions t2 join public.topup_requests r on r.wallet_transaction_id = t2.id
                      where r.id = t1),
            ' note=[', (select notification_type || ' | ' || title || ' | ' || message from public.notifications
                          where event_key = 'topup:' || t1 || ':approved'), ']',
            ' log=', (select count(*) from public.activity_logs where action = 'finance.topup.approve' and target_id = t1),
            ' read_log=', (select count(*) from public.activity_logs where action = 'finance.topup.read' and target_id = t1));
        when 'm_info2' then
          j := public.topup_info_r28();
          report := concat(report, 'can=', j->>'can_top_up', ' balance=', j->>'balance', ' today=', j->>'today_total',
                           ' open=', coalesce(j->'open'->>'status', '-'));
        when 'm_create2' then
          j := public.topup_create_r28(1000, 'kaoid');
          t2 := (j->>'id')::uuid;
          report := concat(report, j->>'status', ' source=', j->>'source_app');
        when 'pg_upload2' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          values ('wallet-slips', mem || '/' || t2 || '/slip.jpg', mem::text,
                  '{"size": 180000, "mimetype": "image/jpeg", "eTag": "\"etag-one\""}');
          report := concat(report, 'ok');
        when 'm_attach2_dup' then
          perform public.topup_attach_slip_r28(t2);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_upload2b' then
          update storage.objects set metadata = '{"size": 190000, "mimetype": "image/jpeg", "eTag": "\"etag-two\""}'
           where bucket_id = 'wallet-slips' and name = mem || '/' || t2 || '/slip.jpg';
          report := concat(report, 'ok');
        when 'm_attach2' then
          j := public.topup_attach_slip_r28(t2);
          report := concat(report, j->>'status');
        when 'st1_approve_dupref' then
          perform public.topup_review_r28(t2, true, true, 'kbank-001', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st1_reject_noreason' then
          perform public.topup_review_r28(t2, false, false, null, 'x');
          report := concat(report, 'UNEXPECTED_OK');
        when 'st1_reject' then
          j := public.topup_review_r28(t2, false, false, null, 'ชื่อผู้โอนไม่ตรงกับเจ้าของบัญชี');
          report := concat(report, j->>'status', ' reason=', j->>'reject_reason');
        when 'pg_wallet_rej' then
          report := concat(report, (select 'balance=' || balance from public.wallets where profile_id = mem),
            ' deposits=', (select count(*) from public.wallet_transactions x join public.wallets w on w.id = x.wallet_id
                            where w.profile_id = mem and x.transaction_type = 'deposit'),
            ' note=[', (select title || ' | ' || message from public.notifications
                          where event_key = 'topup:' || t2 || ':rejected'), ']');
        when 'm_create3' then
          j := public.topup_create_r28(50000, 'kaoid');
          t3 := (j->>'id')::uuid;
          report := concat(report, j->>'status');
        when 'pg_upload3' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          values ('wallet-slips', mem || '/' || t3 || '/slip.jpg', mem::text,
                  '{"size": 200000, "mimetype": "image/jpeg", "eTag": "\"etag-three\""}');
          report := concat(report, 'ok');
        when 'm_attach3' then
          j := public.topup_attach_slip_r28(t3);
          report := concat(report, j->>'status');
        when 'st1_first' then
          j := public.topup_review_r28(t3, true, true, 'SCB-777', null);
          report := concat(report, j->>'status', ' first=', j->>'first_reviewer_name');
        when 'st1_second_self' then
          j := public.topup_review_r28(t3, true, true, 'SCB-777', null);
          report := concat(report, j->>'status');
        when 'st1_reject_own_vote' then
          perform public.topup_review_r28(t3, false, false, null, 'เปลี่ยนใจ');
          report := concat(report, 'UNEXPECTED_OK');
        when 'st2_mismatch' then
          perform public.topup_review_r28(t3, true, true, 'SCB-778', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st2_nopayer' then
          perform public.topup_review_r28(t3, true, false, 'SCB-777', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st2_approve' then
          j := public.topup_review_r28(t3, true, true, 'scb-777', null);
          report := concat(report, j->>'status', ' ref=', j->>'bank_reference');
        when 'pg_wallet2' then
          report := concat(report, (select 'balance=' || balance from public.wallets where profile_id = mem),
            ' deposits=', (select count(*) from public.wallet_transactions x join public.wallets w on w.id = x.wallet_id
                            where w.profile_id = mem and x.transaction_type = 'deposit'),
            ' logs=', (select string_agg(action, ',' order by created_at) from public.activity_logs
                        where target_id = t3 and action like 'finance.topup.%approve'));
        when 'm_info3' then
          j := public.topup_info_r28();
          report := concat(report, 'today=', j->>'today_total', ' max=', j->>'max_amount', ' can=', j->>'can_top_up');
        when 'pg_daily' then
          update kaoid_private.topup_settings_r28 set daily_max = 60000 where id;
          report := concat(report, 'ok');
        when 'm_create_daily' then
          perform public.topup_create_r28(10000, 'kaoid');
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_create4' then
          j := public.topup_create_r28(100, 'kaoid');
          t4 := (j->>'id')::uuid;
          report := concat(report, j->>'status');
        when 'm_cancel' then
          j := public.topup_cancel_r28(t4);
          report := concat(report, j->>'status');
        when 'm_cancel_again' then
          j := public.topup_cancel_r28(t4);
          report := concat(report, j->>'status');
        when 'm_create5' then
          j := public.topup_create_r28(100, 'kaoid');
          t5 := (j->>'id')::uuid;
          report := concat(report, j->>'status');
        when 'pg_expire' then
          update public.topup_requests set expires_at = now() - interval '1 minute' where id = t5;
          report := concat(report, 'expired=', kaoid_private.expire_topups_r28(),
                           ' status=', (select status from public.topup_requests where id = t5));
        when 'm_upload_expired' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          values ('wallet-slips', mem || '/' || t5 || '/slip.jpg', mem::text, '{"size": 100, "mimetype": "image/jpeg"}');
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_attach5' then
          perform public.topup_attach_slip_r28(t5);
          report := concat(report, 'UNEXPECTED_OK');
        when 'm_history' then
          j := public.topup_history_r28(null, 20);
          report := concat(report, 'n=', jsonb_array_length(j), ' statuses=',
                           (select string_agg(e->>'status', ',') from jsonb_array_elements(j) e),
                           ' leaks=', j::text like '%bank_reference%' or j::text like '%slip_path%');
        when 'm_history_sh' then
          j := public.topup_history_r28(null, 2);
          report := concat(report, 'n=', jsonb_array_length(j));
        when 'pg_grant_st1' then
          perform kaoid_private.grant_kao_id_r27a(st1);
          update kaoid_private.topup_settings_r28 set daily_max = 200000 where id;
          report := concat(report, 'ok');
        when 'st1_create' then
          j := public.topup_create_r28(100, 'kaoid');
          t6 := (j->>'id')::uuid;
          report := concat(report, j->>'status');
        when 'pg_upload_st1' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          values ('wallet-slips', st1 || '/' || t6 || '/slip.jpg', st1::text,
                  '{"size": 100000, "mimetype": "image/jpeg", "eTag": "\"etag-six\""}');
          report := concat(report, 'ok');
        when 'st1_attach' then
          j := public.topup_attach_slip_r28(t6);
          report := concat(report, j->>'status');
        when 'st1_own_review' then
          perform public.topup_review_r28(t6, true, true, 'OWN-1', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'anon_info' then
          perform public.topup_info_r28();
          report := concat(report, 'UNEXPECTED_OK');
        when 'anon_queue' then
          perform public.topup_queue_r28('pending_review', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_bad_status' then
          update public.topup_requests set status = 'approved' where id = t6;
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_privs' then
          report := concat(report,
            'auth_select=', has_table_privilege('authenticated', 'public.topup_requests', 'select'),
            ' settings_select=', has_table_privilege('authenticated', 'kaoid_private.topup_settings_r28', 'select'),
            ' anon_info=', has_function_privilege('anon', 'public.topup_info_r28()', 'execute'),
            ' auth_payload=', has_function_privilege('authenticated',
                                'kaoid_private.promptpay_payload_r28(text, text, numeric)', 'execute'),
            ' auth_expire=', has_function_privilege('authenticated', 'kaoid_private.expire_topups_r28(uuid)', 'execute'),
            ' sh_allow=', (select count(*) from kaoid_private.app_clients_r18, unnest(allowed_rpcs) r
                            where app_code = 'secondhand_web' and r like 'public.topup_%'));
        when 'pg_invariants' then
          report := concat(report,
            'approved_without_tx=', (select count(*) from public.topup_requests
                                      where status = 'approved' and wallet_transaction_id is null),
            ' wallet_matches_deposits=', (select w.balance = coalesce(sum(x.amount), 0)
                                            from public.wallets w
                                            left join public.wallet_transactions x
                                              on x.wallet_id = w.id and x.transaction_type = 'deposit'
                                           where w.profile_id = mem group by w.balance),
            ' open=', (select count(*) from public.topup_requests
                        where profile_id = mem and status in ('awaiting_slip', 'pending_review', 'awaiting_second')));
      end case;
    exception when others then
      get stacked diagnostics err_ctx = pg_exception_context;
      report := concat(report, 'ERR ', sqlerrm,
                       case when sqlerrm like 'permission denied%' then ' CTX ' || err_ctx end);
    end;
    report := concat(report, E'\n');
  end loop;
  raise exception 'E2E_REPORT%', E'\n' || report;
end $$;
