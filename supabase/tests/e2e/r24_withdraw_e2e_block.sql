-- R24 checks: wallet withdrawals and system contents. Appended after the migration inside one transaction that never commits.
do $$
declare
  seller uuid := '9044e32e-24e7-49e2-9aaf-500c48ecce7e';
  buyer uuid := '3bd1dcd3-6ab3-4af5-a83f-2c9883438629';
  staff uuid;
  seller_session uuid := gen_random_uuid();
  buyer_session uuid := gen_random_uuid();
  staff_session uuid := gen_random_uuid();
  cid uuid := 'f56cdf5a-347a-4847-ad0d-f05b580b007c';
  w1 uuid;
  w2 uuid;
  w3 uuid;
  c1 uuid;
  report text := '';
  j jsonb;
  t text;
  who uuid;
  sess uuid;
  step text;
  as_postgres text[] := array['setup', 'pg_wallet1', 'pg_wallet2', 'pg_wallet3', 'pg_wallet4', 'pg_plain_account',
                              'pg_negative', 'pg_revisions'];
  as_staff text[] := array['st_tools', 'st_queue', 'st_detail', 'st_paid_noref', 'st_paid', 'st_paid_again',
                           'st_reject_noreason', 'st_reject', 'st_paid_rejected', 'st_c_save', 'st_c_bad',
                           'st_c_update', 'st_c_stale', 'st_c_keylock', 'st_c_list', 'st_c_delete'];
  as_buyer text[] := array['b_tools', 'b_info', 'b_queue', 'b_c_list'];
  as_anon text[] := array['anon_info', 'anon_contents', 'anon_after_delete', 'anon_queue'];
  steps text[] := array['setup', 'guard_seller', 'guard_contents', 'guard_staff_blocked', 's_info', 's_req_small',
    's_req_frac', 's_req_big', 's_req', 's_req_again', 'pg_wallet1', 's_info2', 's_cancel', 'pg_wallet2', 's_req2',
    's_queue', 's_review', 's_content_save', 'b_tools', 'b_info', 'b_queue', 'b_c_list', 'anon_info', 'anon_queue', 'st_tools', 'st_queue',
    'st_detail', 'st_paid_noref', 'st_paid', 'st_paid_again', 'pg_wallet3', 's_req3', 'st_reject_noreason',
    'st_reject', 'st_paid_rejected', 'pg_wallet4', 's_list', 's_my_page', 'anon_contents', 'st_c_save', 'st_c_bad',
    'st_c_update', 'st_c_stale', 'st_c_keylock', 'st_c_list', 'st_c_delete', 'pg_revisions', 'anon_after_delete',
    'pg_plain_account', 'pg_negative'];
