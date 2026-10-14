-- S1 golden journey: two brand-new members go from sign-up to a verified seller, a sale paid from the wallet,
-- receipt with reviews, a withdrawal paid by staff, and a second sale paid with the mock gateway.
-- Steps named pg_* stand in for Supabase Auth / Storage (confirming email and phone, uploading files)
-- or for a wallet deposit, which has no app path yet. Everything runs in one transaction that never commits.
do $$
declare
  seller uuid := gen_random_uuid();
  buyer uuid := gen_random_uuid();
  staff uuid := gen_random_uuid();
  seller_session uuid := gen_random_uuid();
  buyer_session uuid := gen_random_uuid();
  staff_session uuid := gen_random_uuid();
  cid uuid := 'f56cdf5a-347a-4847-ad0d-f05b580b007c';
  doc uuid := gen_random_uuid();
  bank uuid := gen_random_uuid();
  photo_set text := 'e2e' || left(replace(gen_random_uuid()::text, '-', ''), 8);
  cat uuid;
  other uuid;
  pink uuid := gen_random_uuid();
  pid text;
  total int;
  digit int;
  p1 uuid;
  p2 uuid;
  shop uuid;
  addr uuid;
  o1 uuid;
  o2 uuid;
  w1 uuid;
  req uuid;
  fv uuid;
  seller_mark numeric;
  report text := '';
  j jsonb;
  ok boolean;
  t text;
  who uuid;
  sess uuid;
  step text;
  kao_steps text[] := array['s_kyc_submit', 's_issue_early', 's_issue', 's_bank_submit', 't_kyc_queue', 't_kyc_approve', 't_bank_queue',
                            't_bank_approve', 't_withdraw_queue', 't_withdraw_paid', 't_tools', 'b_pink_submit',
                            't_pink_approve'];
  as_postgres text[] := array['setup', 'pg_unit_docs', 'pg_confirm', 'pg_upload_kyc', 'pg_after_kyc', 'pg_bank_request',
                              'pg_verified', 'pg_photos', 'pg_upload_pink', 'pg_pink_request', 'pg_after_pink',
                              'pg_fund', 'pg_after_pay', 'pg_after_receive', 'pg_after_request', 'pg_after_paid',
                              'pg_mark', 'pg_after_mock', 'pg_notifications', 'pg_invariants'];
  as_seller text[] := array['s_status0', 's_list_early', 's_status1', 's_kyc_submit', 's_issue_early', 's_issue',
                            's_status_no_bank', 's_list_no_bank',
                            's_bank_submit', 's_status2',
                            's_list', 's_my_page', 's_ship1', 's_review_back', 's_withdraw_info', 's_withdraw_big',
                            's_withdraw', 's_list2', 's_ship2'];
  as_staff text[] := array['t_kyc_queue', 't_kyc_approve', 't_bank_queue', 't_bank_approve', 't_withdraw_queue',
                           't_withdraw_paid', 't_tools', 't_pink_approve'];
  as_anon text[] := array['anon_detail'];
  steps text[] := array['setup', 'pg_unit_docs', 's_status0', 's_list_early', 'b_checkout_early', 'pg_confirm', 's_status1',
    'pg_upload_kyc', 's_kyc_submit', 't_kyc_queue', 't_kyc_approve', 'pg_after_kyc', 's_issue_early', 's_status_no_bank', 's_list_no_bank', 's_bank_submit', 'pg_bank_request', 't_bank_queue',
    't_bank_approve', 's_issue', 'pg_verified', 'pg_upload_pink', 'b_pink_submit', 'pg_pink_request',
    't_pink_approve', 'pg_after_pink', 's_status2', 'pg_photos', 's_list', 'anon_detail', 'b_checkout', 'pg_fund',
    'b_order1', 'b_pay1', 'pg_after_pay', 's_my_page', 's_ship1', 'b_receive1', 'pg_after_receive', 's_review_back',
    'b_reviews', 's_withdraw_info', 's_withdraw_big', 's_withdraw', 'pg_after_request', 't_tools',
    't_withdraw_queue', 't_withdraw_paid', 'pg_after_paid', 's_list2', 'b_order2', 'pg_mark', 'b_pay2', 's_ship2', 'b_receive2',
    'pg_after_mock', 'pg_notifications', 'pg_invariants'];
