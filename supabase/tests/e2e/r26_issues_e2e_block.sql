-- R26 checks: cancel rules, problem reports with escrow hold, staff decisions and the Kao ID sign-out return. Appended inside one transaction that never commits.
do $$
declare
  seller uuid := '9044e32e-24e7-49e2-9aaf-500c48ecce7e';
  buyer uuid := '3bd1dcd3-6ab3-4af5-a83f-2c9883438629';
  staff uuid := gen_random_uuid();
  seller_session uuid := gen_random_uuid();
  buyer_session uuid := gen_random_uuid();
  staff_session uuid := gen_random_uuid();
  cid uuid := 'f56cdf5a-347a-4847-ad0d-f05b580b007c';
  p1 uuid;
  pb uuid;
  pc uuid;
  pd uuid;
  addr uuid;
  oa uuid;
  ob uuid;
  oc uuid;
  od uuid;
  ic uuid;
  id_ uuid;
  buyer_before numeric;
  report text := '';
  j jsonb;
  n int;
  t text;
  who uuid;
  sess uuid;
  step text;
  as_postgres text[] := array['setup', 'pg_overdue', 'pg_a_after', 'pg_b_opened', 'pg_b_auto', 'pg_b_after_withdraw',
                              'pg_b_after_cancel', 'pg_c_after_dismiss', 'pg_c_after_release', 'pg_d_after'];
  as_seller text[] := array['s_ship_b', 's_get_b', 's_my_page', 's_issue_seller', 's_cancel_b', 's_ship_c', 's_ship_d'];
  as_staff text[] := array['st_tools', 'st_queue', 'st_detail', 'st_nonote', 'st_dismiss', 'st_release', 'st_refund',
                           'st_queue_closed'];
  as_anon text[] := array['anon_logout'];
  steps text[] := array['setup', 'guard_rpc', 'guard_staff_blocked',
    'b_create_a', 'b_pay_a', 'b_cancel_a_early', 'b_get_a', 'pg_overdue', 'b_get_a2', 'b_cancel_a', 'pg_a_after',
    'b_create_b', 'b_pay_b', 's_ship_b', 'b_cancel_b', 'b_issue_bad_kind', 'b_issue_noreason', 'b_issue_b',
    'b_issue_b_again', 'pg_b_opened', 's_get_b', 's_my_page', 's_issue_seller', 'pg_b_auto', 'b_withdraw_b',
    'pg_b_after_withdraw', 'b_withdraw_b_again', 'b_issue_b2', 's_cancel_b', 'pg_b_after_cancel',
    'b_create_c', 'b_pay_c', 's_ship_c', 'b_issue_c', 'b_direct_insert', 'b_resolve', 'st_tools', 'st_queue',
    'st_detail', 'st_nonote', 'st_dismiss', 'pg_c_after_dismiss', 'b_issue_c2', 'st_release', 'pg_c_after_release',
    'b_create_d', 'b_pay_d', 's_ship_d', 'b_issue_d', 'st_refund', 'pg_d_after', 'st_queue_closed', 'anon_logout'];
