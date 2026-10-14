-- R47: Admin Hub RBAC by work line.
-- * Permission catalogue for the 10 admin lines and 11 system roles.
-- * kyc_officer becomes kaoid_admin: every review check now asks for the kaoid.kyc.review permission.
--   kaoid_admin keeps the KYC exemption but only acts from an MFA (aal2) session.
-- * Legacy roles admin / super_admin / support / kyc_officer are switched off; rows stay for audit.
-- * Dangerous permissions only work for staff from an MFA (aal2) session. Owner-only permissions are never granted.
-- * Owner role editor: custom roles and per-permission switches, fresh MFA, audited.
-- * Admin role grants need a second person. While nobody else can approve, a grant waits 24 hours before it
--   starts (cooling-off) and the owner can cancel it.

-- 1. Permission catalogue -------------------------------------------------------------------------------------------
insert into public.permissions(category, resource, action, code, name, description, is_dangerous, is_immutable, sort_order)
values
  ('Admin', 'assignments', 'approve', 'admin.assignments.approve', 'Assignment Approve', 'Second approval for admin role grants', true, true, 54),
  ('Catalog', 'attributes', 'manage', 'catalog.attributes.manage', 'Catalog Attributes Manage', 'Item attributes, sizes and conditions', false, false, 410),
  ('Catalog', 'brands', 'manage', 'catalog.brands.manage', 'Catalog Brands Manage', 'Brand list', false, false, 420),
  ('Listing', 'listings', 'review', 'listing.review', 'Listings Review', 'Listing audit queue', false, false, 500),
  ('Listing', 'listings', 'hide', 'listing.hide', 'Listings Hide', 'Take a listing down', true, false, 510),
  ('Listing', 'keywords', 'manage', 'listing.keywords.manage', 'Prohibited Keywords Manage', 'Prohibited words and items', false, false, 520),
  ('Listing', 'reports', 'handle', 'listing.reports.handle', 'Listing Reports Handle', 'Reports about listings', false, false, 530),
  ('KaoID', 'verifications', 'review', 'kaoid.kyc.review', 'Kao ID Verification Review', 'Personal, business and bank verification reviews', false, true, 600),
  ('KaoID', 'accounts', 'suspend', 'kaoid.account.suspend', 'Kao ID Account Suspend', 'Suspend or restore a Kao ID account', true, false, 610),
  ('KaoID', 'mfa', 'reset', 'kaoid.mfa.reset', 'Kao ID MFA Reset', 'Reset a member''s second factor', true, false, 620),
  ('Dispute', 'snapshots', 'view', 'dispute.snapshot.view', 'Order Snapshot View', 'Listing snapshot kept with an order', false, false, 700),
  ('Dispute', 'shop_reports', 'handle', 'dispute.shop_reports.handle', 'Shop Reports Handle', 'Reports about shops', false, false, 710),
  ('Finance', 'refunds', 'review', 'finance.refunds.review', 'Refunds Review', 'Refund decisions', true, false, 800),
  ('Finance', 'tax', 'view', 'finance.tax.view', 'Tax Records View', 'Tax and fee records', false, false, 810),
  ('Logistics', 'shipments', 'view', 'logistics.shipments.view', 'Shipments View', 'Shipment status', false, false, 900),
  ('Logistics', 'cases', 'resolve', 'logistics.cases.resolve', 'Shipping Cases Resolve', 'Lost or damaged parcels', false, false, 910),
  ('Logistics', 'carriers', 'manage', 'logistics.carriers.manage', 'Carriers Manage', 'Carrier list for Thailand and Japan', false, false, 920),
  ('Support', 'tickets', 'view', 'support.tickets.view', 'Support Tickets View', 'Member questions', false, false, 1000),
  ('Support', 'tickets', 'reply', 'support.tickets.reply', 'Support Tickets Reply', 'Answer member questions', false, false, 1010),
  ('Marketing', 'banners', 'manage', 'marketing.banners.manage', 'Banners Manage', 'Banner drafts', false, false, 1100),
  ('Marketing', 'banners', 'publish', 'marketing.banners.publish', 'Banners Publish', 'Schedule and publish banners', false, false, 1110),
  ('Marketing', 'coupons', 'manage', 'marketing.coupons.manage', 'Coupons Manage', 'Coupons and discounts', true, false, 1120),
  ('Marketing', 'campaigns', 'manage', 'marketing.campaigns.manage', 'Campaigns Manage', 'Campaigns and featured sets', false, false, 1130),
  ('I18n', 'texts', 'edit', 'i18n.texts.edit', 'Translations Edit', 'Text overrides per language', false, false, 1200),
  ('I18n', 'locales', 'manage', 'i18n.locales.manage', 'Locales Manage', 'Languages offered', false, false, 1210),
  ('Audit', 'trail', 'view', 'audit.trail.view', 'Audit Trail View', 'Staff and system activity', false, false, 1300),
  ('Legal', 'data', 'export', 'legal.data.export', 'Legal Data Export', 'Data for authorities', true, false, 1310),
  ('System', 'health', 'view', 'system.health.view', 'System Health View', 'Service health', false, false, 1400),
  ('System', 'jobs', 'view', 'system.jobs.view', 'Background Jobs View', 'Scheduled jobs', false, false, 1410),
  ('System', 'settings', 'manage', 'settings.system.manage', 'System Settings Manage', 'Owner only', true, true, 1420),
  ('System', 'features', 'toggle', 'features.toggle', 'Feature Flags Toggle', 'Owner only', true, true, 1430)
on conflict (code) do nothing;

-- 2. System roles per work line -------------------------------------------------------------------------------------
insert into public.admin_roles(code, name, description, is_system, is_active)
values
  ('catalog_admin', 'Catalog Admin', 'Categories, attributes and brands', true, true),
  ('listing_audit_admin', 'Listing Audit Admin', 'Listing checks, prohibited items and reports', true, true),
  ('kaoid_admin', 'Kao ID Admin', 'Kao ID verification reviews and account safety', true, true),
  ('dispute_admin', 'Dispute Admin', 'Order problems, reviews and shop reports', true, true),
  ('finance_admin', 'Finance Admin', 'Top-ups, withdrawals, refunds and tax', true, true),
  ('logistics_admin', 'Logistics Admin', 'Shipments, carriers and parcel cases', true, true),
  ('cs_operator', 'CS Operator', 'Member support', true, true),
  ('marketing_admin', 'Marketing Admin', 'Banners, coupons and campaigns', true, true),
  ('i18n_admin', 'Localization Admin', 'Translations and system texts', true, true),
  ('legal_security_admin', 'Legal & Security Admin', 'Audit trail, legal requests and second approval', true, true),
  ('tech_support_admin', 'Tech Support Admin', 'Service health and background jobs', true, true)
on conflict (code) do nothing;

