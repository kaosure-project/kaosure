-- R22 checks. Appended after the migration inside one transaction that never commits.
do $$
declare
  seller uuid := '9044e32e-24e7-49e2-9aaf-500c48ecce7e';
  buyer uuid := '3bd1dcd3-6ab3-4af5-a83f-2c9883438629';
  seller_session uuid := gen_random_uuid();
  buyer_session uuid := gen_random_uuid();
  cid uuid := 'f56cdf5a-347a-4847-ad0d-f05b580b007c';
  product uuid;
  addr uuid;
  seller_addr uuid;
  o1 uuid;
  o2 uuid;
  o3 uuid;
  o4 uuid;
  report text := '';
  j jsonb;
  n int;
  rpc text;
  step text;
  as_postgres text[] := array['setup', 'pg_block', 'pg_unblock', 'pg_relist', 'pg_fund', 'pg_relist2', 'pg_expire',
    'pg_relist3', 'pg_ship_due', 'pg_timer', 'readback', 'buyer_wallet_after_refund', 'seller_wallet'];
  as_seller text[] := array['seller_own', 'seller_get_pending', 'seller_todo', 'seller_get_paid', 'seller_ship_bad',
    'seller_ship', 'seller_confirm', 'seller_cancel_paid', 'seller_ship4', 'seller_list', 'seller_wallet'];
  as_anon text[] := array['anon_checkout'];
  steps text[] := array['setup', 'guard_rpc', 'buyer_checkout', 'seller_own', 'buyer_bad_address', 'pg_block',
    'buyer_blocked_checkout', 'buyer_blocked_create', 'pg_unblock', 'buyer_create', 'buyer_create_again',
    'seller_get_pending', 'buyer_wallet_short', 'buyer_mock_pay', 'buyer_pay_again', 'seller_todo', 'seller_get_paid',
    'buyer_cancel_paid', 'buyer_ship', 'seller_ship_bad', 'seller_ship', 'seller_confirm', 'buyer_confirm',
    'buyer_review', 'pg_relist', 'pg_fund', 'buyer_create2', 'buyer_wallet_pay', 'seller_cancel_paid',
    'buyer_wallet_after_refund', 'pg_relist2', 'buyer_create3', 'pg_expire', 'pg_relist3', 'buyer_create4',
    'buyer_wallet_pay4', 'seller_ship4', 'pg_ship_due', 'pg_timer', 'seller_wallet', 'buyer_list', 'seller_list',
    'buyer_bad_filter', 'anon_checkout', 'readback'];
