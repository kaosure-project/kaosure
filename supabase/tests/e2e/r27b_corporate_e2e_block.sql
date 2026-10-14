-- R27b corporate shop journey: a simulated company (business Kao ID + verified company bank) runs a business shop.
-- The owner invites a staff member by Kao ID; staff list, chat and ship within their permissions; the sale settles
-- into the organization's wallet; only finance withdraws, to the company bank; Kao ID staff pay it out.
-- Company registration itself is R27c, so pg_* steps create the company. Everything is rolled back.
do $$
declare
  owner uuid := gen_random_uuid();
  fin uuid := gen_random_uuid();
  stf uuid := gen_random_uuid();
  nokid uuid := gen_random_uuid();
  buyer uuid := gen_random_uuid();
  kstaff uuid := gen_random_uuid();
  owner_s uuid := gen_random_uuid();
  fin_s uuid := gen_random_uuid();
  stf_s uuid := gen_random_uuid();
  nokid_s uuid := gen_random_uuid();
  buyer_s uuid := gen_random_uuid();
  kstaff_s uuid := gen_random_uuid();
  cid uuid := 'f56cdf5a-347a-4847-ad0d-f05b580b007c';
  photo_set text := 'e2e' || left(replace(gen_random_uuid()::text, '-', ''), 8);
  org uuid;
  shop uuid;
  bank uuid;
  cat uuid;
  kid_stf text;
  kid_fin text;
  inv uuid;
  p1 uuid;
  addr uuid;
  o1 uuid;
  w1 uuid;
  org_wallet uuid;
  report text := '';
  ctx text;
  j jsonb;
  who uuid;
  sess uuid;
  step text;
  kao_steps text[] := array['t_detail', 't_member_denied', 't_paid'];
  as_postgres text[] := array['setup', 'pg_photos', 'pg_fund', 'pg_after_pay', 'pg_after_receive', 'pg_after_request',
                              'pg_t_join', 'pg_t_leave', 'pg_after_paid', 'pg_expire', 'pg_invariants'];
  as_owner text[] := array['o_my_shops', 'o_invite_unknown', 'o_invite', 'o_update', 'o_orders_personal',
                           'o_withdraw_personal', 'o_list_staff', 'o_remove', 'o_invite2', 'o_invite3', 'o_cancel3',
                           'o_invite4', 'o_events'];
  as_fin text[] := array['f_my_shops', 'f_list_denied', 'f_withdraw_info', 'f_withdraw', 'f_withdraw_again'];
  as_stf text[] := array['s_list_before', 's_my_shops_invite', 's_accept', 's_my_shops', 's_list', 's_invite_escalate',
                         's_withdraw_info_denied', 's_checkout_own', 's_orders', 's_chat', 's_chat_view', 's_ship',
                         's_review_back', 's_withdraw_denied', 's_rls_invites', 's_rls_staff', 's_after_removed',
                         's_orders_after', 's_my_shops_after', 's_decline2', 's_accept_expired'];
  as_nokid text[] := array['n_list', 'n_accept_other'];
  as_kstaff text[] := array['t_detail', 't_member_denied', 't_paid'];
  as_anon text[] := array['anon_detail'];
  steps text[] := array['setup', 'o_my_shops', 'f_my_shops', 'n_list', 'o_invite_unknown', 'o_invite',
    's_list_before', 's_my_shops_invite', 'n_accept_other', 's_accept', 's_my_shops', 'pg_photos', 's_list',
    's_invite_escalate', 's_withdraw_info_denied', 'f_list_denied', 'o_update', 'anon_detail', 'pg_fund',
    's_checkout_own', 'b_checkout', 'b_order', 'b_pay', 'pg_after_pay', 's_orders', 'o_orders_personal', 's_chat',
    'b_chat', 's_chat_view', 's_ship', 'b_receive', 'pg_after_receive', 's_review_back', 'b_order_view',
    's_withdraw_denied', 'o_withdraw_personal', 'f_withdraw_info', 'f_withdraw', 'f_withdraw_again',
    'pg_after_request', 'pg_t_join', 't_member_denied', 'pg_t_leave', 't_detail', 't_paid', 'pg_after_paid',
    's_rls_invites', 's_rls_staff', 'o_list_staff', 'o_remove', 's_after_removed', 's_orders_after',
    's_my_shops_after', 'o_invite2', 's_decline2', 'o_invite3', 'o_cancel3', 'o_invite4', 'pg_expire',
    's_accept_expired', 'o_events', 'pg_invariants'];
