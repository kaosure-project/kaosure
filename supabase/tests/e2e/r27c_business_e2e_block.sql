-- R27c company journey: a director with a personal Kao ID registers a company (certificate + optional VAT
-- certificate), Kao ID staff confirm the director and approve, the business Kao ID is issued, the company bank is
-- refused when the account name does not match, accepted when it does, reviewed under the two-person rule by staff
-- outside the company, and the company opens its Secondhand shop and lists. A second company is rejected.
-- Everything is rolled back.
do $$
declare
  app uuid := gen_random_uuid();
  app2 uuid := gen_random_uuid();
  nokid uuid := gen_random_uuid();
  fin uuid := gen_random_uuid();
  rev1 uuid := gen_random_uuid();
  rev2 uuid := gen_random_uuid();
  app_s uuid := gen_random_uuid();
  app2_s uuid := gen_random_uuid();
  nokid_s uuid := gen_random_uuid();
  fin_s uuid := gen_random_uuid();
  rev1_s uuid := gen_random_uuid();
  rev2_s uuid := gen_random_uuid();
  cid uuid := 'f56cdf5a-347a-4847-ad0d-f05b580b007c';
  photo_set text := 'e2e' || left(replace(gen_random_uuid()::text, '-', ''), 8);
  legal text := 'บริษัท ทดสอบอาร์ยี่สิบเจ็ดซี ' || left(replace(gen_random_uuid()::text, '-', ''), 6) || ' จำกัด';
  num text;
  num2 text;
  bad_num text;
  reg uuid;
  reg2 uuid;
  cert uuid := gen_random_uuid();
  vat uuid := gen_random_uuid();
  cert2 uuid := gen_random_uuid();
  org uuid;
  org2 uuid;
  bid_bad uuid := gen_random_uuid();
  bid uuid := gen_random_uuid();
  fv uuid;
  shop uuid;
  cat uuid;
  nid uuid;
  total int;
  report text := '';
  ctx text;
  j jsonb;
  b boolean;
  r public.business_registrations;
  who uuid;
  sess uuid;
  step text;
  as_postgres text[] := array['setup', 'pg_upload_docs', 'pg_after_approve', 'pg_bank_files', 'pg_add_members',
                              'pg_fv', 'pg_r2_leave', 'pg_after_bank', 'pg_photos', 'pg_upload_x', 'pg_after_reject',
                              'pg_invariants'];
  as_app2 text[] := array['x_dup_number', 'x_create', 'x_attach', 'x_submit', 'x_create_again'];
  as_nokid text[] := array['n_create', 'n_bank'];
  as_fin text[] := array['f_bank_denied', 'f_my_orgs', 'f_bank_notice', 's_f_open_denied'];
  as_rev1 text[] := array['r1_old_decide', 'r1_queue', 'r1_evidence', 'r1_approve_nodir', 'r1_approve',
                          'r1_approve_again', 'r1_bank_queue', 'r1_bank_notice_target', 'r1_bank_evidence',
                          'r1_bank_vote', 'r1_bank_vote_again', 'r1_reject'];
  as_rev2 text[] := array['r2_queue_hidden', 'r2_conflict_decide', 'r2_bank_approve'];
  secondhand_steps text[] := array['s_my_shops', 's_f_open_denied', 's_open', 's_open_again', 's_list',
                                   's_my_shops_after'];
  steps text[] := array['setup', 'n_create', 'a_create_badnum', 'a_create_old', 'a_create', 'a_dup_draft',
    'a_submit_nodoc', 'pg_upload_docs', 'a_attach_cert', 'a_attach_vat', 'a_attach_badpath', 'a_submit_nodecl',
    'a_submit', 'a_get', 'x_dup_number', 'a_legacy_kao', 'a_legacy_shop', 'r1_old_decide', 'a_self_decide',
    'r1_queue', 'r1_evidence', 'r1_approve_nodir', 'r1_approve', 'r1_approve_again', 'pg_after_approve', 'a_notice',
    'a_my_orgs', 'pg_bank_files', 'n_bank', 'a_bank_mismatch', 'pg_add_members', 'f_bank_denied', 'a_bank',
    'pg_fv', 'a_bank_again', 'r1_bank_queue', 'r1_bank_notice_target', 'r1_bank_evidence', 'r2_queue_hidden',
    'r2_conflict_decide', 'pg_r2_leave', 'r1_bank_vote', 'r1_bank_vote_again', 'r2_bank_approve', 'pg_after_bank',
    'f_my_orgs', 'f_bank_notice', 's_my_shops', 's_f_open_denied', 's_open', 's_open_again', 'pg_photos', 's_list',
    's_my_shops_after', 'x_create', 'pg_upload_x', 'x_attach', 'x_submit', 'r1_reject', 'pg_after_reject',
    'x_create_again', 'pg_invariants'];