do $$
declare
  pairs text[] := array[
    'catalog_admin:admin.dashboard.view', 'catalog_admin:marketplace.categories.manage',
    'catalog_admin:catalog.attributes.manage', 'catalog_admin:catalog.brands.manage',
    'listing_audit_admin:admin.dashboard.view', 'listing_audit_admin:listing.review', 'listing_audit_admin:listing.hide',
    'listing_audit_admin:listing.keywords.manage', 'listing_audit_admin:listing.reports.handle',
    'kaoid_admin:admin.dashboard.view', 'kaoid_admin:kaoid.kyc.review', 'kaoid_admin:kaoid.account.suspend',
    'kaoid_admin:kaoid.mfa.reset',
    'dispute_admin:admin.dashboard.view', 'dispute_admin:marketplace.orders.resolve',
    'dispute_admin:marketplace.reviews.moderate', 'dispute_admin:dispute.snapshot.view',
    'dispute_admin:dispute.shop_reports.handle',
    'finance_admin:admin.dashboard.view', 'finance_admin:finance.view', 'finance_admin:finance.transactions.view',
    'finance_admin:finance.payouts.view', 'finance_admin:finance.bank_accounts.view', 'finance_admin:wallet.deposit.approve',
    'finance_admin:wallet.deposit.settings', 'finance_admin:wallet.withdraw.approve', 'finance_admin:finance.refunds.review',
    'finance_admin:finance.tax.view',
    'logistics_admin:admin.dashboard.view', 'logistics_admin:logistics.shipments.view',
    'logistics_admin:logistics.cases.resolve', 'logistics_admin:logistics.carriers.manage',
    'cs_operator:admin.dashboard.view', 'cs_operator:support.tickets.view', 'cs_operator:support.tickets.reply',
    'cs_operator:dispute.snapshot.view',
    'marketing_admin:admin.dashboard.view', 'marketing_admin:marketing.banners.manage',
    'marketing_admin:marketing.banners.publish', 'marketing_admin:marketing.coupons.manage',
    'marketing_admin:marketing.campaigns.manage',
    'i18n_admin:admin.dashboard.view', 'i18n_admin:i18n.texts.edit', 'i18n_admin:i18n.locales.manage',
    'i18n_admin:content.system.manage',
    'legal_security_admin:admin.dashboard.view', 'legal_security_admin:audit.trail.view',
    'legal_security_admin:legal.data.export', 'legal_security_admin:admin.assignments.approve',
    'legal_security_admin:approval.history.view',
    'tech_support_admin:admin.dashboard.view', 'tech_support_admin:system.health.view',
    'tech_support_admin:system.jobs.view'];
  missing text;
begin
  select string_agg(x, ', ') into missing from unnest(pairs) x
   where not exists (select 1 from public.admin_roles r where r.code = split_part(x, ':', 1))
      or not exists (select 1 from public.permissions p where p.code = split_part(x, ':', 2));
  if missing is not null then raise exception 'R47 stopped: unknown role or permission %', missing; end if;
  insert into public.role_permissions(role_id, permission_id)
  select r.id, p.id from unnest(pairs) x
    join public.admin_roles r on r.code = split_part(x, ':', 1)
    join public.permissions p on p.code = split_part(x, ':', 2)
  on conflict (role_id, permission_id) do nothing;
end $$;

insert into public.approval_policies(code, name, description, resource, action, minimum_approvals, is_active, is_immutable)
values ('admin_role_grant_r47', 'Admin role grant', 'Owner request plus a second approver', 'admin_role_grant', 'grant', 2, true, true)
on conflict (code) do nothing;

-- 3. kyc_officer -> kaoid_admin, legacy roles off -------------------------------------------------------------------
-- System events with no human actor: this migration and cooling-off grants that reach their start time.
alter table public.activity_logs drop constraint activity_system_actor_r11a;
alter table public.activity_logs add constraint activity_system_actor_r11a check (
  profile_id is not null
  or action in ('kyc.expire', 'governance.role.migrate', 'governance.role.retire', 'governance.grant.activate'));

with moved as (
  insert into public.admin_assignments(profile_id, role_id, assigned_by, starts_at, expires_at, is_active)
  select a.profile_id, k.id, a.assigned_by, a.starts_at, a.expires_at, true
    from public.admin_assignments a
    join public.admin_roles o on o.id = a.role_id and o.code = 'kyc_officer'
    join public.admin_roles k on k.code = 'kaoid_admin'
   where a.is_active and (a.expires_at is null or a.expires_at > now())
  on conflict (profile_id, role_id) do update set is_active = true, expires_at = excluded.expires_at, updated_at = now()
  returning id, profile_id, expires_at)
insert into public.activity_logs(profile_id, action, target_table, target_id, description)
select null, 'governance.role.migrate', 'admin_assignments', id,
       jsonb_build_object('target_profile_id', profile_id, 'role', 'kaoid_admin', 'from_role', 'kyc_officer',
                          'expires_at', expires_at, 'migration', 'r47')::text
  from moved;

with retired as (
  update public.admin_assignments a set is_active = false, updated_at = now()
    from public.admin_roles r
   where r.id = a.role_id and r.code in ('admin', 'super_admin', 'support', 'kyc_officer') and a.is_active
  returning a.id, a.profile_id, r.code)
insert into public.activity_logs(profile_id, action, target_table, target_id, description)
select null, 'governance.role.retire', 'admin_assignments', id,
       jsonb_build_object('target_profile_id', profile_id, 'role', code, 'reason', 'legacy_role_retired',
                          'migration', 'r47')::text
  from retired;

update public.admin_roles set is_active = false, updated_at = now()
 where code in ('admin', 'super_admin', 'support', 'kyc_officer') and is_active;