begin
  -- Only one company owner may exist: hand ownership to the buyer for this rolled-back run so the seller is a plain
  -- member and the buyer acts as staff (through Kao ID) or as an owner holding an app token.
  update public.company_owners set profile_id = buyer;
  staff := (select profile_id from public.company_owners limit 1);
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
    values (seller_session, seller, now(), now(), 'aal1'), (buyer_session, buyer, now(), now(), 'aal1'),
         (staff_session, staff, now(), now(), 'aal1');

  foreach step in array steps loop
    begin
      report := concat(report, step, ': ');
      who := case when step = any(as_staff) then staff when step = any(as_buyer) then buyer else seller end;
      sess := case when step = any(as_staff) then staff_session when step = any(as_buyer) then buyer_session
                   else seller_session end;
      if step = any(as_anon) then
        perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
      elsif step = any(as_staff) then
        perform set_config('request.jwt.claims', json_build_object(
          'sub', who, 'role', 'authenticated', 'session_id', sess, 'aal', 'aal1', 'is_anonymous', false)::text, true);
      else
        perform set_config('request.jwt.claims', json_build_object(
          'sub', who, 'role', 'authenticated', 'session_id', sess,
          'aal', 'aal1', 'is_anonymous', false, 'client_id', cid)::text, true);
      end if;
      perform set_config('request.headers', '{"content-profile":"secondhand"}', true);
      perform set_config('request.method', 'POST', true);
      perform set_config('role', case when step = any(as_anon) then 'anon'
                                      when step = any(as_postgres) then 'postgres' else 'authenticated' end, true);

      case step
        when 'setup' then
          insert into public.wallets(profile_id) values (seller) on conflict (profile_id) do nothing;
          update public.wallets set balance = 500, hold_balance = 0 where profile_id = seller;
          report := concat(report, 'staff=', staff is not null, ' seller_bank=',
                           (secondhand.payout_bank_r24(seller)).id is not null,
                           ' buyer_bank=', (secondhand.payout_bank_r24(buyer)).id is not null,
                           ' min=', (select withdraw_min_amount from secondhand.market_settings where id),
                           ' perms=', (select count(*) from public.permissions
                                        where code in ('wallet.withdraw.approve', 'content.system.manage')),
                           ' seeds=', (select count(*) from public.system_contents));
        when 'guard_seller' then
          foreach t in array array['get_withdrawal_info', 'request_withdrawal', 'cancel_withdrawal',
                                   'list_my_withdrawals', 'get_my_page'] loop
            perform set_config('request.path', '/rpc/' || t, true);
            perform kaoid_private.pre_request_r10d();
          end loop;
          report := concat(report, 'allowed');
        when 'guard_contents' then
          perform set_config('request.headers', '{"content-profile":"public"}', true);
          perform set_config('request.path', '/rpc/get_system_contents', true);
          perform kaoid_private.pre_request_r10d();
          report := concat(report, 'allowed');
        when 'guard_staff_blocked' then
          perform set_config('request.headers', '{"content-profile":"public"}', true);
          foreach t in array array['withdrawal_queue_r24', 'withdrawal_review_r24', 'content_save_r24',
                                   'staff_tools_r24'] loop
            begin
              perform set_config('request.path', '/rpc/' || t, true);
              perform kaoid_private.pre_request_r10d();
              report := concat(report, t, '=UNEXPECTED_OK ');
            exception when others then
              report := concat(report, t, '=blocked ');
            end;
          end loop;
        when 's_info' then
          j := secondhand.get_withdrawal_info();
          report := concat(report, 'can=', j->>'can_withdraw', ' reason=', coalesce(j->>'reason', '-'),
                           ' balance=', j->>'balance', ' min=', j->>'min_amount', ' fee=', j->>'fee',
                           ' bank=', j->'bank' ? 'last4', ' last4_len=', length(j->'bank'->>'last4'),
                           ' pending_release=', j->>'pending_release');
        when 's_req_small' then
          perform secondhand.request_withdrawal(99);
          report := concat(report, 'UNEXPECTED_OK');
        when 's_req_frac' then
          perform secondhand.request_withdrawal(100.005);
          report := concat(report, 'UNEXPECTED_OK');
        when 's_req_big' then
          perform secondhand.request_withdrawal(600);
          report := concat(report, 'UNEXPECTED_OK');
        when 's_req' then
          j := secondhand.request_withdrawal(300);
          w1 := (j->>'id')::uuid;
          report := concat(report, j->>'status', ' amount=', j->>'amount', ' has_number_key=', j ? 'account_number');
        when 's_req_again' then
          perform secondhand.request_withdrawal(100);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_wallet1' then
          report := concat(report, (select 'balance=' || balance || ' hold=' || hold_balance from public.wallets
                                     where profile_id = seller),
                           ' tx=', (select t2.transaction_type || '/' || t2.transaction_status || '/' || t2.amount
                                      from public.wallet_transactions t2
                                      join public.withdraw_requests r on r.wallet_transaction_id = t2.id
                                     where r.id = w1),
                           ' plain_number=', (select account_number is not null from public.withdraw_requests
                                                where id = w1));
        when 's_info2' then
          j := secondhand.get_withdrawal_info();
          report := concat(report, 'can=', j->>'can_withdraw', ' reason=', j->>'reason', ' hold=', j->>'hold_balance',
                           ' pending=', j->'pending'->>'status');
        when 's_cancel' then
          j := secondhand.cancel_withdrawal(w1);
          report := concat(report, j->>'status');
        when 'pg_wallet2' then
          report := concat(report, (select 'balance=' || balance || ' hold=' || hold_balance from public.wallets
                                     where profile_id = seller),
                           ' tx=', (select transaction_status from public.wallet_transactions t2
                                      join public.withdraw_requests r on r.wallet_transaction_id = t2.id
                                     where r.id = w1),
                           ' returns=', (select count(*) from public.wallet_transactions t2
                                           join public.wallets w on w.id = t2.wallet_id
                                          where w.profile_id = seller and t2.transaction_type = 'withdraw_return'));
        when 's_req2' then
          j := secondhand.request_withdrawal(300);
          w2 := (j->>'id')::uuid;
          report := concat(report, j->>'status');
        when 's_queue' then
          perform public.withdrawal_queue_r24('pending', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 's_review' then
          perform public.withdrawal_review_r24(w2, true, 'REF-1', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 's_content_save' then
          perform public.content_save_r24(null, 'secondhand.e2e.sample', 'secondhand', 'guide',
                                          '{"th":"ทดสอบ"}', '{"th":"เนื้อหา"}', '{}', 0, true, null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'b_tools' then
          j := public.staff_tools_r24();
          report := concat(report, j::text);
        when 'b_info' then
          j := secondhand.get_withdrawal_info();
          report := concat(report, 'can=', j->>'can_withdraw', ' reason=', j->>'reason');
        when 'b_queue' then
          perform public.withdrawal_queue_r24('pending', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'b_c_list' then
          perform public.content_list_r24(null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'anon_info' then
          perform secondhand.get_withdrawal_info();
          report := concat(report, 'UNEXPECTED_OK');
        when 'anon_queue' then
          perform public.withdrawal_queue_r24('pending', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st_tools' then
          j := public.staff_tools_r24();
          report := concat(report, 'withdrawals=', j->>'withdrawals', ' contents=', j->>'contents',
                           ' pending>=1=', (j->>'pending_withdrawals')::int >= 1);
        when 'st_queue' then
          j := public.withdrawal_queue_r24('pending', null);
          report := concat(report, 'has_w2=', j @> jsonb_build_array(jsonb_build_object('id', w2)),
                           ' has_number=', j::text like '%account_number%', ' name=',
                           (select e->>'display_name' is not null from jsonb_array_elements(j) e
                             where e->>'id' = w2::text));
        when 'st_detail' then
          j := public.withdrawal_detail_r24(w2);
          report := concat(report, 'number_len=', length(j->>'account_number'),
                           ' ends_with_last4=', right(j->>'account_number', 4) = j->>'last4',
                           ' still_verified=', j->>'bank_still_verified', ' hold=', j->>'wallet_hold');
        when 'st_paid_noref' then
          perform public.withdrawal_review_r24(w2, true, ' ', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st_paid' then
          j := public.withdrawal_review_r24(w2, true, 'KBANK-20261013-001', null);
          report := concat(report, j->>'status', ' ref=', j->>'transfer_reference', ' reviewer=',
                           j->>'reviewer_name' is not null);
        when 'st_paid_again' then
          j := public.withdrawal_review_r24(w2, true, 'KBANK-20261013-001', null);
          report := concat(report, j->>'status');
        when 'pg_wallet3' then
          report := concat(report, (select 'balance=' || balance || ' hold=' || hold_balance from public.wallets
                                     where profile_id = seller),
                           ' tx=', (select transaction_status from public.wallet_transactions t2
                                      join public.withdraw_requests r on r.wallet_transaction_id = t2.id
                                     where r.id = w2),
                           ' note=[', (select title || ' | ' || message from public.notifications
                                         where event_key = 'withdrawal:' || w2 || ':paid'), ']',
                           ' log=', (select count(*) from public.activity_logs where action = 'finance.withdraw.paid'
                                       and target_id = w2),
                           ' read_log=', (select count(*) from public.activity_logs
                                            where action = 'finance.withdraw.read' and target_id = w2));
        when 's_req3' then
          j := secondhand.request_withdrawal(150.50);
          w3 := (j->>'id')::uuid;
          report := concat(report, j->>'status', ' amount=', j->>'amount');
        when 'st_reject_noreason' then
          perform public.withdrawal_review_r24(w3, false, null, 'x');
          report := concat(report, 'UNEXPECTED_OK');
        when 'st_reject' then
          j := public.withdrawal_review_r24(w3, false, null, 'ชื่อบัญชีไม่ตรงกับผู้ขาย');
          report := concat(report, j->>'status', ' reason=', j->>'reject_reason');
        when 'st_paid_rejected' then
          perform public.withdrawal_review_r24(w3, true, 'REF-2', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_wallet4' then
          report := concat(report, (select 'balance=' || balance || ' hold=' || hold_balance from public.wallets
                                     where profile_id = seller),
                           ' note=[', (select title || ' | ' || message from public.notifications
                                         where event_key = 'withdrawal:' || w3 || ':rejected'), ']');
        when 's_list' then
          j := secondhand.list_my_withdrawals(null, 20);
          report := concat(report, 'n=', jsonb_array_length(j), ' statuses=',
                           (select string_agg(e->>'status', ',') from jsonb_array_elements(j) e));
        when 's_my_page' then
          j := secondhand.get_my_page();
          report := concat(report, 'wallet_keys=', (select string_agg(k, ',' order by k)
                                                     from jsonb_object_keys(j->'wallet') k));
        when 'anon_contents' then
          j := public.get_system_contents('secondhand', 'help');
          report := concat(report, 'help=', jsonb_array_length(j), ' first=', j->0->>'key', ' en=',
                           j->0->'title'->>'en', ' rules=',
                           jsonb_array_length(public.get_system_contents('secondhand', 'rule')));
        when 'st_c_save' then
          j := public.content_save_r24(null, 'secondhand.e2e.sample', 'secondhand', 'guide',
                                       '{"th":"  ทดสอบ  ","en":"Test"}', '{"th":"เนื้อหา","en":""}',
                                       '{"icon":"info"}', 5, true, null);
          c1 := (j->>'id')::uuid;
          report := concat(report, 'v=', j->>'version', ' title_th=[', j->'title'->>'th', '] body_has_en=',
                           j->'body' ? 'en');
        when 'st_c_bad' then
          perform public.content_save_r24(null, 'secondhand.e2e.bad', 'secondhand', 'guide',
                                          '{"en":"Only English"}', '{"th":"x"}', '{}', 0, true, null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st_c_update' then
          j := public.content_save_r24(c1, 'secondhand.e2e.sample', 'secondhand', 'warning',
                                       '{"th":"แก้แล้ว","en":"Edited"}', '{"th":"ใหม่"}', '{}', 6, false, 1);
          report := concat(report, 'v=', j->>'version', ' active=', j->>'is_active', ' category=', j->>'category');
        when 'st_c_stale' then
          perform public.content_save_r24(c1, 'secondhand.e2e.sample', 'secondhand', 'warning',
                                          '{"th":"ซ้ำ"}', '{"th":"ซ้ำ"}', '{}', 6, true, 1);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st_c_keylock' then
          perform public.content_save_r24(c1, 'secondhand.e2e.renamed', 'secondhand', 'warning',
                                          '{"th":"ซ้ำ"}', '{"th":"ซ้ำ"}', '{}', 6, true, 2);
          report := concat(report, 'UNEXPECTED_OK');
        when 'st_c_list' then
          j := public.content_list_r24('secondhand');
          report := concat(report, 'n=', jsonb_array_length(j), ' has_inactive=',
                           exists (select 1 from jsonb_array_elements(j) e where e->>'id' = c1::text
                                     and e->>'is_active' = 'false'));
        when 'st_c_delete' then
          report := concat(report, public.content_delete_r24(c1, 2));
        when 'pg_revisions' then
          report := concat(report, (select string_agg(change_kind || '@' || version, ',' order by id)
                                      from public.system_content_revisions where content_id = c1),
                           ' logs=', (select count(*) from public.activity_logs where target_id = c1));
        when 'anon_after_delete' then
          j := public.get_system_contents('secondhand', null);
          report := concat(report, 'all=', jsonb_array_length(j), ' sample_gone=',
                           not exists (select 1 from jsonb_array_elements(j) e where e->>'key' = 'secondhand.e2e.sample'));
        when 'pg_plain_account' then
          update public.withdraw_requests set account_number = '1234567890' where id = w2;
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_negative' then
          update public.wallets set balance = -1 where profile_id = seller;
          report := concat(report, 'UNEXPECTED_OK');
      end case;
    exception when others then
      report := concat(report, 'ERR ', sqlerrm);
    end;
    report := concat(report, E'\n');
  end loop;
  raise exception 'E2E_REPORT%', E'\n' || report;
end $$;