begin
  insert into auth.users(id, instance_id, aud, role, email, email_confirmed_at, phone, phone_confirmed_at,
                         raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_anonymous)
  values (staff, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'e2e-r26-' || left(staff::text, 8) || '@example.invalid', now(), '66800000096', now(),
          '{"provider":"email","providers":["email"]}', '{}', now(), now(), false);
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (seller_session, seller, now(), now(), 'aal1'), (buyer_session, buyer, now(), now(), 'aal1'),
         (staff_session, staff, now(), now(), 'aal1');
  -- Only one company owner may exist: the rolled-back run makes the new account the owner so staff is neither side.
  update public.company_owners set profile_id = staff;

  foreach step in array steps loop
    begin
      report := concat(report, step, ': ');
      who := case when step = any(as_seller) then seller when step = any(as_staff) then staff else buyer end;
      sess := case when step = any(as_seller) then seller_session when step = any(as_staff) then staff_session
                   else buyer_session end;
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
          select p.id into p1
            from public.products p join secondhand.listings l on l.product_id = p.id
           where l.seller_id = seller and secondhand.listing_public_r20d(p.id)
           order by p.price, p.id limit 1;
          -- Rolled-back copies of the seller's listing give one item per order.
          foreach t in array array['b', 'c', 'd'] loop
            j := jsonb_build_object('id', gen_random_uuid());
            insert into public.products
            select (jsonb_populate_record(null::public.products, to_jsonb(p) || j || jsonb_build_object(
                      'slug', p.slug || '-e2e-r26' || t, 'product_code', p.product_code || '-E2E' || upper(t)))).*
              from public.products p where p.id = p1;
            insert into secondhand.listings
            select (jsonb_populate_record(null::secondhand.listings,
                                          to_jsonb(l) || jsonb_build_object('product_id', j->>'id'))).*
              from secondhand.listings l where l.product_id = p1;
            insert into public.product_images
            select (jsonb_populate_record(null::public.product_images, to_jsonb(i) || jsonb_build_object(
                      'id', gen_random_uuid(), 'product_id', j->>'id'))).*
              from public.product_images i where i.product_id = p1;
            case t when 'b' then pb := (j->>'id')::uuid; when 'c' then pc := (j->>'id')::uuid;
                   else pd := (j->>'id')::uuid; end case;
          end loop;
          update auth.users set email_confirmed_at = coalesce(email_confirmed_at, now()),
                                phone_confirmed_at = coalesce(phone_confirmed_at, now())
           where id = buyer;
          insert into secondhand.shipping_addresses(profile_id, recipient_name, phone, postal_code, province,
                                                    district, address_line1, address_type)
          values (buyer, 'Buyer A', '812345678', '10110', 'Bangkok', 'Watthana', '1 Sukhumvit', 'shipping')
          returning id into addr;
          insert into public.wallets(profile_id) values (buyer), (seller) on conflict (profile_id) do nothing;
          update public.wallets set balance = 1000000 where profile_id = buyer;
          buyer_before := 1000000;
          report := concat(report, 'p1=', p1 is not null, ' copies_public=',
                           secondhand.listing_public_r20d(pb) and secondhand.listing_public_r20d(pc)
                             and secondhand.listing_public_r20d(pd),
                           ' perm=', exists (select 1 from public.permissions where code = 'marketplace.orders.resolve'),
                           ' seeds=', (select count(*) from public.system_contents
                                        where content_key like 'secondhand.notice.order_issue_%'
                                           or content_key in ('secondhand.order.cancel_rules', 'secondhand.order.issue_guide')));
        when 'guard_rpc' then
          foreach t in array array['open_order_issue', 'withdraw_order_issue', 'cancel_order', 'get_order'] loop
            perform set_config('request.path', '/rpc/' || t, true);
            perform kaoid_private.pre_request_r10d();
          end loop;
          report := concat(report, 'allowed');
        when 'guard_staff_blocked' then
          perform set_config('request.headers', '{"content-profile":"public"}', true);
          foreach t in array array['order_issue_queue_r26', 'order_issue_detail_r26', 'order_issue_resolve_r26'] loop
            begin
              perform set_config('request.path', '/rpc/' || t, true);
              perform kaoid_private.pre_request_r10d();
              report := concat(report, t, '=UNEXPECTED_OK ');
            exception when others then
              report := concat(report, t, '=blocked ');
            end;
          end loop;

        -- A: the seller misses the shipping deadline; the buyer cancels and is refunded.
        when 'b_create_a' then
          oa := (secondhand.create_order(p1, addr)->>'order_id')::uuid;
          report := concat(report, 'ok');
        when 'b_pay_a' then
          j := secondhand.pay_order(oa, 'wallet');
          report := concat(report, j->>'status', ' wallet=', (select balance from public.wallets where profile_id = buyer));
        when 'b_cancel_a_early' then
          perform secondhand.cancel_order(oa);
          report := concat(report, 'UNEXPECTED_OK');
        when 'b_get_a' then
          j := secondhand.get_order(oa);
          report := concat(report, 'can_cancel=', j->>'can_cancel', ' can_open_issue=', j->>'can_open_issue',
                           ' issue=', coalesce(j->>'issue', '-'));
        when 'pg_overdue' then
          update secondhand.order_details set ship_by = now() - interval '1 minute' where order_id = oa;
          report := concat(report, 'ok');
        when 'b_get_a2' then
          j := secondhand.get_order(oa);
          report := concat(report, 'can_cancel=', j->>'can_cancel');
        when 'b_cancel_a' then
          j := secondhand.cancel_order(oa);
          report := concat(report, j->>'status');
        when 'pg_a_after' then
          report := concat(report, (select order_status || '/' || payment_status || '/' || escrow_status
                                             || ' reason=' || cancel_reason from public.orders where id = oa),
                           ' by=', (select cancelled_by from secondhand.order_details where order_id = oa),
                           ' item=', (select status from public.products where id = p1),
                           ' buyer_delta=', (select balance from public.wallets where profile_id = buyer) - buyer_before,
                           ' refund_tx=', (select count(*) from public.wallet_transactions
                                            where order_id = oa and transaction_type = 'refund'),
                           E'\n  note_seller=[', (select message from public.notifications
                                                   where event_key = 'order_cancelled:' || oa || ':' || seller), ']');

        -- B: a report holds the money; the buyer withdraws it, reports again, and the seller cancels after shipping.
        when 'b_create_b' then
          ob := (secondhand.create_order(pb, addr)->>'order_id')::uuid;
          report := concat(report, 'ok');
        when 'b_pay_b' then
          j := secondhand.pay_order(ob, 'wallet');
          report := concat(report, j->>'status');
        when 's_ship_b' then
          j := secondhand.mark_shipped(ob, 'Kerry', 'KER-R26-B');
          report := concat(report, j->>'status');
        when 'b_cancel_b' then
          perform secondhand.cancel_order(ob);
          report := concat(report, 'UNEXPECTED_OK');
        when 'b_issue_bad_kind' then
          perform secondhand.open_order_issue(ob, 'refund_now', 'อยากได้เงินคืน');
          report := concat(report, 'UNEXPECTED_OK');
        when 'b_issue_noreason' then
          perform secondhand.open_order_issue(ob, 'not_as_described', ' แตก ');
          report := concat(report, 'UNEXPECTED_OK');
        when 'b_issue_b' then
          j := secondhand.open_order_issue(ob, 'not_arrived', null);
          report := concat(report, j->>'kind', '/', j->>'status');
        when 'b_issue_b_again' then
          perform secondhand.open_order_issue(ob, 'not_arrived', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_b_opened' then
          report := concat(report, 'escrow=', (select e.escrow_status from public.escrow_transactions e
                                                 join secondhand.order_details d on d.escrow_id = e.id
                                                where d.order_id = ob),
                           ' events=', (select count(*) from public.order_events
                                         where order_id = ob and event_type = 'dispute_opened'),
                           E'\n  note_seller=[', (select title || ' | ' || message from public.notifications
                                                   where profile_id = seller and notification_type = 'order_issue'
                                                     and target_id = ob), ']');
        when 's_get_b' then
          j := secondhand.get_order(ob);
          report := concat(report, 'issue=', j->'issue'->>'kind', '/', j->'issue'->>'status',
                           ' can_cancel=', j->>'can_cancel', ' can_open_issue=', j->>'can_open_issue');
        when 's_my_page' then
          j := secondhand.get_my_page();
          report := concat(report, 'first_todo=', j->'todo'->0->>'code', ' count=', j->'todo'->0->>'count',
                           ' order=', j->'todo'->0->>'order_id' = ob::text);
        when 's_issue_seller' then
          perform secondhand.open_order_issue(ob, 'not_arrived', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_b_auto' then
          update secondhand.order_details set receive_by = now() - interval '1 minute' where order_id = ob;
          n := secondhand.run_order_timeouts_r22();
          report := concat(report, 'status=', (select order_status from public.orders where id = ob));
        when 'b_withdraw_b' then
          j := secondhand.withdraw_order_issue(ob);
          report := concat(report, j->>'status');
        when 'pg_b_after_withdraw' then
          report := concat(report, 'escrow=', (select e.escrow_status from public.escrow_transactions e
                                                 join secondhand.order_details d on d.escrow_id = e.id
                                                where d.order_id = ob),
                           ' receive_by>2d=', (select receive_by > now() + interval '2 days'
                                                 from secondhand.order_details where order_id = ob),
                           ' note=[', (select message from public.notifications
                                        where profile_id = seller and notification_type = 'order_issue'
                                          and event_key like '%:withdrawn:%' and target_id = ob), ']');
        when 'b_withdraw_b_again' then
          perform secondhand.withdraw_order_issue(ob);
          report := concat(report, 'UNEXPECTED_OK');
        when 'b_issue_b2' then
          j := secondhand.open_order_issue(ob, 'cancel_request', 'เปลี่ยนใจ ขอยกเลิกได้ไหมครับ');
          report := concat(report, j->>'kind', '/', j->>'status');
        when 's_cancel_b' then
          j := secondhand.cancel_order(ob);
          report := concat(report, j->>'status');
        when 'pg_b_after_cancel' then
          report := concat(report, (select order_status || '/' || escrow_status from public.orders where id = ob),
                           ' by=', (select cancelled_by from secondhand.order_details where order_id = ob),
                           ' issues=', (select string_agg(issue_status || ':' || (resolved_by = seller)::text, ','
                                                         order by created_at)
                                          from secondhand.order_issues where order_id = ob),
                           ' item=', (select status from public.products where id = pb),
                           ' escrow_tx=', (select e.escrow_status from public.escrow_transactions e
                                             join secondhand.order_details d on d.escrow_id = e.id
                                            where d.order_id = ob),
                           ' buyer_delta=', (select balance from public.wallets where profile_id = buyer) - buyer_before,
                           E'\n  note_buyer=[', (select message from public.notifications
                                                  where event_key = 'order_cancelled:' || ob || ':' || buyer), ']');

        -- C: staff dismiss the first report, then release the money on the second (mock payment).
        when 'b_create_c' then
          oc := (secondhand.create_order(pc, addr)->>'order_id')::uuid;
          report := concat(report, 'ok');
        when 'b_pay_c' then
          j := secondhand.pay_order(oc, 'mock');
          report := concat(report, j->>'status');
        when 's_ship_c' then
          j := secondhand.mark_shipped(oc, 'Flash', null);
          report := concat(report, j->>'status');
        when 'b_issue_c' then
          j := secondhand.open_order_issue(oc, 'not_as_described', 'สินค้ามีรอยแตก ไม่ตรงกับรูป');
          ic := (j->>'id')::uuid;
          report := concat(report, j->>'status');
        when 'b_direct_insert' then
          insert into secondhand.order_issues(order_id, opened_by, kind) values (oc, buyer, 'not_arrived');
          report := concat(report, 'UNEXPECTED_OK');
        when 'b_resolve' then
          perform public.order_issue_resolve_r26(ic, 'refund', 'ขอเงินคืน');
          report := concat(report, 'UNEXPECTED_OK');
        when 'st_tools' then
          j := public.staff_tools_r24();
          report := concat(report, 'order_issues=', j->>'order_issues', ' open>=1=', (j->>'open_order_issues')::int >= 1);
        when 'st_queue' then
          j := public.order_issue_queue_r26('open', null);
          report := concat(report, 'has_c=', j @> jsonb_build_array(jsonb_build_object('id', ic)),
                           ' item=', (select concat(e->'order'->>'order_number' is not null, ' escrow=',
                                                    e->'order'->>'escrow_status', ' buyer=',
                                                    e->'buyer'->>'display_name' is not null)
                                        from jsonb_array_elements(j) e where e->>'id' = ic::text));
        when 'st_detail' then
          j := public.order_issue_detail_r26(ic);
          report := concat(report, 'events=', jsonb_array_length(j->'events'), ' history=', jsonb_array_length(j->'history'),
                           ' seller=', j->'seller'->>'display_name' is not null);
        when 'st_nonote' then
          perform public.order_issue_resolve_r26(ic, 'dismiss', ' ');
          report := concat(report, 'UNEXPECTED_OK');
        when 'st_dismiss' then
          j := public.order_issue_resolve_r26(ic, 'dismiss', 'ภาพถ่ายยืนยันว่าสินค้าตรงตามประกาศ');
          report := concat(report, j->>'status', ' order=', j->'order'->>'status', ' escrow=', j->'order'->>'escrow_status');
        when 'pg_c_after_dismiss' then
          report := concat(report, 'receive_by>6d=', (select receive_by > now() + interval '6 days'
                                                        from secondhand.order_details where order_id = oc),
                           ' log=', (select count(*) from public.activity_logs
                                      where action = 'marketplace.order_issue.dismiss' and target_id = ic),
                           ' notes=', (select count(*) from public.notifications
                                        where event_key like 'order_issue:' || ic || ':dismissed:%'),
                           E'\n  note_buyer=[', (select title || ' | ' || message from public.notifications
                                                  where event_key = 'order_issue:' || ic || ':dismissed:' || buyer), ']');
        when 'b_issue_c2' then
          j := secondhand.open_order_issue(oc, 'not_arrived', null);
          ic := (j->>'id')::uuid;
          report := concat(report, j->>'status');
        when 'st_release' then
          j := public.order_issue_resolve_r26(ic, 'release', 'ขนส่งยืนยันว่าส่งถึงผู้รับแล้ว');
          report := concat(report, j->>'status', ' order=', j->'order'->>'status');
        when 'pg_c_after_release' then
          report := concat(report, (select order_status || '/' || escrow_status from public.orders where id = oc),
                           ' escrow_tx=', (select e.escrow_status from public.escrow_transactions e
                                             join secondhand.order_details d on d.escrow_id = e.id
                                            where d.order_id = oc),
                           ' issues=', (select string_agg(issue_status, ',' order by created_at)
                                          from secondhand.order_issues where order_id = oc),
                           E'\n  note_seller=[', (select message from public.notifications
                                                   where event_key = 'order_issue:' || ic || ':released:' || seller), ']');

        -- D: staff refund the buyer.
        when 'b_create_d' then
          od := (secondhand.create_order(pd, addr)->>'order_id')::uuid;
          report := concat(report, 'ok');
        when 'b_pay_d' then
          j := secondhand.pay_order(od, 'wallet');
          report := concat(report, j->>'status');
        when 's_ship_d' then
          j := secondhand.mark_shipped(od, 'Kerry', 'KER-R26-D');
          report := concat(report, j->>'status');
        when 'b_issue_d' then
          j := secondhand.open_order_issue(od, 'not_as_described', 'กล่องบุบ สินค้าข้างในแตก');
          id_ := (j->>'id')::uuid;
          report := concat(report, j->>'status');
        when 'st_refund' then
          j := public.order_issue_resolve_r26(id_, 'refund', 'รูปถ่ายยืนยันว่าสินค้าเสียหาย');
          report := concat(report, j->>'status', ' order=', j->'order'->>'status');
        when 'pg_d_after' then
          report := concat(report, (select order_status || '/' || escrow_status || ' reason=' || cancel_reason
                                      from public.orders where id = od),
                           ' by=', (select cancelled_by from secondhand.order_details where order_id = od),
                           ' item=', (select status from public.products where id = pd),
                           ' buyer_delta=', (select balance from public.wallets where profile_id = buyer) - buyer_before,
                           ' log=', (select count(*) from public.activity_logs
                                      where action = 'marketplace.order_issue.refund' and target_id = id_),
                           E'\n  note_buyer_cancel=[', (select message from public.notifications
                                                         where event_key = 'order_cancelled:' || od || ':' || buyer), ']',
                           E'\n  note_buyer_issue=[', (select message from public.notifications
                                                        where event_key = 'order_issue:' || id_ || ':refunded:' || buyer), ']');
        when 'st_queue_closed' then
          j := public.order_issue_queue_r26('closed', null);
          report := concat(report, 'has_d=', j @> jsonb_build_array(jsonb_build_object('id', id_)),
                           ' has_c=', j @> jsonb_build_array(jsonb_build_object('id', ic)),
                           ' open_has_d=', public.order_issue_queue_r26('open', null)
                                             @> jsonb_build_array(jsonb_build_object('id', id_)));
        when 'anon_logout' then
          report := concat(report,
            'app=', public.kao_id_sign_out_return_ok('http://localhost:7357/'),
            ' app_path=', public.kao_id_sign_out_return_ok('http://localhost:7357/my-page'),
            ' query=', public.kao_id_sign_out_return_ok('http://localhost:7357/?x=1'),
            ' fragment=', public.kao_id_sign_out_return_ok('http://localhost:7357/#a'),
            ' other_port=', public.kao_id_sign_out_return_ok('http://localhost:7358/'),
            ' lookalike=', public.kao_id_sign_out_return_ok('http://localhost:7357.evil.test/'),
            ' userinfo=', public.kao_id_sign_out_return_ok('http://evil.test@localhost:7357/'),
            ' evil=', public.kao_id_sign_out_return_ok('https://evil.test/'),
            ' js=', public.kao_id_sign_out_return_ok('javascript:alert(1)'),
            ' null=', public.kao_id_sign_out_return_ok(null));
      end case;
    exception when others then
      report := concat(report, 'ERR ', sqlerrm);
    end;
    report := concat(report, E'\n');
  end loop;
  raise exception 'E2E_REPORT%', E'\n' || report;
end $$;