begin
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (seller_session, seller, now(), now(), 'aal1'), (buyer_session, buyer, now(), now(), 'aal1');

  foreach step in array steps loop
    begin
      report := concat(report, step, ': ');
      if step = any(as_anon) then
        perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
      else
        perform set_config('request.jwt.claims', json_build_object(
          'sub', case when step = any(as_seller) then seller else buyer end,
          'role', 'authenticated',
          'session_id', case when step = any(as_seller) then seller_session else buyer_session end,
          'aal', 'aal1', 'is_anonymous', false, 'client_id', cid)::text, true);
      end if;
      perform set_config('request.headers', '{"content-profile":"secondhand"}', true);
      perform set_config('request.method', 'POST', true);
      perform set_config('role', case when step = any(as_anon) then 'anon'
                                      when step = any(as_postgres) then 'postgres' else 'authenticated' end, true);

      case step
        when 'setup' then
          select p.id into product
            from public.products p join secondhand.listings l on l.product_id = p.id
           where l.seller_id = seller and secondhand.listing_public_r20d(p.id)
           order by p.price
           limit 1;
          update auth.users set email_confirmed_at = coalesce(email_confirmed_at, now()),
                                phone_confirmed_at = coalesce(phone_confirmed_at, now())
           where id = buyer;
          insert into secondhand.shipping_addresses(profile_id, recipient_name, phone, postal_code, province,
                                                    district, address_line1, address_type)
          values (buyer, 'ผู้ซื้อ ทดสอบ', '812345678', '10110', 'กรุงเทพมหานคร', 'วัฒนา', '1 ถนนสุขุมวิท', 'shipping')
          returning id into addr;
          insert into secondhand.shipping_addresses(profile_id, recipient_name, phone, postal_code, province,
                                                    address_line1, address_type)
          values (seller, 'ผู้ขาย', '898765432', '10200', 'กรุงเทพมหานคร', '2 ถนนพระราม 1', 'shipping')
          returning id into seller_addr;
          report := concat(report, 'product=', product is not null, ' price=',
                           (select price from public.products where id = product));
        when 'guard_rpc' then
          foreach rpc in array array['get_checkout', 'create_order', 'pay_order', 'mark_shipped', 'confirm_received',
                                     'cancel_order', 'get_order', 'list_my_orders'] loop
            perform set_config('request.path', '/rpc/' || rpc, true);
            perform kaoid_private.pre_request_r10d();
          end loop;
          report := concat(report, 'allowed');
        when 'buyer_checkout' then
          j := secondhand.get_checkout(product);
          report := concat(report, 'price=', j->>'price', ' problem=', coalesce(j->>'problem', 'none'), ' mock=',
                           j->>'mock_payment_enabled', ' hours=', j->>'pay_within_hours', ' wallet=',
                           coalesce(j->>'wallet_balance', 'none'));
        when 'seller_own' then
          perform secondhand.create_order(product, seller_addr);
          report := concat(report, 'UNEXPECTED_OK');
        when 'buyer_bad_address' then
          perform secondhand.create_order(product, seller_addr);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_block' then
          insert into public.user_blocks(blocker_profile_id, blocked_profile_id, reason)
          values (seller, buyer, 'e2e')
          on conflict (blocker_profile_id, blocked_profile_id) do update set is_active = true, expires_at = null;
          report := concat(report, 'seller blocked buyer');
        when 'buyer_blocked_checkout' then
          j := secondhand.get_checkout(product);
          report := concat(report, 'problem=', j->>'problem');
        when 'buyer_blocked_create' then
          perform secondhand.create_order(product, addr);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_unblock' then
          update public.user_blocks set is_active = false where blocker_profile_id = seller and blocked_profile_id = buyer;
          report := concat(report, 'unblocked');
        when 'buyer_create' then
          j := secondhand.create_order(product, addr);
          o1 := (j->>'order_id')::uuid;
          perform set_config('role', 'postgres', true);
          report := concat(report, 'number=', left(j->>'order_number', 2), ' total=', j->>'total', ' product=',
                           (select status from public.products where id = product), ' pay_by_h=',
                           round(extract(epoch from ((j->>'pay_by')::timestamptz - now())) / 3600));
        when 'buyer_create_again' then
          perform secondhand.create_order(product, addr);
          report := concat(report, 'UNEXPECTED_OK');
        when 'seller_get_pending' then
          j := secondhand.get_order(o1);
          report := concat(report, 'role=', j->>'role', ' status=', j->>'status', ' address=',
                           coalesce(j->>'address', 'hidden'), ' buyer=', j->'counterpart'->>'display_name');
        when 'buyer_wallet_short' then
          perform secondhand.pay_order(o1, 'wallet');
          report := concat(report, 'UNEXPECTED_OK');
        when 'buyer_mock_pay' then
          j := secondhand.pay_order(o1, 'mock');
          perform set_config('role', 'postgres', true);
          report := concat(report, j->>'status', ' escrow=',
                           (select escrow_status || ' ' || amount from public.escrow_transactions where order_id = o1),
                           ' ship_by_d=', (select round(extract(epoch from (ship_by - now())) / 86400)
                                             from secondhand.order_details where order_id = o1));
        when 'buyer_pay_again' then
          perform secondhand.pay_order(o1, 'mock');
          report := concat(report, 'UNEXPECTED_OK');
        when 'seller_todo' then
          j := secondhand.get_my_page();
          report := concat(report, (select string_agg(t->>'code' || '=' || (t->>'count'), ',')
                                      from jsonb_array_elements(j->'todo') t));
        when 'seller_get_paid' then
          j := secondhand.get_order(o1);
          report := concat(report, 'status=', j->>'status', ' address=', j->'address'->>'recipient_name',
                           ' method=', j->>'payment_method');
        when 'buyer_cancel_paid' then
          perform secondhand.cancel_order(o1);
          report := concat(report, 'UNEXPECTED_OK');
        when 'buyer_ship' then
          perform secondhand.mark_shipped(o1, 'Flash', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'seller_ship_bad' then
          perform secondhand.mark_shipped(o1, '  ', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'seller_ship' then
          j := secondhand.mark_shipped(o1, 'Flash Express', 'TH0001E2E');
          perform set_config('role', 'postgres', true);
          report := concat(report, j->>'status', ' receive_by_d=',
                           (select round(extract(epoch from (receive_by - now())) / 86400)
                              from secondhand.order_details where order_id = o1));
        when 'seller_confirm' then
          perform secondhand.confirm_received(o1);
          report := concat(report, 'UNEXPECTED_OK');
        when 'buyer_confirm' then
          j := secondhand.confirm_received(o1);
          perform set_config('role', 'postgres', true);
          report := concat(report, j->>'status', ' ', (select 'fee=' || marketplace_fee || ' escrow=' || escrow_status
                                                          from public.orders where id = o1),
                           ' seller_wallet=', (select balance from public.wallets where profile_id = seller),
                           ' release=', (select string_agg(pt.transaction_type || ':' || pt.amount || ':' || pt.note, ',')
                                           from public.payment_transactions pt
                                           join public.escrow_transactions e on e.id = pt.escrow_id
                                          where e.order_id = o1 and pt.transaction_type <> 'payment'));
        when 'buyer_review' then
          j := secondhand.submit_review(o1, 'good', 'ส่งไว');
          report := concat(report, j->>'verdict');
        when 'pg_relist' then
          update public.products set status = 'active' where id = product;
          report := concat(report, 'relisted');
        when 'pg_fund' then
          update public.wallets set balance = 50000 where profile_id = buyer;
          report := concat(report, 'buyer wallet 50000');
        when 'buyer_create2' then
          j := secondhand.create_order(product, addr);
          o2 := (j->>'order_id')::uuid;
          report := concat(report, 'ok');
        when 'buyer_wallet_pay' then
          j := secondhand.pay_order(o2, 'wallet');
          perform set_config('role', 'postgres', true);
          report := concat(report, j->>'status', ' buyer_wallet=',
                           (select balance from public.wallets where profile_id = buyer));
        when 'seller_cancel_paid' then
          j := secondhand.cancel_order(o2);
          perform set_config('role', 'postgres', true);
          report := concat(report, j->>'status', ' payment=', (select payment_status from public.orders where id = o2),
                           ' product=', (select status from public.products where id = product));
        when 'buyer_wallet_after_refund' then
          report := concat(report, 'balance=', (select balance from public.wallets where profile_id = buyer), ' tx=',
                           (select string_agg(t.transaction_type, ',' order by t.created_at, t.transaction_type)
                              from public.wallet_transactions t join public.wallets w on w.id = t.wallet_id
                             where w.profile_id = buyer and t.order_id = o2));
        when 'pg_relist2' then
          update public.products set status = 'active' where id = product;
          report := concat(report, 'relisted');
        when 'buyer_create3' then
          j := secondhand.create_order(product, addr);
          o3 := (j->>'order_id')::uuid;
          report := concat(report, 'ok');
        when 'pg_expire' then
          update secondhand.order_details set pay_by = now() - interval '1 minute' where order_id = o3;
          n := secondhand.run_order_timeouts_r22();
          report := concat(report, 'handled=', n, ' status=', (select order_status || '/' || cancel_reason
                                                                 from public.orders where id = o3),
                           ' product=', (select status from public.products where id = product));
        when 'pg_relist3' then
          report := concat(report, 'already ', (select status from public.products where id = product));
        when 'buyer_create4' then
          j := secondhand.create_order(product, addr);
          o4 := (j->>'order_id')::uuid;
          report := concat(report, 'ok');
        when 'buyer_wallet_pay4' then
          j := secondhand.pay_order(o4, 'wallet');
          report := concat(report, j->>'status');
        when 'seller_ship4' then
          j := secondhand.mark_shipped(o4, 'Kerry', null);
          report := concat(report, j->>'status');
        when 'pg_ship_due' then
          update secondhand.order_details set receive_by = now() - interval '1 minute' where order_id = o4;
          report := concat(report, 'due');
        when 'pg_timer' then
          n := secondhand.run_order_timeouts_r22();
          report := concat(report, 'handled=', n, ' status=', (select order_status || ' fee=' || marketplace_fee
                                                                 from public.orders where id = o4));
        when 'seller_wallet' then
          report := concat(report, 'balance=', (select balance from public.wallets where profile_id = seller),
                           ' sale=', (select string_agg(amount::text, ',') from public.wallet_transactions t
                                        join public.wallets w on w.id = t.wallet_id
                                       where w.profile_id = seller and t.transaction_type = 'sale'));
        when 'buyer_list' then
          j := secondhand.list_my_orders('buyer');
          report := concat(report, 'n=', jsonb_array_length(j->'orders'), ' statuses=',
                           (select string_agg(o->>'status', ',') from jsonb_array_elements(j->'orders') o));
        when 'seller_list' then
          j := secondhand.list_my_orders('seller', null, 2);
          report := concat(report, 'n=', jsonb_array_length(j->'orders'), ' more=', j->>'has_more');
        when 'buyer_bad_filter' then
          perform secondhand.list_my_orders('everyone');
          report := concat(report, 'UNEXPECTED_OK');
        when 'anon_checkout' then
          perform secondhand.get_checkout(product);
          report := concat(report, 'UNEXPECTED_OK');
        when 'readback' then
          report := concat(report, 'history=', (select count(*) from public.order_status_history where order_id = o1),
                           ' events=', (select string_agg(event_type, ',' order by created_at, event_type)
                                          from public.order_events where order_id = o1),
                           ' notes=', (select count(*) from public.notifications where target_id in (o1, o2, o3, o4)),
                           ' offers_cancelled_ok=', not exists (select 1 from secondhand.price_offers
                                                                  where order_id = o1 and status <> 'used'));
      end case;
    exception when others then
      report := concat(report, 'ERR ', sqlerrm);
    end;
    report := concat(report, E'\n');
  end loop;
  raise exception 'E2E_REPORT%', E'\n' || report;
end $$;