begin
  insert into auth.users(id, instance_id, aud, role, email, phone, raw_app_meta_data, raw_user_meta_data,
                         created_at, updated_at, is_anonymous, email_confirmed_at, phone_confirmed_at)
  select x.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'e2e-r27b-' || x.tag || '-' || left(x.id::text, 8) || '@example.invalid',
         '6681' || lpad((random() * 1e7)::int::text, 7, '0'),
         '{"provider":"email","providers":["email"]}', jsonb_build_object('display_name', x.name),
         now(), now(), false, now(), now()
    from (values (owner, 'owner', 'Corp Owner'), (fin, 'finance', 'Corp Finance'), (stf, 'staff', 'Corp Staff'),
                 (nokid, 'nokid', 'No Kao ID'), (buyer, 'buyer', 'Corp Buyer'), (kstaff, 'kao', 'Kao Staff'))
         x(id, tag, name);
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (owner_s, owner, now(), now(), 'aal1'), (fin_s, fin, now(), now(), 'aal1'), (stf_s, stf, now(), now(), 'aal1'),
         (nokid_s, nokid, now(), now(), 'aal1'), (buyer_s, buyer, now(), now(), 'aal1'),
         (kstaff_s, kstaff, now(), now(), 'aal1');
  update public.company_owners set profile_id = kstaff;

  foreach step in array steps loop
    begin
      report := concat(report, step, ': ');
      who := case when step = any(as_owner) then owner when step = any(as_fin) then fin
                  when step = any(as_stf) then stf when step = any(as_nokid) then nokid
                  when step = any(as_kstaff) then kstaff else buyer end;
      sess := case when step = any(as_owner) then owner_s when step = any(as_fin) then fin_s
                   when step = any(as_stf) then stf_s when step = any(as_nokid) then nokid_s
                   when step = any(as_kstaff) then kstaff_s else buyer_s end;
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
        -- A company that passed R27c-style checks: business Kao ID and an approved company bank account.
        -- Members' personal Kao IDs stand in for their approved identity documents.
        when 'setup' then
          select id into cat from public.categories where is_active order by sort_order nulls last, name limit 1;
          perform kaoid_private.grant_kao_id_r27a(x) from unnest(array[owner, fin, stf, buyer]) x;
          select kao_id into kid_stf from public.kao_id_identities where profile_id = stf;
          select kao_id into kid_fin from public.kao_id_identities where profile_id = fin;
          insert into public.organizations(name, code, organization_type)
          values ('บริษัท ทดสอบอาร์ยี่สิบเจ็ดบี จำกัด', 'E2E-' || left(owner::text, 8), 'company')
          returning id into org;
          insert into public.organization_members(organization_id, profile_id, role)
          values (org, owner, 'owner'), (org, fin, 'finance');
          insert into public.kao_id_identities(profile_id, organization_id, kao_id, status, identity_type, issued_at)
          values (null, org, public.generate_kao_id(), 'active', 'business', now());
          insert into public.bank_accounts(profile_id, organization_id, bank_name, account_name, account_number,
                                           bank_code, branch_name, account_type, is_verified, status, verified_at)
          values (null, org, 'ธนาคารกรุงเทพ', 'บริษัท ทดสอบอาร์ยี่สิบเจ็ดบี จำกัด', '9876543210', '002', 'สำนักงานใหญ่',
                  'current', true, 'verified', now())
          returning id into bank;
          insert into public.financial_verifications(bank_account_id, identity_type, profile_id, organization_id,
                                                     submitted_by, name_match_status, status, verified_at)
          values (bank, 'business', null, org, owner, 'matched', 'approved', now());
          insert into public.shops(owner_id, organization_id, seller_identity_type, shop_name, shop_slug)
          values (owner, org, 'business', 'ร้านบริษัท R27b', 'e2e-r27b-' || left(replace(org::text, '-', ''), 12))
          returning id into shop;
          report := concat(report, 'kao_ids=', (select count(*) from public.kao_id_identities
                                                  where profile_id in (owner, fin, stf, buyer)),
                           ' org_verified=', public.is_identity_financially_verified('business', null, org),
                           ' sell=', secondhand.shop_sell_status_r27(shop)::text);

        when 'o_my_shops' then
          j := secondhand.my_shops();
          report := concat(report, 'shops=', jsonb_array_length(j->'shops'),
                           ' kind=', j->'shops'->0->>'kind', ' perms=', j->'shops'->0->>'permissions',
                           ' can_list=', j->'shops'->0->'sell_status'->>'can_list');
        when 'f_my_shops' then
          j := secondhand.my_shops();
          report := concat(report, 'perms=', j->'shops'->0->>'permissions');
        when 'n_list' then
          perform secondhand.create_listing(cat, 'ของคนนอก', 'ไม่มีสิทธิ์ในร้านบริษัทนี้', 3::smallint, 1500,
                                            array[nokid || '/x/1.jpg'], 'seller', 'thailand_post_registered', 250,
                                            10::smallint, '1_2', shop);
          report := concat(report, 'UNEXPECTED_OK');

        -- Staff invitation by Kao ID.
        when 'o_invite_unknown' then
          perform secondhand.invite_shop_staff(shop, 'KAO-0000-0000-NOPE', true, true, false, false, false);
          report := concat(report, 'UNEXPECTED_OK');
        when 'o_invite' then
          j := secondhand.invite_shop_staff(shop, lower(' ' || kid_stf || ' '), true, true, false, false, false);
          inv := (j->>'id')::uuid;
          report := concat(report, 'status=', j->>'status', ' perms=', j->>'permissions');
        when 's_list_before' then
          perform secondhand.create_listing(cat, 'ก่อนตอบรับ', 'ยังไม่ได้ตอบรับคำเชิญเป็นทีมงาน', 3::smallint, 1500,
                                            array[stf || '/x/1.jpg'], 'seller', 'thailand_post_registered', 250,
                                            10::smallint, '1_2', shop);
          report := concat(report, 'UNEXPECTED_OK');
        when 's_my_shops_invite' then
          j := secondhand.my_shops();
          report := concat(report, 'shops=', jsonb_array_length(j->'shops'), ' invites=', jsonb_array_length(j->'invites'),
                           ' shop_name=', j->'invites'->0->>'shop_name');
        when 'n_accept_other' then
          perform secondhand.respond_shop_staff_invite(inv, true);
          report := concat(report, 'UNEXPECTED_OK');
        when 's_accept' then
          j := secondhand.respond_shop_staff_invite(inv, true);
          report := concat(report, 'status=', j->>'status');
        when 's_my_shops' then
          j := secondhand.my_shops();
          report := concat(report, 'shops=', jsonb_array_length(j->'shops'), ' perms=', j->'shops'->0->>'permissions');

        -- Staff with the products permission list for the company shop.
        when 'pg_photos' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          select 'marketplace-product-images', stf || '/' || photo_set || '/' || n || '.jpg', stf::text,
                 '{"size": 200000, "mimetype": "image/jpeg"}'
            from generate_series(1, 2) n;
          report := concat(report, 'ok');
        when 's_list' then
          j := secondhand.create_listing(cat, 'โน้ตบุ๊กบริษัท R27b', 'โน้ตบุ๊กมือสองจากบริษัท ทดสอบระบบร้านนิติบุคคล',
                                         3::smallint, 1500, array[stf || '/' || photo_set || '/1.jpg'],
                                         'seller', 'thailand_post_registered', 250, 10::smallint, '1_2', shop);
          p1 := (j->>'product_id')::uuid;
          report := concat(report, 'same_shop=', (j->>'shop_id')::uuid = shop, ' fee=', j->>'sales_fee',
                           ' promo=', j->>'first_sale_promo');
        when 's_invite_escalate' then
          perform secondhand.invite_shop_staff(shop, kid_fin, true, false, false, false, false);
          report := concat(report, 'UNEXPECTED_OK');
        when 's_withdraw_info_denied' then
          perform secondhand.get_withdrawal_info(shop);
          report := concat(report, 'UNEXPECTED_OK');
        when 'f_list_denied' then
          perform secondhand.create_listing(cat, 'ฝ่ายการเงินลงขาย', 'ฝ่ายการเงินไม่มีสิทธิ์จัดการสินค้า', 3::smallint, 1500,
                                            array[fin || '/x/1.jpg'], 'seller', 'thailand_post_registered', 250,
                                            10::smallint, '1_2', shop);
          report := concat(report, 'UNEXPECTED_OK');
        when 'o_update' then
          j := secondhand.update_shop_staff(shop, stf, true, true, true, false, false);
          report := concat(report, 'perms=', j->>'permissions');
        when 'anon_detail' then
          j := secondhand.get_listing_detail(p1);
          report := concat(report, 'kind=', j->'seller'->>'kind', ' name=', j->'seller'->>'display_name',
                           ' verified=', j->'seller'->>'is_verified', ' is_owner=', j->>'is_owner');

        -- A buyer pays from the wallet; escrow holds it for the organization's wallet.
        when 'pg_fund' then
          report := concat(report, 'seller_is_owner=', (select seller_id from secondhand.listings where product_id = p1) = owner,
                           ' invite_notified=', exists (select 1 from public.notifications
                                                         where profile_id = stf and notification_type = 'shop_staff_invite'),
                           ' ');
          insert into public.wallets(profile_id) values (buyer) on conflict (profile_id) do nothing;
          update public.wallets set balance = 5000 where profile_id = buyer;
          insert into secondhand.shipping_addresses(profile_id, recipient_name, phone, postal_code, province,
                                                    district, address_line1, address_type)
          values (buyer, 'Corp Buyer', '812345678', '10110', 'Bangkok', 'Watthana', '1 Sukhumvit', 'shipping')
          returning id into addr;
          report := concat(report, 'deposit_simulated=5000');
        when 's_checkout_own' then
          j := secondhand.get_checkout(p1);
          report := concat(report, 'problem=', coalesce(j->>'problem', 'none'));
        when 'b_checkout' then
          j := secondhand.get_checkout(p1);
          report := concat(report, 'problem=', coalesce(j->>'problem', 'none'), ' price=', j->>'price');
        when 'b_order' then
          o1 := (secondhand.create_order(p1, addr)->>'order_id')::uuid;
          report := concat(report, 'ok');
        when 'b_pay' then
          j := secondhand.pay_order(o1, 'wallet');
          report := concat(report, j->>'status');
        when 'pg_after_pay' then
          select id into org_wallet from public.wallets where organization_id = org;
          report := concat(report, 'org_wallet=', org_wallet is not null,
                           ' escrow_to_org=', (select e.seller_wallet_id = org_wallet from public.escrow_transactions e
                                                 join secondhand.order_details d on d.escrow_id = e.id
                                                where d.order_id = o1),
                           ' owner_wallet=', coalesce((select balance::text from public.wallets where profile_id = owner),
                                                      'none'));
        when 's_orders' then
          j := secondhand.list_my_orders('seller', null, 20, shop);
          report := concat(report, 'orders=', jsonb_array_length(j->'orders'), ' role=', j->'orders'->0->>'role',
                           ' total=', j->'orders'->0->>'total');
        when 'o_orders_personal' then
          j := secondhand.list_my_orders('seller', null, 20);
          report := concat(report, 'personal_orders=', jsonb_array_length(j->'orders'));
        when 's_chat' then
          j := secondhand.send_order_message(o1, 'ขอบคุณที่สั่งซื้อค่ะ จะจัดส่งพรุ่งนี้', gen_random_uuid());
          report := concat(report, 'sent=', j->>'seq');
        when 'b_chat' then
          j := secondhand.get_order_chat(o1, null, 30);
          perform secondhand.send_order_message(o1, 'รับทราบครับ ขอบคุณครับ', gen_random_uuid());
          report := concat(report, 'buyer_sees=', jsonb_array_length(j->'messages'),
                           ' first_mine=', j->'messages'->0->>'mine');
        when 's_chat_view' then
          j := secondhand.get_order_chat(o1, null, 30);
          report := concat(report, 'messages=', jsonb_array_length(j->'messages'), ' unread=', j->>'unread',
                           ' mine=', (select string_agg(x->>'mine', ',') from jsonb_array_elements(j->'messages') x),
                           ' read=', secondhand.mark_order_chat_read(o1)->>'read');
        when 's_ship' then
          j := secondhand.mark_shipped(o1, 'Kerry', 'KRY0001');
          report := concat(report, j->>'status');
        when 'b_receive' then
          j := secondhand.receive_and_review(o1, 'good', 'ได้รับแล้ว ร้านบริษัทบริการดีครับ', null);
          report := concat(report, coalesce(j->>'status', j::text));
        when 'pg_after_receive' then
          report := concat(report, (select order_status || '/' || escrow_status from public.orders where id = o1),
                           ' fee=', (select marketplace_fee from public.orders where id = o1),
                           ' org_balance=', (select balance from public.wallets where id = org_wallet),
                           ' owner_wallet=', coalesce((select balance::text from public.wallets where profile_id = owner),
                                                      'none'),
                           ' promo_rows=', (select count(*) from secondhand.first_sale_promotions where profile_id = owner));
        when 's_review_back' then
          j := secondhand.submit_review(o1, 'good', 'ผู้ซื้อชำระเงินรวดเร็ว ขอบคุณค่ะ', null);
          report := concat(report, 'role=', j->>'reviewer_role',
                           ' reviewer_is_owner=', (select reviewer_id = owner from secondhand.reviews where id = (j->>'id')::uuid));
        when 'b_order_view' then
          j := secondhand.get_order(o1);
          report := concat(report, 'counterpart=', coalesce(j->'counterpart'->>'display_name', j->'order'->'counterpart'->>'display_name'));

        -- Only the organization's owner or finance may withdraw, and only to the company bank.
        when 's_withdraw_denied' then
          perform secondhand.request_withdrawal(100, shop);
          report := concat(report, 'UNEXPECTED_OK');
        when 'o_withdraw_personal' then
          j := secondhand.get_withdrawal_info();
          report := concat(report, 'personal_balance=', j->>'balance', ' reason=', j->>'reason');
        when 'f_withdraw_info' then
          j := secondhand.get_withdrawal_info(shop);
          report := concat(report, 'balance=', j->>'balance', ' bank=', j->'bank'->>'bank_name',
                           ' last4=', j->'bank'->>'last4', ' can=', j->>'can_withdraw', ' org=', j->>'organization_name');
        when 'f_withdraw' then
          j := secondhand.request_withdrawal(500, shop);
          w1 := (j->>'id')::uuid;
          report := concat(report, j->>'status', ' last4=', j->>'last4');
        when 'f_withdraw_again' then
          perform secondhand.request_withdrawal(100, shop);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_after_request' then
          report := concat(report, (select 'balance=' || balance || ' hold=' || hold_balance from public.wallets
                                     where id = org_wallet),
                           ' request=', (select withdraw_status || ':' || amount || ' org=' || (organization_id = org)
                                           || ' requester_fin=' || (profile_id = fin)
                                           from public.withdraw_requests where id = w1));
        when 'pg_t_join' then
          insert into public.organization_members(organization_id, profile_id, role) values (org, kstaff, 'staff');
          report := concat(report, 'ok');
        when 't_member_denied' then
          perform public.withdrawal_review_r24(w1, true, 'TRF-R27B-SELF', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_t_leave' then
          delete from public.organization_members where organization_id = org and profile_id = kstaff;
          report := concat(report, 'ok');
        when 't_detail' then
          j := public.withdrawal_detail_r24(w1);
          report := concat(report, 'org=', j->>'organization_name', ' business_kao_id=', j->>'business_kao_id' is not null,
                           ' bank_ok=', j->>'bank_still_verified', ' hold=', j->>'wallet_hold');
        when 't_paid' then
          j := public.withdrawal_review_r24(w1, true, 'TRF-R27B-0001', null);
          report := concat(report, j->>'status');
        when 'pg_after_paid' then
          report := concat(report, (select 'balance=' || balance || ' hold=' || hold_balance from public.wallets
                                     where id = org_wallet),
                           ' request=', (select withdraw_status || ' ref=' || transfer_reference
                                           from public.withdraw_requests where id = w1),
                           ' fin_notified=', exists (select 1 from public.notifications
                                                      where profile_id = fin and notification_type = 'withdrawal'));

        -- Tables are reachable only through the RPCs.
        when 's_rls_invites' then
          perform count(*) from secondhand.shop_staff_invites;
          report := concat(report, 'UNEXPECTED_OK');
        when 's_rls_staff' then
          perform count(*) from public.shop_staff;
          report := concat(report, 'UNEXPECTED_OK');

        -- Removing staff ends access immediately.
        when 'o_list_staff' then
          j := secondhand.list_shop_staff(shop);
          report := concat(report, 'staff=', jsonb_array_length(j->'staff'), ' kao_id_shown=',
                           j->'staff'->0->>'kao_id' = kid_stf, ' perms=', j->'staff'->0->>'permissions');
        when 'o_remove' then
          j := secondhand.remove_shop_staff(shop, stf);
          report := concat(report, 'removed=', j->>'removed');
        when 's_after_removed' then
          perform secondhand.mark_shipped(o1, 'Kerry', null);
          report := concat(report, 'UNEXPECTED_OK');
        when 's_orders_after' then
          perform secondhand.list_my_orders('seller', null, 20, shop);
          report := concat(report, 'UNEXPECTED_OK');
        when 's_my_shops_after' then
          j := secondhand.my_shops();
          report := concat(report, 'shops=', jsonb_array_length(j->'shops'));

        -- Invitations: decline, cancel, expiry.
        when 'o_invite2' then
          inv := (secondhand.invite_shop_staff(shop, kid_stf, false, false, true, false, false)->>'id')::uuid;
          report := concat(report, 'ok');
        when 's_decline2' then
          report := concat(report, 'status=', secondhand.respond_shop_staff_invite(inv, false)->>'status');
        when 'o_invite3' then
          inv := (secondhand.invite_shop_staff(shop, kid_stf, false, false, true, false, false)->>'id')::uuid;
          report := concat(report, 'ok');
        when 'o_cancel3' then
          report := concat(report, 'status=', secondhand.cancel_shop_staff_invite(inv)->>'status');
        when 'o_invite4' then
          inv := (secondhand.invite_shop_staff(shop, kid_stf, false, false, true, false, false)->>'id')::uuid;
          report := concat(report, 'ok');
        when 'pg_expire' then
          update secondhand.shop_staff_invites set expires_at = now() - interval '1 second' where id = inv;
          report := concat(report, 'ok');
        when 's_accept_expired' then
          report := concat(report, 'status=', secondhand.respond_shop_staff_invite(inv, true)->>'status');
        when 'o_events' then
          j := secondhand.list_shop_staff(shop);
          report := concat(report, 'actions=', (select string_agg(x->>'action', ',' order by ord desc)
                                                  from jsonb_array_elements(j->'events') with ordinality e(x, ord)));

        when 'pg_invariants' then
          report := concat(report,
            'no_negative_wallets=', not exists (select 1 from public.wallets
                                                 where (organization_id = org or profile_id in (owner, fin, stf, buyer))
                                                   and (balance < 0 or hold_balance < 0)),
            ' org_tx=', (select string_agg(transaction_type || ':' || transaction_status || ':' || amount, ','
                                            order by w.created_at)
                           from public.wallet_transactions w where w.wallet_id = org_wallet),
            ' buyer_final=', (select balance from public.wallets where profile_id = buyer),
            ' stf_active_after_expired=', (select count(*) from public.shop_staff
                                            where shop_id = shop and profile_id = stf and is_active),
            ' invite4=', (select invite_status from secondhand.shop_staff_invites where id = inv),
            ' one_owner_check=', (select count(*) from public.wallets where profile_id is null and organization_id is null));
      end case;
    exception when others then
      get stacked diagnostics ctx = pg_exception_context;
      report := concat(report, 'ERR ', sqlerrm,
                       case when sqlerrm in ('permission denied for table listings', 'query returned no rows')
                            then ' @ ' || replace(ctx, E'\n', ' | ') end);
    end;
    report := concat(report, E'\n');
  end loop;
  raise exception 'E2E_REPORT%', E'\n' || report;
end $$;