begin
  -- Sign-up as Supabase Auth does it: email and phone not confirmed yet.
  insert into auth.users(id, instance_id, aud, role, email, phone, raw_app_meta_data, raw_user_meta_data,
                         created_at, updated_at, is_anonymous)
  values (seller, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'e2e-s1-seller-' || left(seller::text, 8) || '@example.invalid', null,
          '{"provider":"email","providers":["email"]}', '{"display_name":"Golden Seller"}', now(), now(), false),
         (buyer, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'e2e-s1-buyer-' || left(buyer::text, 8) || '@example.invalid', null,
          '{"provider":"email","providers":["email"]}', '{"display_name":"Golden Buyer"}', now(), now(), false),
         (staff, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'e2e-s1-staff-' || left(staff::text, 8) || '@example.invalid', null,
          '{"provider":"email","providers":["email"]}', '{}', now(), now(), false);
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (seller_session, seller, now(), now(), 'aal1'), (buyer_session, buyer, now(), now(), 'aal1'),
         (staff_session, staff, now(), now(), 'aal1');
  -- Only one company owner may exist: the rolled-back run makes the new staff account the owner.
  update public.company_owners set profile_id = staff;

  foreach step in array steps loop
    begin
      report := concat(report, step, ': ');
      who := case when step = any(as_seller) then seller when step = any(as_staff) then staff else buyer end;
      sess := case when step = any(as_seller) then seller_session when step = any(as_staff) then staff_session
                   else buyer_session end;
      if step = any(as_anon) then
        perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
      elsif step = any(kao_steps) then
        perform set_config('request.jwt.claims', json_build_object(
          'sub', who, 'role', 'authenticated', 'session_id', sess, 'aal', 'aal1', 'is_anonymous', false)::text, true);
      else
        perform set_config('request.jwt.claims', json_build_object(
          'sub', who, 'role', 'authenticated', 'session_id', sess,
          'aal', 'aal1', 'is_anonymous', false, 'client_id', cid)::text, true);
      end if;
      perform set_config('request.headers', case when step = any(kao_steps) then '{"content-profile":"public"}'
                                                 else '{"content-profile":"secondhand"}' end, true);
      perform set_config('request.method', 'POST', true);
      perform set_config('role', case when step = any(as_anon) then 'anon'
                                      when step = any(as_postgres) then 'postgres' else 'authenticated' end, true);

      case step
        when 'setup' then
          select id into cat from public.categories where is_active order by sort_order nulls last, name limit 1;
          select l.product_id into other from secondhand.listings l
           where secondhand.listing_public_r20d(l.product_id) limit 1;
          report := concat(report, 'profiles=', (select count(*) from public.profiles where id in (seller, buyer, staff)),
                           ' verifications=', (select count(*) from public.verifications where profile_id in (seller, buyer)),
                           ' wallets=', (select count(*) from public.wallets where profile_id in (seller, buyer)));

        -- Sign-up done, nothing verified: no listing, no buying.
        when 's_status0' then
          j := secondhand.get_seller_status();
          report := concat(report, j::text);
        when 's_list_early' then
          perform secondhand.create_listing(cat, 'กล้องก่อนยืนยัน', 'ยังไม่ยืนยันตัวตน ลงขายไม่ได้', 3::smallint, 1500,
                                            array[seller || '/x/1.jpg'], 'seller', 'thailand_post_registered', 250,
                                            10::smallint, '1_2');
          report := concat(report, 'UNEXPECTED_OK');
        when 'b_checkout_early' then
          j := secondhand.get_checkout(other);
          report := concat(report, 'problem_for_unconfirmed=', coalesce(j->>'problem', 'none'));

        -- Supabase Auth confirms the email link and the SMS code.
        when 'pg_confirm' then
          update auth.users set email_confirmed_at = now(), phone = '6680' || lpad((random() * 1e7)::int::text, 7, '0'),
                                phone_confirmed_at = now()
           where id in (seller, buyer);
          report := concat(report, 'ok verifications_synced=',
                           (select bool_and(email_verified and phone_verified) from public.verifications
                             where profile_id in (seller, buyer)));
        when 's_status1' then
          j := secondhand.get_seller_status();
          report := concat(report, j::text);

        -- Kao ID: Thai ID card (front/back) reviewed by staff, then the bank account in the same name.
        when 'pg_upload_kyc' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          values ('identity-documents', seller || '/national-id/' || doc || '/front.jpg', seller::text,
                  '{"size": 120000, "mimetype": "image/jpeg"}'),
                 ('identity-documents', seller || '/national-id/' || doc || '/back.jpg', seller::text,
                  '{"size": 110000, "mimetype": "image/jpeg"}'),
                 ('identity-documents', seller || '/bank-account/' || bank || '/evidence.jpg', seller::text,
                  '{"size": 90000, "mimetype": "image/jpeg"}');
          report := concat(report, 'ok');
        when 's_kyc_submit' then
          perform public.submit_national_id_r16a(doc, '1101700230701', 'สมชาย ทดสอบระบบ', date '2020-01-01',
                                                 date '2030-01-01', seller || '/national-id/' || doc || '/front.jpg',
                                                 seller || '/national-id/' || doc || '/back.jpg',
                                                 '99/1 ถนนสุขุมวิท', 'คลองเตยเหนือ', 'วัฒนา', 'กรุงเทพมหานคร', '10110');
          select id into req from public.verification_requests where document_id = doc;
          report := concat(report, 'request=', req is not null);
        when 't_kyc_queue' then
          j := to_jsonb(public.kyc_review_queue_r7c());
          report := concat(report, 'has_request=', position(req::text in j::text) > 0);
        when 't_kyc_approve' then
          ok := public.kyc_review_decision_r7c(req, true, null);
          report := concat(report, 'decided=', ok);
        when 'pg_after_kyc' then
          report := concat(report, 'kyc=', kaoid_private.kyc_status_r18(seller),
                           ' doc=', (select status from public.identity_documents where id = doc),
                           ' kao_id=', (select string_agg(status, ',') from public.kao_id_identities
                                         where profile_id = seller and organization_id is null));
        when 's_issue_early' then
          report := concat(report, 'same_kao_id=',
                           public.issue_kao_id(seller) = (select kao_id from public.kao_id_identities where profile_id = seller));
        when 's_status_no_bank' then
          j := secondhand.get_seller_status();
          report := concat(report, 'kao_id=', j->>'kao_id', ' bank=', j->>'bank', ' can_list=', j->>'can_list');
        when 's_list_no_bank' then
          perform secondhand.create_listing(cat, 'กล้องก่อนผูกธนาคาร', 'มี Kao ID แต่ยังไม่ผูกบัญชีธนาคาร', 3::smallint, 1500,
                                            array[seller || '/x/1.jpg'], 'seller', 'thailand_post_registered', 250,
                                            10::smallint, '1_2');
          report := concat(report, 'UNEXPECTED_OK');
        when 's_issue' then
          report := concat(report, 'kao_id_issued=', public.issue_kao_id(seller) is not null);

        -- Buyer: a Thai pink card is a permanent document with a 13-digit PID, so it grants a Kao ID.
        when 'pg_unit_docs' then
          report := concat(report,
            'thai_id=', kaoid_private.primary_identity_r27a('thai_national_id', null, null),
            ' passport=', kaoid_private.primary_identity_r27a('passport', 'JPN', null),
            ' pink=', kaoid_private.primary_identity_r27a('residence_card', 'THA', 'pink_card'),
            ' alien_cert=', kaoid_private.primary_identity_r27a('residence_card', 'THA', 'residence_certificate'),
            ' work_permit=', kaoid_private.primary_identity_r27a('residence_card', 'THA', 'work_permit'),
            ' tr13=', kaoid_private.primary_identity_r27a('residence_card', 'THA', 'house_registration_tr13'),
            ' foreign_zairyu=', kaoid_private.primary_identity_r27a('residence_card', 'Japan', null));
        when 'pg_upload_pink' then
          pid := '6' || lpad((floor(random() * 1e11))::bigint::text, 11, '0');
          total := 0;
          for digit in 1..12 loop total := total + substr(pid, digit, 1)::int * (14 - digit); end loop;
          pid := pid || ((11 - total % 11) % 10)::text;
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          values ('identity-documents', buyer || '/residence/' || pink || '/front.jpg', buyer::text,
                  '{"size": 120000, "mimetype": "image/jpeg"}'),
                 ('identity-documents', buyer || '/residence/' || pink || '/back.jpg', buyer::text,
                  '{"size": 110000, "mimetype": "image/jpeg"}');
          report := concat(report, 'ok');
        when 'b_pink_submit' then
          perform public.submit_thai_foreign_document_r16b(pink, 'pink_card', pid, 'Aung', 'Min', false, false, 'MMR',
                                                           'card', false, date '2022-01-01', date '2032-01-01',
                                                           buyer || '/residence/' || pink || '/front.jpg',
                                                           buyer || '/residence/' || pink || '/back.jpg',
                                                           '12/3 ถนนพระรามสี่', 'คลองเตย', 'คลองเตย', 'กรุงเทพมหานคร', '10110');
          report := concat(report, 'ok');
        when 'pg_pink_request' then
          select id into req from public.verification_requests where document_id = pink;
          report := concat(report, 'request=', req is not null);
        when 't_pink_approve' then
          report := concat(report, 'decided=', public.kyc_review_decision_r7c(req, true, null));
        when 'pg_after_pink' then
          report := concat(report, 'kao_id=', (select string_agg(status, ',') from public.kao_id_identities
                                                where profile_id = buyer and organization_id is null),
                           ' verification=', (select status from public.verifications where profile_id = buyer));
        when 's_bank_submit' then
          report := concat(report, 'bank_id_returned=',
                           public.submit_bank_r8c(bank, 'ธนาคารกสิกรไทย', 'สมชาย ทดสอบระบบ', '0123456789', 'สาขาทดสอบ',
                                                  'savings', seller || '/bank-account/' || bank || '/evidence.jpg') = bank);
        when 'pg_bank_request' then
          select id into fv from public.financial_verifications where bank_account_id = bank;
          report := concat(report, 'request=', fv is not null);
        when 't_bank_queue' then
          j := to_jsonb(public.kyc_review_queue_r7c());
          report := concat(report, 'has_bank=', position(fv::text in j::text) > 0 or position(bank::text in j::text) > 0);
        when 't_bank_approve' then
          ok := public.kyc_review_decision_r7c(fv, true, null);
          report := concat(report, 'decided=', ok);
        when 'pg_verified' then
          report := concat(report, 'bank=', (select status || '/' || is_verified from public.bank_accounts where id = bank),
                           ' fv=', (select status || '/' || name_match_status from public.financial_verifications where id = fv),
                           ' kao_id=', (select string_agg(status, ',') from public.kao_id_identities
                                         where profile_id = seller and organization_id is null),
                           ' seller=', secondhand.seller_status_r20f(seller)::text);
        when 's_status2' then
          j := secondhand.get_seller_status();
          report := concat(report, 'verified=', j->>'verified', ' can_list=', j->>'can_list');

        -- First listing: the shop is opened for the member (1 account = 1 shop).
        when 'pg_photos' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          select 'marketplace-product-images', seller || '/' || photo_set || '/' || n || '.jpg', seller::text,
                 '{"size": 200000, "mimetype": "image/jpeg"}'
            from generate_series(1, 3) n;
          report := concat(report, 'ok');
        when 's_list' then
          j := secondhand.create_listing(cat, 'กล้องฟิล์ม Golden Journey', 'กล้องฟิล์มสภาพดี ใช้งานได้ปกติ ทดสอบระบบ',
                                         3::smallint, 1500,
                                         array[seller || '/' || photo_set || '/1.jpg', seller || '/' || photo_set || '/2.jpg'],
                                         'seller', 'thailand_post_registered', 250, 10::smallint, '1_2');
          p1 := (j->>'product_id')::uuid;
          shop := (j->>'shop_id')::uuid;
          report := concat(report, 'fee=', j->>'sales_fee', ' net=', j->>'net_amount', ' first_sale_promo=',
                           j->>'first_sale_promo', ' shops=', (select count(*) from public.shops where owner_id = seller));
        when 'anon_detail' then
          j := secondhand.get_listing_detail(p1);
          report := concat(report, 'title=', j->>'title' is not null, ' verified_badge=',
                           coalesce(j->'seller'->>'verified', j->'seller_card'->>'verified', '?'));

        -- Buyer: checkout, wallet payment into escrow.
        when 'b_checkout' then
          j := secondhand.get_checkout(p1);
          report := concat(report, 'problem=', coalesce(j->>'problem', 'none'), ' total=', j->>'price',
                           ' wallet=', coalesce(j->>'wallet_balance', 'null'));
        when 'pg_fund' then
          insert into public.wallets(profile_id) values (buyer), (seller) on conflict (profile_id) do nothing;
          update public.wallets set balance = 5000 where profile_id = buyer;
          insert into secondhand.shipping_addresses(profile_id, recipient_name, phone, postal_code, province,
                                                    district, address_line1, address_type)
          values (buyer, 'Golden Buyer', '812345678', '10110', 'Bangkok', 'Watthana', '1 Sukhumvit', 'shipping')
          returning id into addr;
          seller_mark := (select balance from public.wallets where profile_id = seller);
          report := concat(report, 'deposit_simulated=5000 seller_start=', seller_mark);
        when 'b_order1' then
          o1 := (secondhand.create_order(p1, addr)->>'order_id')::uuid;
          report := concat(report, 'ok');
        when 'b_pay1' then
          j := secondhand.pay_order(o1, 'wallet');
          report := concat(report, j->>'status');
        when 'pg_after_pay' then
          report := concat(report, (select order_status || '/' || payment_status || '/' || escrow_status
                                      from public.orders where id = o1),
                           ' buyer_wallet=', (select balance from public.wallets where profile_id = buyer),
                           ' item=', (select status from public.products where id = p1),
                           ' escrow=', (select e.escrow_status || ':' || e.amount from public.escrow_transactions e
                                          join secondhand.order_details d on d.escrow_id = e.id where d.order_id = o1));
        when 's_my_page' then
          j := secondhand.get_my_page();
          report := concat(report, 'todo=', (select string_agg(x->>'code', ',') from jsonb_array_elements(j->'todo') x));
        when 's_ship1' then
          j := secondhand.mark_shipped(o1, 'Thailand Post', 'EE123456789TH');
          report := concat(report, j->>'status');
        when 'b_receive1' then
          j := secondhand.receive_and_review(o1, 'good', 'ได้รับแล้ว สภาพดีมากครับ', null);
          report := concat(report, coalesce(j->>'status', j::text));
        when 'pg_after_receive' then
          report := concat(report, (select order_status || '/' || escrow_status from public.orders where id = o1),
                           ' seller_delta=', (select balance from public.wallets where profile_id = seller) - seller_mark,
                           ' fee=', (select marketplace_fee from public.orders where id = o1),
                           ' escrow=', (select e.escrow_status from public.escrow_transactions e
                                          join secondhand.order_details d on d.escrow_id = e.id where d.order_id = o1),
                           ' promo_used=', exists (select 1 from secondhand.first_sale_promotions where profile_id = seller));
        when 's_review_back' then
          j := secondhand.submit_review(o1, 'good', 'ชำระเงินรวดเร็ว ขอบคุณครับ', null);
          report := concat(report, 'ok');
        when 'b_reviews' then
          j := secondhand.list_member_reviews(shop, null, null, 20);
          report := concat(report, 'seller_reviews=', jsonb_array_length(coalesce(j->'reviews', j->'items', '[]'::jsonb)),
                           ' good=', coalesce(j->'summary'->>'good', j->>'good', '?'));

        -- Withdrawal to the verified bank account, paid by staff.
        when 's_withdraw_info' then
          j := secondhand.get_withdrawal_info();
          report := concat(report, 'balance=', j->>'balance', ' bank=', coalesce(j->'bank'->>'bank_name', j->>'bank_name', '?'),
                           ' last4=', coalesce(j->'bank'->>'last4', j->>'account_last4', '?'));
        when 's_withdraw_big' then
          perform secondhand.request_withdrawal(99999);
          report := concat(report, 'UNEXPECTED_OK');
        when 's_withdraw' then
          j := secondhand.request_withdrawal(1000);
          w1 := coalesce(j->>'id', j->>'withdrawal_id')::uuid;
          report := concat(report, coalesce(j->>'status', j::text));
        when 'pg_after_request' then
          report := concat(report, (select 'balance=' || balance || ' hold=' || hold_balance from public.wallets
                                     where profile_id = seller),
                           ' request=', (select withdraw_status || ':' || amount from public.withdraw_requests where id = w1));
        when 't_tools' then
          j := public.staff_tools_r24();
          report := concat(report, 'withdrawals=', j->>'withdrawals', ' pending>=1=', (j->>'pending_withdrawals')::int >= 1);
        when 't_withdraw_queue' then
          j := public.withdrawal_queue_r24('pending', null);
          report := concat(report, 'has=', j @> jsonb_build_array(jsonb_build_object('id', w1)));
        when 't_withdraw_paid' then
          j := public.withdrawal_review_r24(w1, true, 'TRF-E2E-0001', null);
          report := concat(report, j->>'status');
        when 'pg_after_paid' then
          report := concat(report, (select 'balance=' || balance || ' hold=' || hold_balance from public.wallets
                                     where profile_id = seller),
                           ' request=', (select withdraw_status || ' ref=' || transfer_reference from public.withdraw_requests
                                          where id = w1),
                           ' tx=', (select transaction_status from public.wallet_transactions
                                     where id = (select wallet_transaction_id from public.withdraw_requests where id = w1)));

        -- Second sale with the test gateway: the money must never reach the seller's wallet.
        when 's_list2' then
          j := secondhand.create_listing(cat, 'เลนส์ Golden Journey', 'เลนส์สภาพดี ใช้งานได้ปกติ ทดสอบระบบรอบสอง',
                                         2::smallint, 1200, array[seller || '/' || photo_set || '/3.jpg'],
                                         'seller', 'thailand_post_registered', 250, 10::smallint, '2_3');
          p2 := (j->>'product_id')::uuid;
          report := concat(report, 'fee=', j->>'sales_fee', ' first_sale_promo=', j->>'first_sale_promo');
        when 'b_order2' then
          o2 := (secondhand.create_order(p2, addr)->>'order_id')::uuid;
          report := concat(report, 'ok');
        when 'pg_mark' then
          seller_mark := (select balance from public.wallets where profile_id = seller);
          report := concat(report, 'seller_before_mock=', seller_mark);
        when 'b_pay2' then
          j := secondhand.pay_order(o2, 'mock');
          report := concat(report, j->>'status');
        when 's_ship2' then
          j := secondhand.mark_shipped(o2, 'Flash', null);
          report := concat(report, j->>'status');
        when 'b_receive2' then
          j := secondhand.receive_and_review(o2, 'good', null, null);
          report := concat(report, coalesce(j->>'status', j::text));
        when 'pg_after_mock' then
          report := concat(report, (select order_status || '/' || escrow_status from public.orders where id = o2),
                           ' fee=', (select marketplace_fee from public.orders where id = o2),
                           ' seller_delta=', (select balance from public.wallets where profile_id = seller) - seller_mark,
                           ' buyer_wallet=', (select balance from public.wallets where profile_id = buyer));

        when 'pg_notifications' then
          report := concat(report, 'seller=', (select string_agg(notification_type || ':' || n, ',')
                                                 from (select notification_type, count(*) n from public.notifications
                                                        where profile_id = seller group by 1 order by 1) x),
                           E'\n  buyer=', (select string_agg(notification_type || ':' || n, ',')
                                             from (select notification_type, count(*) n from public.notifications
                                                    where profile_id = buyer group by 1 order by 1) x));
        when 'pg_invariants' then
          report := concat(report,
            'no_negative_wallets=', not exists (select 1 from public.wallets where profile_id in (seller, buyer)
                                                   and (balance < 0 or hold_balance < 0)),
            ' completed_escrow_released=', not exists (
              select 1 from public.orders o join secondhand.order_details d on d.order_id = o.id
                join public.escrow_transactions e on e.id = d.escrow_id
               where o.id in (o1, o2) and o.order_status = 'completed' and e.escrow_status <> 'released'),
            ' seller_final=', (select balance from public.wallets where profile_id = seller),
            ' buyer_final=', (select balance from public.wallets where profile_id = buyer),
            ' seller_tx=', (select string_agg(transaction_type || ':' || transaction_status || ':' || amount, ','
                                              order by w.created_at)
                              from public.wallet_transactions w join public.wallets x on x.id = w.wallet_id
                             where x.profile_id = seller),
            E'\n  buyer_tx=', (select string_agg(transaction_type || ':' || transaction_status || ':' || amount, ','
                                                 order by w.created_at)
                                 from public.wallet_transactions w join public.wallets x on x.id = w.wallet_id
                                where x.profile_id = buyer));
      end case;
    exception when others then
      report := concat(report, 'ERR ', sqlerrm);
    end;
    report := concat(report, E'\n');
  end loop;
  raise exception 'E2E_REPORT%', E'\n' || report;
end $$;