begin
  insert into auth.users(id, instance_id, aud, role, email, phone, raw_app_meta_data, raw_user_meta_data,
                         created_at, updated_at, is_anonymous, email_confirmed_at, phone_confirmed_at)
  select x.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'e2e-r27c-' || x.tag || '-' || left(x.id::text, 8) || '@example.invalid',
         '6682' || lpad((random() * 1e7)::int::text, 7, '0'),
         '{"provider":"email","providers":["email"]}', jsonb_build_object('display_name', x.name),
         now(), now(), false, now(), now()
    from (values (app, 'app', 'Corp Director'), (app2, 'app2', 'Other Director'), (nokid, 'nokid', 'No Kao ID'),
                 (fin, 'fin', 'Corp Finance'), (rev1, 'rev1', 'Kao Reviewer One'), (rev2, 'rev2', 'Kao Reviewer Two'))
         x(id, tag, name);
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (app_s, app, now(), now(), 'aal1'), (app2_s, app2, now(), now(), 'aal1'), (nokid_s, nokid, now(), now(), 'aal1'),
         (fin_s, fin, now(), now(), 'aal1'), (rev1_s, rev1, now(), now(), 'aal1'), (rev2_s, rev2, now(), now(), 'aal1');
  update public.company_owners set profile_id = rev1;

  foreach step in array steps loop
    begin
      report := concat(report, step, ': ');
      who := case when step = any(as_app2) then app2 when step = any(as_nokid) then nokid
                  when step = any(as_fin) then fin when step = any(as_rev1) then rev1
                  when step = any(as_rev2) then rev2 else app end;
      sess := case when step = any(as_app2) then app2_s when step = any(as_nokid) then nokid_s
                   when step = any(as_fin) then fin_s when step = any(as_rev1) then rev1_s
                   when step = any(as_rev2) then rev2_s else app_s end;
      if step = any(secondhand_steps) then
        perform set_config('request.jwt.claims', json_build_object(
          'sub', who, 'role', 'authenticated', 'session_id', sess,
          'aal', 'aal1', 'is_anonymous', false, 'client_id', cid)::text, true);
        perform set_config('request.headers', '{"content-profile":"secondhand"}', true);
      else
        perform set_config('request.jwt.claims', json_build_object(
          'sub', who, 'role', 'authenticated', 'session_id', sess, 'aal', 'aal1', 'is_anonymous', false)::text, true);
        perform set_config('request.headers', '{"content-profile":"public"}', true);
      end if;
      perform set_config('request.method', 'POST', true);
      perform set_config('role', case when step = any(as_postgres) then 'postgres' else 'authenticated' end, true);

      case step
        -- Applicants hold personal Kao IDs (standing in for their approved identity documents).
        when 'setup' then
          select id into cat from public.categories where is_active order by sort_order nulls last, name limit 1;
          perform kaoid_private.grant_kao_id_r27a(x) from unnest(array[app, app2, fin]) x;
          for i in 1..3 loop
            num := '0105' || lpad((floor(random() * 1e8))::bigint::text, 8, '0');
            total := 0;
            for k in 1..12 loop total := total + substr(num, k, 1)::int * (14 - k); end loop;
            num := num || ((11 - total % 11) % 10)::text;
            if i = 1 then bad_num := left(num, 12) || ((right(num, 1)::int + 1) % 10)::text;
            elsif i = 2 then num2 := num; end if;
            if i < 3 then continue; end if;
          end loop;
          report := concat(report, 'kao_ids=', (select count(*) from public.kao_id_identities
                                                  where profile_id in (app, app2, fin)),
                           ' policy=', (select dual_review || '/' || mfa_required from kaoid_private.security_policy_r14a));

        -- Registration rules.
        when 'n_create' then
          perform public.create_business_registration('registered_business', legal, num, 'อิเล็กทรอนิกส์');
          report := concat(report, 'UNEXPECTED_OK');
        when 'a_create_badnum' then
          perform public.create_business_registration('registered_business', legal, bad_num, 'อิเล็กทรอนิกส์');
          report := concat(report, 'UNEXPECTED_OK');
        when 'a_create_old' then
          perform public.create_business_registration('registered_business', legal, num, 'อิเล็กทรอนิกส์', null,
                                                      'Test R27C Co., Ltd.', current_date - 200);
          report := concat(report, 'UNEXPECTED_OK');
        when 'a_create' then
          r := public.create_business_registration('registered_business', legal, num, 'อิเล็กทรอนิกส์',
                                                   'ขายอุปกรณ์อิเล็กทรอนิกส์มือสอง', 'Test R27C Co., Ltd.',
                                                   current_date - 30);
          reg := r.id;
          report := concat(report, 'status=', r.status, ' en=', r.legal_name_en, ' cert_age=', current_date - r.certificate_issued_on);
        when 'a_dup_draft' then
          perform public.create_business_registration('registered_business', legal, num2, 'อิเล็กทรอนิกส์');
          report := concat(report, 'UNEXPECTED_OK');
        when 'a_submit_nodoc' then
          perform public.submit_business_registration(reg, true);
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_upload_docs' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          values ('identity-documents', app || '/business-registration/' || reg || '/' || cert || '.pdf', app::text,
                  '{"size": 300000, "mimetype": "application/pdf"}'),
                 ('identity-documents', app || '/business-registration/' || reg || '/' || vat || '.jpg', app::text,
                  '{"size": 200000, "mimetype": "image/jpeg"}');
          report := concat(report, 'ok');
        when 'a_attach_cert' then
          r := public.attach_business_document_r27c(reg, 'certificate', cert,
                 app || '/business-registration/' || reg || '/' || cert || '.pdf', 'หนังสือรับรอง.pdf');
          report := concat(report, 'doc_status=', r.document_status, ' cert=', r.document_id = cert);
        when 'a_attach_vat' then
          r := public.attach_business_document_r27c(reg, 'vat', vat,
                 app || '/business-registration/' || reg || '/' || vat || '.jpg', 'ภพ20.jpg');
          report := concat(report, 'vat=', r.vat_document_id = vat);
        when 'a_attach_badpath' then
          perform public.attach_business_document_r27c(reg, 'vat', gen_random_uuid(),
                    nokid || '/business-registration/' || reg || '/x.jpg', 'x.jpg');
          report := concat(report, 'UNEXPECTED_OK');
        when 'a_submit_nodecl' then
          perform public.submit_business_registration(reg);
          report := concat(report, 'UNEXPECTED_OK');
        when 'a_submit' then
          r := public.submit_business_registration(reg, true);
          org := r.organization_id;
          report := concat(report, 'status=', r.status, ' org=', org is not null, ' declared=', r.director_declared_at is not null);
        when 'a_get' then
          r := public.get_current_business_registration();
          report := concat(report, 'id_ok=', r.id = reg, ' status=', r.status, ' vat=', r.vat_document_id is not null);
        when 'x_dup_number' then
          perform public.create_business_registration('registered_business', 'บริษัท ลอกเลขทะเบียน จำกัด', num, 'อื่นๆ');
          report := concat(report, 'UNEXPECTED_OK');

        -- Legacy shortcuts are closed.
        when 'a_legacy_kao' then
          perform public.issue_business_kao_id(org);
          report := concat(report, 'UNEXPECTED_OK');
        when 'a_legacy_shop' then
          perform public.create_business_shop(org, 'ร้านลัด', 'shortcut-' || left(org::text, 8), null);
          report := concat(report, 'UNEXPECTED_OK');
        when 'r1_old_decide' then
          perform public.business_review_decide_r15b(rev1, reg, true, 'old path');
          report := concat(report, 'UNEXPECTED_OK');
        when 'a_self_decide' then
          perform public.business_review_decide_r27c(app, reg, true, 'self', true);
          report := concat(report, 'UNEXPECTED_OK');

        -- Kao ID staff review.
        when 'r1_queue' then
          j := (select x from jsonb_array_elements(public.business_review_queue_r15b()) x where x->>'id' = reg::text);
          report := concat(report, 'found=', j is not null, ' num_valid=', j->>'registration_number_valid',
                           ' taken=', j->>'registration_number_taken', ' fresh=', j->>'certificate_fresh',
                           ' en=', j->>'legal_name_en', ' paths=', jsonb_array_length(j->'paths'),
                           ' vat_paths=', jsonb_array_length(j->'vat_paths'), ' kao_id=', j->>'owner_kao_id' is not null,
                           ' declared=', j->>'director_declared', ' has_bank_field=', j ? 'bank_name');
        when 'r1_evidence' then
          report := concat(report, 'cert=', kaoid_private.can_read_evidence_r7c(app || '/business-registration/' || reg || '/' || cert || '.pdf'),
                           ' vat=', kaoid_private.can_read_evidence_r7c(app || '/business-registration/' || reg || '/' || vat || '.jpg'));
        when 'r1_approve_nodir' then
          perform public.business_review_decide_r27c(rev1, reg, true, null, false);
          report := concat(report, 'UNEXPECTED_OK');
        when 'r1_approve' then
          j := public.business_review_decide_r27c(rev1, reg, true, 'ตรวจกรรมการตามหนังสือรับรองแล้ว', true);
          report := concat(report, 'status=', j->>'status', ' kao_id_format=', j->>'business_kao_id' ~ '^K[A-Z0-9]{10}$');
        when 'r1_approve_again' then
          j := public.business_review_decide_r27c(rev1, reg, true, 'again', true);
          report := concat(report, 'status=', j->>'status');
        when 'pg_after_approve' then
          select id into nid from public.notifications where profile_id = app and message = 'business_approved' and target_id = reg;
          report := concat(report,
            'org=', (select status from public.organizations where id = org),
            ' role=', (select string_agg(role, ',') from public.organization_members where organization_id = org),
            ' legal=', (select verification_status || '/' || registration_status || '/' || coalesce(legal_name_en, '-')
                          from public.organization_legal_profiles where organization_id = org),
            ' docs=', (select string_agg(document_type || ':' || status, ',' order by document_type)
                         from public.identity_documents where id in (cert, vat)),
            ' ov=', (select status || '/bank=' || bank_verified || '/person=' || authorized_person_verified
                       from public.organization_verifications where organization_id = org),
            ' business_kao_ids=', (select count(*) from public.kao_id_identities where organization_id = org),
            ' confirmed_by_rev1=', (select director_confirmed_by = rev1 from public.business_registrations where id = reg),
            ' notice=', nid is not null,
            ' log=', exists (select 1 from public.activity_logs where action = 'kyc.business.approve' and target_id = reg));
        when 'a_notice' then
          j := public.kaoid_notice_target_r14b(nid);
          report := concat(report, j->>'kind', '/', j->>'status');
        when 'a_my_orgs' then
          j := public.my_organizations_r27c() -> 0;
          report := concat(report, 'role=', j->>'role', ' kao_id=', j->>'business_kao_id' is not null,
                           ' can_bank=', j->>'can_manage_bank', ' bank_verified=', j->>'bank_verified',
                           ' banks=', jsonb_array_length(j->'banks'), ' shop=', coalesce(j->>'shop', 'none'));

        -- Company bank: the account name must match the legal name.
        when 'pg_bank_files' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          select 'identity-documents', app || '/business-bank/' || x || '/evidence.jpg', app::text,
                 '{"size": 150000, "mimetype": "image/jpeg"}'
            from unnest(array[bid_bad, bid]) x;
          report := concat(report, 'ok');
        when 'n_bank' then
          perform public.submit_org_bank_r27c(org, gen_random_uuid(), 'ธนาคารกสิกรไทย', legal, '1234567890',
                                              'สำนักงานใหญ่', 'current', nokid || '/business-bank/x/evidence.jpg');
          report := concat(report, 'UNEXPECTED_OK');
        when 'a_bank_mismatch' then
          perform public.submit_org_bank_r27c(org, bid_bad, 'ธนาคารกสิกรไทย', 'บริษัท อื่นที่ไม่ใช่ จำกัด', '1234567890',
                                              'สำนักงานใหญ่', 'current', app || '/business-bank/' || bid_bad || '/evidence.jpg');
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_add_members' then
          insert into public.organization_members(organization_id, profile_id, role)
          values (org, fin, 'finance'), (org, rev2, 'staff');
          insert into public.admin_assignments(profile_id, role_id, assigned_by)
          select rev2, id, rev1 from public.admin_roles where code = 'kyc_officer';
          insert into auth.mfa_factors(id, user_id, friendly_name, factor_type, status, created_at, updated_at)
          values (gen_random_uuid(), rev1, 'e2e', 'totp', 'verified', now(), now());
          update kaoid_private.security_policy_r14a set dual_review = true where id;
          report := concat(report, 'dual=', (select dual_review from kaoid_private.security_policy_r14a));
        when 'f_bank_denied' then
          perform public.submit_org_bank_r27c(org, gen_random_uuid(), 'ธนาคารกสิกรไทย', legal, '1234567890',
                                              'สำนักงานใหญ่', 'current', fin || '/business-bank/x/evidence.jpg');
          report := concat(report, 'UNEXPECTED_OK');
        when 'a_bank' then
          j := public.submit_org_bank_r27c(org, bid, 'ธนาคารกสิกรไทย',
                 'บจก. ' || replace(replace(legal, 'บริษัท ', ''), ' จำกัด', ''), '7778889990', 'สำนักงานใหญ่', 'current',
                 app || '/business-bank/' || bid || '/evidence.jpg');
          report := concat(report, 'status=', j->>'status', ' name_match=', j->>'name_match');
        when 'pg_fv' then
          select id into fv from public.financial_verifications where bank_account_id = bid;
          select id into nid from public.notifications where profile_id = rev1 and message = 'review_new' and target_id = fv;
          report := concat(report, 'fv=', fv is not null, ' rev1_notice=', nid is not null,
                           ' submitter=', (select submitted_by = app and profile_id is null from public.financial_verifications where id = fv));
        when 'a_bank_again' then
          perform public.submit_org_bank_r27c(org, bid_bad, 'ธนาคารกรุงเทพ', legal, '5556667770',
                                              'สำนักงานใหญ่', 'savings', app || '/business-bank/' || bid_bad || '/evidence.jpg');
          report := concat(report, 'UNEXPECTED_OK');
        when 'r1_bank_queue' then
          j := (select x from jsonb_array_elements(public.kyc_review_queue_r7c()) x where x->>'id' = fv::text);
          report := concat(report, 'type=', j->>'document_type', ' match=', j->>'name_match',
                           ' org=', j->>'organization_name' = legal, ' identity=', j->>'identity_name' = legal,
                           ' kao_id=', j->>'business_kao_id' is not null, ' dual=', j->>'dual_review');
        when 'r1_bank_notice_target' then
          j := public.kaoid_notice_target_r14b(nid);
          report := concat(report, j->>'kind', '/', j->'row'->>'document_type', '/match=', j->'row'->>'name_match');
        when 'r1_bank_evidence' then
          report := concat(report, kaoid_private.can_read_evidence_r7c(app || '/business-bank/' || bid || '/evidence.jpg'));
        when 'r2_queue_hidden' then
          report := concat(report, 'visible=', exists (select 1 from jsonb_array_elements(public.kyc_review_queue_r7c()) x
                                                        where x->>'id' = fv::text),
                           ' evidence=', kaoid_private.can_read_evidence_r7c(app || '/business-bank/' || bid || '/evidence.jpg'));
        when 'r2_conflict_decide' then
          perform public.kyc_review_decision_r7c(fv, true, 'member');
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_r2_leave' then
          delete from public.organization_members where organization_id = org and profile_id = rev2;
          report := concat(report, 'staff_notices_to_members=', (select count(*) from public.notifications
                                                                   where target_id = fv and profile_id in (app, fin, rev2)));
        when 'r1_bank_vote' then
          b := public.kyc_review_decision_r7c(fv, true, 'ชื่อบัญชีตรงกับหนังสือรับรอง');
          report := concat(report, 'final=', b);
        when 'r1_bank_vote_again' then
          b := public.kyc_review_decision_r7c(fv, true, 'ซ้ำ');
          report := concat(report, 'final=', b);
        when 'r2_bank_approve' then
          b := public.kyc_review_decision_r7c(fv, true, 'ยืนยันอีกคน');
          report := concat(report, 'final=', b);
        when 'pg_after_bank' then
          select id into nid from public.notifications where profile_id = fin and message = 'business_bank_approved';
          report := concat(report,
            'bank=', (select status || '/' || is_verified from public.bank_accounts where id = bid),
            ' fv=', (select status || '/' || name_match_status || '/submitter_app=' || (submitted_by = app)
                       from public.financial_verifications where id = fv),
            ' ov_bank=', (select bank_verified from public.organization_verifications where organization_id = org),
            ' fin_verified=', public.is_identity_financially_verified('business', null, org),
            ' payout=', (secondhand.org_payout_bank_r27(org)).id = bid,
            ' notified=', (select string_agg(distinct case profile_id when app then 'app' when fin then 'fin' else 'other' end, ',')
                             from public.notifications where message = 'business_bank_approved' and target_id = bid),
            ' votes=', (select count(*) from public.approval_steps s join public.approval_requests a on a.id = s.approval_request_id
                         where a.resource_id = fv),
            ' log=', exists (select 1 from public.activity_logs where action = 'kyc.business_bank.approve' and target_id = bid),
            ' bad_bank_rows=', (select count(*) from public.bank_accounts where id = bid_bad));
        when 'f_my_orgs' then
          j := public.my_organizations_r27c() -> 0;
          report := concat(report, 'role=', j->>'role', ' can_bank=', j->>'can_manage_bank',
                           ' bank_verified=', j->>'bank_verified', ' bank=', j->'banks'->0->>'status',
                           ' last4=', j->'banks'->0->>'last4');
        when 'f_bank_notice' then
          j := public.kaoid_notice_target_r14b(nid);
          report := concat(report, j->>'kind', '/', j->>'status');

        -- The company opens its Secondhand shop.
        when 's_my_shops' then
          j := secondhand.my_shops();
          report := concat(report, 'shops=', jsonb_array_length(j->'shops'), ' can_open=', jsonb_array_length(j->'can_open'),
                           ' org=', j->'can_open'->0->>'organization_name' = legal);
        when 's_f_open_denied' then
          perform secondhand.open_business_shop(org, 'ร้านฝ่ายการเงิน');
          report := concat(report, 'UNEXPECTED_OK');
        when 's_open' then
          j := secondhand.open_business_shop(org, '  ร้านบริษัท R27c  ', 'สินค้ามือสองจากบริษัท');
          shop := (j->>'shop_id')::uuid;
          report := concat(report, 'name=', j->>'shop_name', ' can_list=', j->'sell_status'->>'can_list');
        when 's_open_again' then
          perform secondhand.open_business_shop(org, 'ร้านที่สอง');
          report := concat(report, 'UNEXPECTED_OK');
        when 'pg_photos' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          select 'marketplace-product-images', app || '/' || photo_set || '/' || n || '.jpg', app::text,
                 '{"size": 200000, "mimetype": "image/jpeg"}'
            from generate_series(1, 2) n;
          report := concat(report, 'ok');
        when 's_list' then
          j := secondhand.create_listing(cat, 'จอมอนิเตอร์บริษัท R27c', 'จอมอนิเตอร์มือสองจากบริษัท ทดสอบระบบลงทะเบียนนิติบุคคล',
                                         3::smallint, 2500, array[app || '/' || photo_set || '/1.jpg'],
                                         'seller', 'thailand_post_registered', 250, 10::smallint, '1_2', shop);
          report := concat(report, 'same_shop=', (j->>'shop_id')::uuid = shop, ' promo=', j->>'first_sale_promo');
        when 's_my_shops_after' then
          j := secondhand.my_shops();
          report := concat(report, 'shops=', jsonb_array_length(j->'shops'), ' can_open=', jsonb_array_length(j->'can_open'),
                           ' kinds=', (select string_agg(x->>'kind', ',') from jsonb_array_elements(j->'shops') x));

        -- A second company is rejected; its number is released.
        when 'x_create' then
          r := public.create_business_registration('organization', 'มูลนิธิทดสอบปฏิเสธ', num2, 'การกุศล', null, null,
                                                   current_date - 10);
          reg2 := r.id;
          report := concat(report, 'status=', r.status);
        when 'pg_upload_x' then
          insert into storage.objects(bucket_id, name, owner_id, metadata)
          values ('identity-documents', app2 || '/business-registration/' || reg2 || '/' || cert2 || '.png', app2::text,
                  '{"size": 100000, "mimetype": "image/png"}');
          update kaoid_private.security_policy_r14a set dual_review = false where id;
          report := concat(report, 'ok');
        when 'x_attach' then
          r := public.attach_business_document_r27c(reg2, 'certificate', cert2,
                 app2 || '/business-registration/' || reg2 || '/' || cert2 || '.png', 'cert.png');
          report := concat(report, 'doc_status=', r.document_status);
        when 'x_submit' then
          r := public.submit_business_registration(reg2, true);
          org2 := r.organization_id;
          report := concat(report, 'status=', r.status);
        when 'r1_reject' then
          j := public.business_review_decide_r27c(rev1, reg2, false, 'ผู้ยื่นไม่ใช่กรรมการตามหนังสือรับรอง', false);
          report := concat(report, 'status=', j->>'status');
        when 'pg_after_reject' then
          report := concat(report,
            'org=', (select status from public.organizations where id = org2),
            ' member=', (select status from public.organization_members where organization_id = org2),
            ' legal=', (select verification_status || '/' || registration_status from public.organization_legal_profiles
                          where organization_id = org2),
            ' kao_ids=', (select count(*) from public.kao_id_identities where organization_id = org2),
            ' doc=', (select status from public.identity_documents where id = cert2),
            ' notice=', exists (select 1 from public.notifications where profile_id = app2 and message = 'business_rejected'));
        when 'x_create_again' then
          r := public.create_business_registration('organization', 'มูลนิธิทดสอบปฏิเสธ', num2, 'การกุศล');
          report := concat(report, 'status=', r.status);

        when 'pg_invariants' then
          report := concat(report,
            'business_kao_ids=', (select count(*) from public.kao_id_identities where organization_id in (org, org2)),
            ' shops=', (select count(*) from public.shops where organization_id = org),
            ' org_banks_pending=', (select count(*) from public.bank_accounts where organization_id = org and status = 'pending'),
            ' approvals_left=', (select count(*) from public.approval_requests where resource_id in (fv, reg) and status = 'pending'),
            ' legacy_acl=', (select string_agg(p.proname || ':' || has_function_privilege('authenticated', p.oid, 'execute'), ',' order by p.proname)
                              from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                             where n.nspname = 'public' and p.proname in ('create_business_shop', 'issue_business_kao_id',
                                                                         'business_review_decide_r15b', 'attach_business_document_r15a')));
      end case;
    exception when others then
      get stacked diagnostics ctx = pg_exception_context;
      report := concat(report, 'ERR ', sqlerrm,
                       case when sqlerrm like '%does not exist%' or sqlerrm like 'query returned%'
                            then ' @ ' || replace(ctx, E'\n', ' | ') end);
    end;
    report := concat(report, E'\n');
  end loop;
  raise exception 'E2E_REPORT%', E'\n' || report;
end $$;