-- 4. Grant requests --------------------------------------------------------------------------------------------------
create table if not exists kaoid_private.staff_grants_r47 (
  id uuid primary key default gen_random_uuid(),
  target_profile_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.admin_roles(id) on delete restrict,
  expires_at timestamptz,
  mode text not null check (mode in ('two_person', 'cooling_off')),
  status text not null default 'pending' check (status in ('pending', 'activated', 'rejected', 'cancelled', 'expired')),
  requested_by uuid not null references public.profiles(id) on delete restrict,
  activate_at timestamptz,
  assignment_id uuid references public.admin_assignments(id) on delete set null,
  approval_request_id uuid references public.approval_requests(id) on delete set null,
  decided_by uuid references public.profiles(id) on delete set null,
  decided_at timestamptz,
  decision_reason text check (decision_reason is null or length(decision_reason) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((mode = 'cooling_off') = (activate_at is not null))
);
create unique index if not exists staff_grants_r47_one_pending
  on kaoid_private.staff_grants_r47(target_profile_id, role_id) where status = 'pending';
create index if not exists staff_grants_r47_status on kaoid_private.staff_grants_r47(status, created_at desc);
alter table kaoid_private.staff_grants_r47 enable row level security;
revoke all on kaoid_private.staff_grants_r47 from public, anon, authenticated;

-- 5. Permission helpers ----------------------------------------------------------------------------------------------
create or replace function kaoid_private.owner_only_permission_r47(p_code text)
returns boolean language sql immutable set search_path = '' as $$
  select p_code = any (array['admin.assignments.create', 'admin.assignments.update', 'admin.assignments.delete',
    'admin.owners.update', 'admin.roles.create', 'admin.roles.update', 'admin.roles.delete',
    'settings.system.manage', 'features.toggle']);
$$;

-- Readiness of a role holder judged from outside their session (notices, second approver, staff list).
create or replace function kaoid_private.role_holder_ready_r47(p_profile uuid, p_role text)
returns boolean language sql stable security definer set search_path = '' as $$
  select case when p_role = 'kaoid_admin'
    then exists (select 1 from auth.mfa_factors f where f.user_id = p_profile and f.status::text = 'verified')
    else exists (select 1 from public.verifications v join public.kao_id_identities k on k.profile_id = v.profile_id
                  where v.profile_id = p_profile and v.status = 'approved' and k.status = 'active') end;
$$;

create or replace function kaoid_private.profile_permission_r47(p_profile uuid, p_code text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles p
     where p.id = p_profile and p.account_status = 'active' and p.deleted_at is null
       and (exists (select 1 from public.company_owners o where o.profile_id = p.id)
         or (not kaoid_private.owner_only_permission_r47(p_code) and exists (
           select 1 from public.admin_assignments a
             join public.admin_roles r on r.id = a.role_id and r.is_active
             join public.role_permissions rp on rp.role_id = r.id
             join public.permissions m on m.id = rp.permission_id and m.is_active and m.code = p_code
            where a.profile_id = p.id and a.is_active and a.starts_at <= now()
              and (a.expires_at is null or a.expires_at > now())
              and kaoid_private.role_holder_ready_r47(p.id, r.code)
              and (not m.is_dangerous or exists (select 1 from auth.mfa_factors f
                                                  where f.user_id = p.id and f.status::text = 'verified'))))));
$$;

create or replace function kaoid_private.grant_approver_ready_r47(p_requester uuid, p_target uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles p
     where p.id is distinct from p_requester and p.id is distinct from p_target
       and (exists (select 1 from public.company_owners o where o.profile_id = p.id)
         or exists (select 1 from public.admin_assignments a where a.profile_id = p.id and a.is_active))
       and exists (select 1 from auth.mfa_factors f where f.user_id = p.id and f.status::text = 'verified')
       and kaoid_private.profile_permission_r47(p.id, 'admin.assignments.approve'));
$$;

create or replace function kaoid_private.effective_roles_r13a()
returns table(role_id uuid, code text, name text) language sql stable security definer set search_path = '' as $$
  select distinct r.id, r.code, r.name from public.admin_assignments a
    join public.admin_roles r on r.id = a.role_id
   where kaoid_private.account_active_r9f() and kaoid_private.privileged_ready_r14a() and a.profile_id = auth.uid()
     and a.is_active and r.is_active and a.starts_at <= now()
     and (a.expires_at is null or a.expires_at > now())
     and case when r.code = 'kaoid_admin' then coalesce(kaoid_private.aal2_r14a(), false)
         else exists (select 1 from public.verifications v join public.kao_id_identities k on k.profile_id = v.profile_id
                       where v.profile_id = a.profile_id and v.status = 'approved' and k.status = 'active') end;
$$;

create or replace function kaoid_private.permission_r13a(p_code text)
returns boolean language sql stable security definer set search_path = '' as $$
  select kaoid_private.account_active_r9f() and (
    kaoid_private.company_owner_authority() or (
      not kaoid_private.owner_only_permission_r47(p_code)
      and exists (select 1 from kaoid_private.effective_roles_r13a() r
                    join public.role_permissions rp on rp.role_id = r.role_id
                    join public.permissions p on p.id = rp.permission_id
                   where p.code = p_code and p.is_active
                     and (not p.is_dangerous or coalesce(kaoid_private.aal2_r14a(), false)))));
$$;

create or replace function kaoid_private.can_review_r7c()
returns boolean language sql stable security definer set search_path = '' as $$
  select kaoid_private.permission_r13a('kaoid.kyc.review');
$$;

create or replace function kaoid_private.review_recipients_r14b(p_applicant uuid, p_exclude uuid default null)
returns setof uuid language sql stable security definer set search_path = '' as $$
  select p.id from public.profiles p
   where p.account_status = 'active' and p.deleted_at is null
     and p.id is distinct from p_applicant and p.id is distinct from p_exclude
     and (exists (select 1 from public.company_owners o where o.profile_id = p.id)
       or exists (select 1 from public.admin_assignments a where a.profile_id = p.id and a.is_active))
     and kaoid_private.profile_permission_r47(p.id, 'kaoid.kyc.review');
$$;

create or replace function kaoid_private.security_status_r14a()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare own boolean; ready integer;
begin
  if not kaoid_private.account_active_r9f() then raise exception 'session_required' using errcode = '42501'; end if;
  select exists (select 1 from public.company_owners where profile_id = auth.uid()) into own;
  select count(*) into ready from public.profiles p
   where p.account_status = 'active' and p.deleted_at is null
     and not exists (select 1 from public.company_owners o where o.profile_id = p.id)
     and exists (select 1 from public.admin_assignments a where a.profile_id = p.id and a.is_active)
     and exists (select 1 from auth.mfa_factors f where f.user_id = p.id and f.status::text = 'verified')
     and kaoid_private.profile_permission_r47(p.id, 'kaoid.kyc.review');
  return jsonb_build_object('owner', own, 'aal2', coalesce(kaoid_private.aal2_r14a(), false),
    'verified_factors', (select count(*) from auth.mfa_factors where user_id = auth.uid() and status::text = 'verified'),
    'ready_reviewers', case when own then ready else null end,
    'mfa_required', (select mfa_required from kaoid_private.security_policy_r14a where id),
    'dual_review', (select dual_review from kaoid_private.security_policy_r14a where id));
end $$;

-- 6. Two-person Kao ID reviews: first vote must still come from a ready reviewer --------------------------------------
create or replace function kaoid_private.review_vote_r14a(p_id uuid, p_approve boolean, p_reason text, p_recovery boolean)
returns boolean language plpgsql security definer set search_path = '' as $$
declare target uuid; ar public.approval_requests%rowtype; meta jsonb; rid uuid; sid uuid; fingerprint text; kind text; first_ok boolean;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501';end if;
 if kaoid_private.org_bank_conflict_r27c(p_id,auth.uid()) then raise exception 'request_not_available' using errcode='42501';end if;
 perform kaoid_private.require_fresh_mfa_r14a();
 if not (select dual_review from kaoid_private.security_policy_r14a where id) then return true;end if;
 if p_approve is null or length(coalesce(p_reason,''))>1000 or (not p_approve and length(btrim(coalesce(p_reason,'')))<3) then raise exception 'invalid_decision';end if;
 select requested_by into target from public.verification_requests where id=p_id;
 if target is null then select coalesce(profile_id,submitted_by) into target from public.financial_verifications where id=p_id;end if;
 if target is null or target=auth.uid() then raise exception 'request_not_available' using errcode='42501';end if;
 kind:=case when p_recovery then 'kaoid_recovery' else 'kaoid_review' end;
 perform pg_advisory_xact_lock(hashtextextended('dual-review:'||p_id,141));
 if exists(select 1 from public.verification_requests where id=p_id and status not in ('pending','under_review')) or exists(select 1 from public.financial_verifications where id=p_id and status<>'pending') then return true;end if;
 fingerprint:=kaoid_private.review_fingerprint_r14a(p_id);
 select * into ar from public.approval_requests where resource=kind and resource_id=p_id and status='pending' for update;
 if found then
  select metadata into meta from public.approval_histories where approval_request_id=ar.id and event='request_created' order by created_at,id limit 1;
  select exists(select 1 from auth.mfa_factors f where f.user_id=ar.requested_by and f.status::text='verified')
     and kaoid_private.profile_permission_r47(ar.requested_by,'kaoid.kyc.review') into first_ok;
  if ar.expires_at<=now() or meta->>'fingerprint' is distinct from fingerprint or not first_ok then
   update public.approval_requests set status='expired',completed_at=now(),updated_at=now() where id=ar.id;
   insert into public.approval_histories(approval_request_id,actor_profile_id,event,previous_status,current_status,comment) values(ar.id,auth.uid(),'expired','pending','expired','Evidence, reviewer authority or time changed');
   ar.id:=null;
  elsif ar.requested_by=auth.uid() then
   return false;
  else
   if (meta->>'approve')::boolean is distinct from p_approve then
    update public.approval_requests set status='rejected',completed_at=now(),updated_at=now() where id=ar.id;
    insert into public.approval_histories(approval_request_id,actor_profile_id,event,previous_status,current_status,comment) values(ar.id,auth.uid(),'rejected','pending','rejected',btrim(p_reason));
    return false;
   end if;
   insert into public.approval_steps(approval_request_id,role_id,step_order,status,approved_by,approved_at,comment) values(ar.id,(select id from public.admin_roles where code='kaoid_admin'),2,'approved',auth.uid(),now(),p_reason) returning id into sid;
   update public.approval_requests set status='approved',completed_at=now(),updated_at=now() where id=ar.id;
   insert into public.approval_histories(approval_request_id,approval_step_id,actor_profile_id,event,previous_status,current_status,comment)
   values(ar.id,sid,auth.uid(),'completed','pending','approved',p_reason);
   return true;
  end if;
 end if;
 insert into public.approval_requests(policy_id,requested_by,resource,resource_id,status,reason,expires_at)
 select id,auth.uid(),kind,p_id,'pending',p_reason,now()+interval '24 hours' from public.approval_policies where code='kaoid_two_person_r14a' returning id into rid;
 insert into public.approval_steps(approval_request_id,role_id,step_order,status,approved_by,approved_at,comment) values(rid,(select id from public.admin_roles where code='kaoid_admin'),1,'approved',auth.uid(),now(),p_reason) returning id into sid;
 insert into public.approval_histories(approval_request_id,approval_step_id,actor_profile_id,event,current_status,metadata)
 values(rid,sid,auth.uid(),'request_created','pending',jsonb_build_object('approve',p_approve,'fingerprint',fingerprint,'policy_version','r47'));
 return false;
end $$;

create or replace function kaoid_private.business_review_vote_r15b(p_id uuid, p_approve boolean, p_reason text)
returns boolean language plpgsql security definer set search_path = '' as $$
declare
  ar public.approval_requests%rowtype;
  meta jsonb;
  rid uuid;
  sid uuid;
  hid uuid;
  applicant uuid;
  recipient uuid;
  fingerprint text;
  first_ok boolean;
begin
  if not (select dual_review from kaoid_private.security_policy_r14a where id) then return true; end if;
  select user_id into applicant from public.business_registrations where id = p_id;
  fingerprint := kaoid_private.business_review_fingerprint_r15b(p_id);

  select * into ar from public.approval_requests
   where resource = 'kaoid_business_review' and resource_id = p_id and status = 'pending'
   for update;
  if found then
    select metadata into meta from public.approval_histories
     where approval_request_id = ar.id and event = 'request_created'
     order by created_at, id limit 1;
    select exists (select 1 from auth.mfa_factors f where f.user_id = ar.requested_by and f.status::text = 'verified')
       and kaoid_private.profile_permission_r47(ar.requested_by, 'kaoid.kyc.review') into first_ok;
    if ar.expires_at <= now() or meta ->> 'fingerprint' is distinct from fingerprint or not first_ok then
      update public.approval_requests set status = 'expired', completed_at = now(), updated_at = now() where id = ar.id;
      insert into public.approval_histories(approval_request_id, actor_profile_id, event, previous_status, current_status, comment)
      values (ar.id, auth.uid(), 'expired', 'pending', 'expired', 'Evidence, reviewer authority or time changed');
    elsif ar.requested_by = auth.uid() then
      return false;
    elsif (meta ->> 'approve')::boolean is distinct from p_approve then
      update public.approval_requests set status = 'rejected', completed_at = now(), updated_at = now() where id = ar.id;
      insert into public.approval_histories(approval_request_id, actor_profile_id, event, previous_status, current_status, comment)
      values (ar.id, auth.uid(), 'rejected', 'pending', 'rejected', btrim(p_reason))
      returning id into hid;
      for recipient in select * from kaoid_private.review_recipients_r14b(applicant, null) loop
        perform kaoid_private.emit_notice_r10a(recipient, 'business-vote:' || hid || ':' || recipient, 'business_review_restart', p_id);
      end loop;
      return false;
    else
      insert into public.approval_steps(approval_request_id, role_id, step_order, status, approved_by, approved_at, comment)
      values (ar.id, (select id from public.admin_roles where code = 'kaoid_admin'), 2, 'approved', auth.uid(), now(), p_reason)
      returning id into sid;
      update public.approval_requests set status = 'approved', completed_at = now(), updated_at = now() where id = ar.id;
      insert into public.approval_histories(approval_request_id, approval_step_id, actor_profile_id, event, previous_status, current_status, comment)
      values (ar.id, sid, auth.uid(), 'completed', 'pending', 'approved', p_reason);
      return true;
    end if;
  end if;

  insert into public.approval_requests(policy_id, requested_by, resource, resource_id, status, reason, expires_at)
  select id, auth.uid(), 'kaoid_business_review', p_id, 'pending', p_reason, now() + interval '24 hours'
    from public.approval_policies where code = 'kaoid_two_person_r14a'
  returning id into rid;
  if rid is null then raise exception 'approval_policy_missing' using errcode = '55000'; end if;
  insert into public.approval_steps(approval_request_id, role_id, step_order, status, approved_by, approved_at, comment)
  values (rid, (select id from public.admin_roles where code = 'kaoid_admin'), 1, 'approved', auth.uid(), now(), p_reason)
  returning id into sid;
  insert into public.approval_histories(approval_request_id, approval_step_id, actor_profile_id, event, current_status, metadata)
  values (rid, sid, auth.uid(), 'request_created', 'pending',
          jsonb_build_object('approve', p_approve, 'fingerprint', fingerprint, 'policy_version', 'r47'))
  returning id into hid;
  for recipient in select * from kaoid_private.review_recipients_r14b(applicant, auth.uid()) loop
    perform kaoid_private.emit_notice_r10a(recipient, 'business-vote:' || hid || ':' || recipient, 'business_review_second', p_id);
  end loop;
  return false;
end $$;

-- 7. Grants: settle, request, revoke, cancel, decide, queue -----------------------------------------------------------
create or replace function kaoid_private.staff_grants_settle_r47()
returns void language plpgsql security definer set search_path = '' as $$
begin
  with done as (
    update kaoid_private.staff_grants_r47 g set status = 'activated', decided_at = g.activate_at, updated_at = now()
     where g.mode = 'cooling_off' and g.status = 'pending' and g.activate_at <= now()
       and exists (select 1 from public.admin_assignments a where a.id = g.assignment_id and a.is_active)
    returning g.id, g.target_profile_id, g.role_id, g.assignment_id, g.requested_by, g.expires_at)
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  select null, 'governance.grant.activate', 'admin_assignments', d.assignment_id,
         jsonb_build_object('grant_id', d.id, 'target_profile_id', d.target_profile_id, 'role', r.code,
                            'expires_at', d.expires_at, 'requested_by', d.requested_by, 'mode', 'cooling_off')::text
    from done d join public.admin_roles r on r.id = d.role_id;

  update kaoid_private.staff_grants_r47 g set status = 'cancelled', decided_at = now(), updated_at = now()
   where g.mode = 'cooling_off' and g.status = 'pending'
     and not exists (select 1 from public.admin_assignments a where a.id = g.assignment_id and a.is_active);

  with gone as (
    update kaoid_private.staff_grants_r47 g set status = 'expired', decided_at = now(), updated_at = now()
      from public.approval_requests q
     where q.id = g.approval_request_id and g.mode = 'two_person' and g.status = 'pending' and q.expires_at <= now()
    returning g.approval_request_id),
  closed as (
    update public.approval_requests q set status = 'expired', completed_at = now(), updated_at = now()
      from gone where q.id = gone.approval_request_id and q.status = 'pending'
    returning q.id)
  insert into public.approval_histories(approval_request_id, event, previous_status, current_status, comment)
  select id, 'expired', 'pending', 'expired', 'Second approval window closed' from closed;
end $$;

create or replace function kaoid_private.staff_assign_r9b(p_target text, p_role text, p_expires timestamptz default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  target uuid;
  rid uuid;
  role_code text := lower(btrim(p_role));
  existing public.admin_assignments%rowtype;
  grant_id uuid := gen_random_uuid();
  req uuid;
  assignment uuid;
  starts timestamptz;
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode = '42501'; end if;
  perform kaoid_private.staff_grants_settle_r47();
  if p_expires is not null and p_expires <= now() then raise exception 'invalid_expiry'; end if;
  select p.id into target from public.profiles p join auth.users u on u.id = p.id
    left join public.kao_id_identities k on k.profile_id = p.id
   where (p.id::text = btrim(p_target) or k.kao_id = upper(btrim(p_target)))
     and p.account_status = 'active' and p.deleted_at is null and u.email_confirmed_at is not null
     and coalesce(u.email, '') <> '';
  if target is null then raise exception 'target_unavailable'; end if;
  if target = auth.uid() or exists (select 1 from public.company_owners where profile_id = target) then
    raise exception 'owner_role_protected';
  end if;
  select id into rid from public.admin_roles where code = role_code and is_active;
  if rid is null then raise exception 'role_unavailable'; end if;
  -- kaoid_admin reviews identities, so it cannot wait for its own KYC; it acts only from an MFA session instead.
  if role_code <> 'kaoid_admin' and not kaoid_private.role_holder_ready_r47(target, role_code) then
    raise exception 'target_kyc_required';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(target::text || rid::text, 919));
  if exists (select 1 from kaoid_private.staff_grants_r47 where target_profile_id = target and role_id = rid and status = 'pending') then
    raise exception 'grant_pending';
  end if;
  select * into existing from public.admin_assignments where profile_id = target and role_id = rid for update;
  if found and existing.is_active then
    if existing.starts_at <= now() and existing.expires_at is not distinct from p_expires then return existing.id; end if;
    raise exception 'role_already_assigned';
  end if;

  if kaoid_private.grant_approver_ready_r47(auth.uid(), target) then
    insert into public.approval_requests(policy_id, requested_by, resource, resource_id, status, expires_at)
    select id, auth.uid(), 'admin_role_grant', grant_id, 'pending', now() + interval '72 hours'
      from public.approval_policies where code = 'admin_role_grant_r47' and is_active
    returning id into req;
    if req is null then raise exception 'approval_policy_missing' using errcode = '55000'; end if;
    insert into public.approval_histories(approval_request_id, actor_profile_id, event, current_status, metadata)
    values (req, auth.uid(), 'request_created', 'pending',
            jsonb_build_object('grant_id', grant_id, 'target_profile_id', target, 'role', role_code,
                               'expires_at', p_expires, 'policy_version', 'r47'));
    insert into kaoid_private.staff_grants_r47(id, target_profile_id, role_id, expires_at, mode, requested_by, approval_request_id)
    values (grant_id, target, rid, p_expires, 'two_person', auth.uid(), req);
    insert into public.activity_logs(profile_id, action, target_table, target_id, description)
    values (auth.uid(), 'governance.grant.request', 'staff_grants', grant_id,
            jsonb_build_object('grant_id', grant_id, 'target_profile_id', target, 'role', role_code,
                               'expires_at', p_expires, 'mode', 'two_person')::text);
  else
    starts := now() + interval '24 hours';
    if p_expires is not null and p_expires <= starts then raise exception 'invalid_expiry'; end if;
    insert into public.admin_assignments(profile_id, role_id, assigned_by, starts_at, expires_at, is_active)
    values (target, rid, auth.uid(), starts, p_expires, true)
    on conflict (profile_id, role_id) do update set assigned_by = excluded.assigned_by, starts_at = excluded.starts_at,
      expires_at = excluded.expires_at, is_active = true, updated_at = now()
    returning id into assignment;
    insert into kaoid_private.staff_grants_r47(id, target_profile_id, role_id, expires_at, mode, requested_by,
                                               activate_at, assignment_id)
    values (grant_id, target, rid, p_expires, 'cooling_off', auth.uid(), starts, assignment);
    insert into public.activity_logs(profile_id, action, target_table, target_id, description)
    values (auth.uid(), 'governance.grant.schedule', 'admin_assignments', assignment,
            jsonb_build_object('grant_id', grant_id, 'target_profile_id', target, 'role', role_code,
                               'expires_at', p_expires, 'mode', 'cooling_off', 'activate_at', starts)::text);
  end if;
  return grant_id;
end $$;

create or replace function kaoid_private.staff_revoke_r9b(p_assignment uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
declare a public.admin_assignments%rowtype; code text;
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode = '42501'; end if;
  perform kaoid_private.staff_grants_settle_r47();
  select * into a from public.admin_assignments where id = p_assignment for update;
  if not found then raise exception 'assignment_missing'; end if;
  if not a.is_active then return true; end if;
  select r.code into code from public.admin_roles r where r.id = a.role_id;
  update public.admin_assignments set is_active = false, updated_at = now() where id = a.id;
  update kaoid_private.staff_grants_r47 set status = 'cancelled', decided_by = auth.uid(), decided_at = now(), updated_at = now()
   where assignment_id = a.id and status = 'pending';
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (auth.uid(), 'governance.role.revoke', 'admin_assignments', a.id,
          jsonb_build_object('target_profile_id', a.profile_id, 'role', code, 'expires_at', a.expires_at)::text);
  return true;
end $$;

create or replace function kaoid_private.grant_cancel_r47(p_grant uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
declare g kaoid_private.staff_grants_r47%rowtype; code text;
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode = '42501'; end if;
  perform kaoid_private.staff_grants_settle_r47();
  select * into g from kaoid_private.staff_grants_r47 where id = p_grant for update;
  if not found or g.status <> 'pending' then raise exception 'grant_unavailable'; end if;
  select r.code into code from public.admin_roles r where r.id = g.role_id;
  if g.mode = 'cooling_off' then
    update public.admin_assignments set is_active = false, updated_at = now() where id = g.assignment_id and is_active;
  else
    update public.approval_requests set status = 'cancelled', completed_at = now(), updated_at = now()
     where id = g.approval_request_id and status = 'pending';
    insert into public.approval_histories(approval_request_id, actor_profile_id, event, previous_status, current_status, comment)
    values (g.approval_request_id, auth.uid(), 'cancelled', 'pending', 'cancelled', 'Cancelled by owner');
  end if;
  update kaoid_private.staff_grants_r47 set status = 'cancelled', decided_by = auth.uid(), decided_at = now(), updated_at = now()
   where id = g.id;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (auth.uid(), 'governance.grant.cancel', 'staff_grants', g.id,
          jsonb_build_object('grant_id', g.id, 'target_profile_id', g.target_profile_id, 'role', code, 'mode', g.mode)::text);
  return true;
end $$;

create or replace function kaoid_private.grant_decide_r47(p_grant uuid, p_approve boolean, p_reason text)
returns boolean language plpgsql security definer set search_path = '' as $$
declare g kaoid_private.staff_grants_r47%rowtype; code text; assignment uuid; me uuid := auth.uid();
begin
  if not coalesce(kaoid_private.aal2_r14a(), false) then raise exception 'mfa_required' using errcode = '42501'; end if;
  perform kaoid_private.require_fresh_mfa_r14a();
  if not kaoid_private.permission_r13a('admin.assignments.approve') then
    raise exception 'approver_required' using errcode = '42501';
  end if;
  if p_approve is null or length(coalesce(p_reason, '')) > 1000
     or (not p_approve and length(btrim(coalesce(p_reason, ''))) < 3) then
    raise exception 'invalid_decision';
  end if;
  perform kaoid_private.staff_grants_settle_r47();
  select * into g from kaoid_private.staff_grants_r47 where id = p_grant for update;
  if not found or g.status <> 'pending' or g.mode <> 'two_person' then raise exception 'grant_unavailable'; end if;
  if g.requested_by = me or g.target_profile_id = me then
    raise exception 'second_person_required' using errcode = '42501';
  end if;
  select r.code into code from public.admin_roles r where r.id = g.role_id;
  perform pg_advisory_xact_lock(hashtextextended(g.target_profile_id::text || g.role_id::text, 919));

  if not p_approve then
    update kaoid_private.staff_grants_r47 set status = 'rejected', decided_by = me, decided_at = now(),
      decision_reason = btrim(p_reason), updated_at = now() where id = g.id;
    update public.approval_requests set status = 'rejected', completed_at = now(), updated_at = now()
     where id = g.approval_request_id and status = 'pending';
    insert into public.approval_histories(approval_request_id, actor_profile_id, event, previous_status, current_status, comment)
    values (g.approval_request_id, me, 'rejected', 'pending', 'rejected', btrim(p_reason));
    insert into public.activity_logs(profile_id, action, target_table, target_id, description)
    values (me, 'governance.grant.reject', 'staff_grants', g.id,
            jsonb_build_object('grant_id', g.id, 'target_profile_id', g.target_profile_id, 'role', code,
                               'requested_by', g.requested_by, 'reason', btrim(p_reason))::text);
    return false;
  end if;

  if not exists (select 1 from public.admin_roles where id = g.role_id and is_active) then
    raise exception 'role_unavailable';
  end if;
  if not exists (select 1 from public.profiles p join auth.users u on u.id = p.id
                  where p.id = g.target_profile_id and p.account_status = 'active' and p.deleted_at is null
                    and u.email_confirmed_at is not null)
     or exists (select 1 from public.company_owners where profile_id = g.target_profile_id) then
    raise exception 'target_unavailable';
  end if;
  if code <> 'kaoid_admin' and not kaoid_private.role_holder_ready_r47(g.target_profile_id, code) then
    raise exception 'target_kyc_required';
  end if;
  if g.expires_at is not null and g.expires_at <= now() then raise exception 'invalid_expiry'; end if;

  insert into public.admin_assignments(profile_id, role_id, assigned_by, starts_at, expires_at, is_active)
  values (g.target_profile_id, g.role_id, g.requested_by, now(), g.expires_at, true)
  on conflict (profile_id, role_id) do update set assigned_by = excluded.assigned_by, starts_at = excluded.starts_at,
    expires_at = excluded.expires_at, is_active = true, updated_at = now()
  returning id into assignment;
  update public.approval_requests set status = 'approved', completed_at = now(), updated_at = now()
   where id = g.approval_request_id and status = 'pending';
  insert into public.approval_histories(approval_request_id, actor_profile_id, event, previous_status, current_status, comment)
  values (g.approval_request_id, me, 'completed', 'pending', 'approved', nullif(btrim(coalesce(p_reason, '')), ''));
  update kaoid_private.staff_grants_r47 set status = 'activated', assignment_id = assignment, decided_by = me,
    decided_at = now(), decision_reason = nullif(btrim(coalesce(p_reason, '')), ''), updated_at = now() where id = g.id;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (me, 'governance.role.assign', 'admin_assignments', assignment,
          jsonb_build_object('target_profile_id', g.target_profile_id, 'role', code, 'expires_at', g.expires_at,
                             'grant_id', g.id, 'requested_by', g.requested_by, 'approved_by', me,
                             'mode', 'two_person')::text);
  return true;
end $$;

create or replace function kaoid_private.grant_queue_r47()
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  if not kaoid_private.permission_r13a('admin.assignments.approve') then
    raise exception 'approver_required' using errcode = '42501';
  end if;
  perform kaoid_private.staff_grants_settle_r47();
  return (select coalesce(jsonb_agg(x order by x.created_at), '[]'::jsonb) from (
    select g.id, g.target_profile_id, tp.display_name as target_name, tc.account_code as target_code,
           r.code, r.name as role_name, g.expires_at, g.requested_by, rq.display_name as requester_name,
           rc.account_code as requester_code, g.created_at, q.expires_at as decide_before,
           (g.requested_by <> auth.uid() and g.target_profile_id <> auth.uid()) as can_decide,
           (select coalesce(jsonb_agg(jsonb_build_object('code', m.code, 'dangerous', m.is_dangerous)
                                      order by m.category, m.sort_order, m.code), '[]'::jsonb)
              from public.role_permissions rp join public.permissions m on m.id = rp.permission_id and m.is_active
             where rp.role_id = r.id) as permissions
      from kaoid_private.staff_grants_r47 g
      join public.admin_roles r on r.id = g.role_id
      join public.profiles tp on tp.id = g.target_profile_id
      join public.profiles rq on rq.id = g.requested_by
      left join kaoid_private.account_refs_r10c tc on tc.profile_id = g.target_profile_id
      left join kaoid_private.account_refs_r10c rc on rc.profile_id = g.requested_by
      left join public.approval_requests q on q.id = g.approval_request_id
     where g.status = 'pending' and g.mode = 'two_person') x);
end $$;

-- 8. Owner role editor -----------------------------------------------------------------------------------------------
create or replace function kaoid_private.role_create_r47(p_code text, p_name text, p_description text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare c text := lower(btrim(coalesce(p_code, ''))); n text := btrim(coalesce(p_name, ''));
        d text := nullif(btrim(coalesce(p_description, '')), ''); rid uuid;
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode = '42501'; end if;
  if c !~ '^custom_[a-z0-9_]{2,40}$' then raise exception 'role_code_invalid'; end if;
  if length(n) not between 2 and 60 or length(coalesce(d, '')) > 300 then raise exception 'role_name_invalid'; end if;
  if exists (select 1 from public.admin_roles where code = c or lower(name) = lower(n)) then
    raise exception 'role_name_taken';
  end if;
  insert into public.admin_roles(code, name, description, is_system, is_active) values (c, n, d, false, true)
  returning id into rid;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (auth.uid(), 'governance.role.create', 'admin_roles', rid,
          jsonb_build_object('role', c, 'name', n, 'description', d)::text);
  return rid;
end $$;

create or replace function kaoid_private.role_dangerous_in_use_r47(p_role uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admin_assignments a
                  where a.role_id = p_role and a.is_active and (a.expires_at is null or a.expires_at > now()));
$$;

create or replace function kaoid_private.role_update_r47(p_role text, p_name text, p_description text, p_active boolean)
returns boolean language plpgsql security definer set search_path = '' as $$
declare r public.admin_roles%rowtype; n text := btrim(coalesce(p_name, ''));
        d text := nullif(btrim(coalesce(p_description, '')), '');
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode = '42501'; end if;
  select * into r from public.admin_roles where code = lower(btrim(coalesce(p_role, ''))) for update;
  if not found then raise exception 'role_unavailable'; end if;
  if r.is_system then raise exception 'role_protected'; end if;
  if p_active is null or length(n) not between 2 and 60 or length(coalesce(d, '')) > 300 then
    raise exception 'role_name_invalid';
  end if;
  if exists (select 1 from public.admin_roles where id <> r.id and lower(name) = lower(n)) then
    raise exception 'role_name_taken';
  end if;
  if p_active and not r.is_active and kaoid_private.role_dangerous_in_use_r47(r.id)
     and exists (select 1 from public.role_permissions rp join public.permissions m on m.id = rp.permission_id
                  where rp.role_id = r.id and m.is_dangerous and m.is_active) then
    raise exception 'role_in_use_dangerous';
  end if;
  if r.name = n and r.description is not distinct from d and r.is_active = p_active then return true; end if;
  update public.admin_roles set name = n, description = d, is_active = p_active, updated_at = now() where id = r.id;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (auth.uid(), 'governance.role.update', 'admin_roles', r.id,
          jsonb_build_object('role', r.code, 'name', n, 'description', d, 'active', p_active,
                             'previous_name', r.name, 'previous_active', r.is_active)::text);
  return true;
end $$;

create or replace function kaoid_private.role_permission_r47(p_role text, p_permission text, p_enabled boolean)
returns boolean language plpgsql security definer set search_path = '' as $$
declare r public.admin_roles%rowtype; m public.permissions%rowtype;
begin
  perform kaoid_private.require_fresh_mfa_r14a();
  if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode = '42501'; end if;
  if p_enabled is null then raise exception 'invalid_decision'; end if;
  select * into r from public.admin_roles where code = lower(btrim(coalesce(p_role, ''))) for update;
  if not found then raise exception 'role_unavailable'; end if;
  if r.is_system and not r.is_active then raise exception 'role_protected'; end if;
  select * into m from public.permissions where code = btrim(coalesce(p_permission, '')) and is_active and not is_deprecated;
  if not found then raise exception 'permission_unavailable'; end if;
  if kaoid_private.owner_only_permission_r47(m.code) then raise exception 'permission_owner_only'; end if;
  if p_enabled then
    if exists (select 1 from public.role_permissions where role_id = r.id and permission_id = m.id) then return true; end if;
    -- A dangerous permission added to a role somebody already holds would skip the two-person grant.
    if m.is_dangerous and kaoid_private.role_dangerous_in_use_r47(r.id) then raise exception 'role_in_use_dangerous'; end if;
    insert into public.role_permissions(role_id, permission_id) values (r.id, m.id);
  else
    delete from public.role_permissions where role_id = r.id and permission_id = m.id;
    if not found then return true; end if;
  end if;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (auth.uid(), 'governance.role.permission', 'admin_roles', r.id,
          jsonb_build_object('role', r.code, 'permission', m.code, 'enabled', p_enabled,
                             'dangerous', m.is_dangerous)::text);
  return true;
end $$;

-- 9. Owner snapshot ---------------------------------------------------------------------------------------------------
create or replace function kaoid_private.staff_snapshot_r9b()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode = '42501'; end if;
  perform kaoid_private.staff_grants_settle_r47();
  select jsonb_build_object(
    'roles', (select coalesce(jsonb_agg(x order by x.legacy, x.is_system desc, x.code), '[]'::jsonb) from (
      select r.id, r.code, r.name, r.description, r.is_system, r.is_active, (r.is_system and not r.is_active) as legacy,
             (select count(*) from public.admin_assignments a where a.role_id = r.id and a.is_active
                and (a.expires_at is null or a.expires_at > now())) as holders,
             (select coalesce(jsonb_agg(p.code order by p.code), '[]'::jsonb) from public.role_permissions rp
                join public.permissions p on p.id = rp.permission_id and p.is_active
               where rp.role_id = r.id and not kaoid_private.owner_only_permission_r47(p.code)) as permissions
        from public.admin_roles r) x),
    'catalogue', (select coalesce(jsonb_agg(x order by x.sort_order, x.code), '[]'::jsonb) from (
      select p.code, p.category, p.name, p.description, p.is_dangerous as dangerous,
             kaoid_private.owner_only_permission_r47(p.code) as owner_only, p.sort_order
        from public.permissions p where p.is_active and not p.is_deprecated) x),
    'assignments', (select coalesce(jsonb_agg(x), '[]'::jsonb) from (
      select a.id, a.profile_id, p.display_name, ac.account_code, r.code, r.name as role_name, a.is_active,
             a.starts_at, a.expires_at,
             (a.is_active and r.is_active and p.account_status = 'active' and p.deleted_at is null
               and kaoid_private.role_holder_ready_r47(p.id, r.code) and a.starts_at <= now()
               and (a.expires_at is null or a.expires_at > now())) as currently_assigned,
             (a.is_active and a.starts_at > now()) as scheduled,
             (r.code = 'kaoid_admin' and not exists (select 1 from auth.mfa_factors f
                where f.user_id = p.id and f.status::text = 'verified')) as needs_mfa
        from public.admin_assignments a join public.admin_roles r on r.id = a.role_id
        join public.profiles p on p.id = a.profile_id
        left join kaoid_private.account_refs_r10c ac on ac.profile_id = p.id
       order by a.updated_at desc, a.id limit 100) x),
    'grants', (select coalesce(jsonb_agg(x), '[]'::jsonb) from (
      select g.id, g.target_profile_id, tp.display_name as target_name, tc.account_code as target_code, r.code,
             r.name as role_name, g.mode, g.status, g.expires_at, g.activate_at, g.created_at, g.decided_at,
             g.decision_reason, g.requested_by, q.expires_at as decide_before,
             (g.status = 'pending' and g.mode = 'two_person' and g.requested_by <> auth.uid()) as can_decide
        from kaoid_private.staff_grants_r47 g
        join public.admin_roles r on r.id = g.role_id
        join public.profiles tp on tp.id = g.target_profile_id
        left join kaoid_private.account_refs_r10c tc on tc.profile_id = g.target_profile_id
        left join public.approval_requests q on q.id = g.approval_request_id
       order by (g.status = 'pending') desc, g.created_at desc limit 50) x),
    'approver_ready', kaoid_private.grant_approver_ready_r47(auth.uid(), null),
    'history', (select coalesce(jsonb_agg(x), '[]'::jsonb) from (
      select al.id, al.profile_id, al.action, al.target_table, al.target_id, al.description, al.created_at,
             al.actor_name_at_event, al.actor_roles_at_event, ac.account_code as actor_code,
             tc.account_code as target_code, p.display_name as target_name
        from public.activity_logs al
        left join kaoid_private.account_refs_r10c ac on ac.profile_id = al.profile_id
        left join public.admin_assignments aa on aa.id = al.target_id
        left join kaoid_private.staff_grants_r47 sg on sg.id = al.target_id
        left join kaoid_private.account_refs_r10c tc on tc.profile_id = coalesce(aa.profile_id, sg.target_profile_id)
        left join public.profiles p on p.id = coalesce(aa.profile_id, sg.target_profile_id)
       where al.action like 'governance.role.%' or al.action like 'governance.grant.%'
       order by al.created_at desc, al.id limit 100) x)) into result;
  return result;
end $$;

-- 10. Admin Hub tools: second approvers see the grant queue ----------------------------------------------------------
create or replace function kaoid_private.staff_tools_r24()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_withdrawals boolean := kaoid_private.staff_permission_r24('wallet.withdraw.approve');
  v_contents boolean := kaoid_private.staff_permission_r24('content.system.manage');
  v_reviews boolean := kaoid_private.staff_permission_r24('marketplace.reviews.moderate');
  v_issues boolean := kaoid_private.staff_permission_r24('marketplace.orders.resolve');
  v_topups boolean := kaoid_private.staff_permission_r24('wallet.deposit.approve');
  v_topup_settings boolean := kaoid_private.staff_permission_r24('wallet.deposit.settings');
  v_grants boolean := kaoid_private.staff_permission_r24('admin.assignments.approve');
begin
  return jsonb_build_object(
    'withdrawals', v_withdrawals,
    'contents', v_contents,
    'reviews', v_reviews,
    'order_issues', v_issues,
    'topups', v_topups,
    'topup_settings', v_topup_settings,
    'grant_approvals', v_grants,
    'pending_withdrawals', case when v_withdrawals then
      (select count(*) from public.withdraw_requests r where r.withdraw_status = 'pending') end,
    'pending_review_reports', case when v_reviews then
      (select count(distinct rr.review_id) from secondhand.review_reports rr where rr.report_status = 'pending') end,
    'open_order_issues', case when v_issues then
      (select count(*) from secondhand.order_issues i where i.issue_status = 'open') end,
    'pending_topups', case when v_topups then
      (select count(*) from public.topup_requests t where t.status in ('pending_review', 'awaiting_second')) end,
    'pending_grants', case when v_grants then
      (select count(*) from kaoid_private.staff_grants_r47 g
         join public.approval_requests q on q.id = g.approval_request_id
        where g.status = 'pending' and g.mode = 'two_person' and q.expires_at > now()
          and g.requested_by <> auth.uid() and g.target_profile_id <> auth.uid()) end);
end $$;

-- 11. Public entry points ----------------------------------------------------------------------------------------------
create or replace function public.staff_role_create_r47(p_expected_user uuid, p_code text, p_name text, p_description text default null)
returns uuid language plpgsql set search_path = '' as $$ begin
  if auth.uid() is null or auth.uid() is distinct from p_expected_user then raise exception 'session_changed' using errcode = '42501'; end if;
  return kaoid_private.role_create_r47(p_code, p_name, p_description);
end $$;

create or replace function public.staff_role_update_r47(p_expected_user uuid, p_role text, p_name text, p_description text, p_active boolean)
returns boolean language plpgsql set search_path = '' as $$ begin
  if auth.uid() is null or auth.uid() is distinct from p_expected_user then raise exception 'session_changed' using errcode = '42501'; end if;
  return kaoid_private.role_update_r47(p_role, p_name, p_description, p_active);
end $$;

create or replace function public.staff_role_permission_r47(p_expected_user uuid, p_role text, p_permission text, p_enabled boolean)
returns boolean language plpgsql set search_path = '' as $$ begin
  if auth.uid() is null or auth.uid() is distinct from p_expected_user then raise exception 'session_changed' using errcode = '42501'; end if;
  return kaoid_private.role_permission_r47(p_role, p_permission, p_enabled);
end $$;

create or replace function public.staff_grant_cancel_r47(p_expected_user uuid, p_grant uuid)
returns boolean language plpgsql set search_path = '' as $$ begin
  if auth.uid() is null or auth.uid() is distinct from p_expected_user then raise exception 'session_changed' using errcode = '42501'; end if;
  return kaoid_private.grant_cancel_r47(p_grant);
end $$;

create or replace function public.staff_grant_decide_r47(p_expected_user uuid, p_grant uuid, p_approve boolean, p_reason text default null)
returns boolean language plpgsql set search_path = '' as $$ begin
  if auth.uid() is null or auth.uid() is distinct from p_expected_user then raise exception 'session_changed' using errcode = '42501'; end if;
  return kaoid_private.grant_decide_r47(p_grant, p_approve, p_reason);
end $$;

create or replace function public.staff_grant_queue_r47()
returns jsonb language sql set search_path = '' as $$ select kaoid_private.grant_queue_r47(); $$;

revoke all on function kaoid_private.owner_only_permission_r47(text) from public, anon, authenticated;
revoke all on function kaoid_private.role_holder_ready_r47(uuid, text) from public, anon, authenticated;
revoke all on function kaoid_private.profile_permission_r47(uuid, text) from public, anon, authenticated;
revoke all on function kaoid_private.grant_approver_ready_r47(uuid, uuid) from public, anon, authenticated;
revoke all on function kaoid_private.role_dangerous_in_use_r47(uuid) from public, anon, authenticated;
revoke all on function kaoid_private.staff_grants_settle_r47() from public, anon, authenticated;
revoke all on function kaoid_private.grant_cancel_r47(uuid) from public, anon;
revoke all on function kaoid_private.grant_decide_r47(uuid, boolean, text) from public, anon;
revoke all on function kaoid_private.grant_queue_r47() from public, anon;
revoke all on function kaoid_private.role_create_r47(text, text, text) from public, anon;
revoke all on function kaoid_private.role_update_r47(text, text, text, boolean) from public, anon;
revoke all on function kaoid_private.role_permission_r47(text, text, boolean) from public, anon;
grant execute on function kaoid_private.grant_cancel_r47(uuid) to authenticated;
grant execute on function kaoid_private.grant_decide_r47(uuid, boolean, text) to authenticated;
grant execute on function kaoid_private.grant_queue_r47() to authenticated;
grant execute on function kaoid_private.role_create_r47(text, text, text) to authenticated;
grant execute on function kaoid_private.role_update_r47(text, text, text, boolean) to authenticated;
grant execute on function kaoid_private.role_permission_r47(text, text, boolean) to authenticated;

revoke all on function public.staff_role_create_r47(uuid, text, text, text) from public, anon;
revoke all on function public.staff_role_update_r47(uuid, text, text, text, boolean) from public, anon;
revoke all on function public.staff_role_permission_r47(uuid, text, text, boolean) from public, anon;
revoke all on function public.staff_grant_cancel_r47(uuid, uuid) from public, anon;
revoke all on function public.staff_grant_decide_r47(uuid, uuid, boolean, text) from public, anon;
revoke all on function public.staff_grant_queue_r47() from public, anon;
grant execute on function public.staff_role_create_r47(uuid, text, text, text) to authenticated;
grant execute on function public.staff_role_update_r47(uuid, text, text, text, boolean) to authenticated;
grant execute on function public.staff_role_permission_r47(uuid, text, text, boolean) to authenticated;
grant execute on function public.staff_grant_cancel_r47(uuid, uuid) to authenticated;
grant execute on function public.staff_grant_decide_r47(uuid, uuid, boolean, text) to authenticated;
grant execute on function public.staff_grant_queue_r47() to authenticated;
