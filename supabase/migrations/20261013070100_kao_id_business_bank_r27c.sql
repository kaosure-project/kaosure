-- R27c (2/3): company bank accounts.
-- After the business Kao ID is issued, the owner, a director or an authorized person submits the company's bank
-- account with a passbook photo. The account name must match the company's registered Thai or English legal name
-- (company-form words such as บริษัท / จำกัด / Co., Ltd. are ignored); a mismatch is refused at submission and
-- checked again at review. Kao ID staff review it in the existing bank queue; staff who belong to the company
-- cannot review it. Company members are notified of the result.

-- Who submitted a company account (financial_verifications.profile_id stays null for business rows).
alter table public.financial_verifications
  add column submitted_by uuid references public.profiles(id) on delete restrict;
alter table public.financial_verifications
  add constraint financial_verifications_business_submitter_r27c
  check (identity_type <> 'business' or submitted_by is not null) not valid;

-- ---------------------------------------------------------------------------
-- Legal-name matching
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.org_name_key_r27c(p_name text)
returns text
language sql
immutable
set search_path to ''
as $$
  select nullif(regexp_replace(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            btrim(regexp_replace(lower(coalesce(p_name, '')), '[[:punct:]]+', ' ', 'g')),
            '^the\s+', ''),
          '^((บริษัทมหาชนจำกัด|บริษัท|บจก|บมจ|ห้างหุ้นส่วนจำกัด|ห้างหุ้นส่วนสามัญนิติบุคคล|ห้างหุ้นส่วนสามัญ|ห้างหุ้นส่วน|หจก|หสน)\s*)+', ''),
        '(\s*(จำกัด|มหาชน))+$', ''),
      '(\s+(public|company|limited|co|ltd|plc|pcl|inc|corp|corporation|partnership))+$', ''),
    '\s+', '', 'g'), '');
$$;

create or replace function kaoid_private.org_bank_name_ok_r27c(p_org uuid, p_account_name text)
returns boolean
language sql
stable security definer
set search_path to ''
as $$
  select coalesce((
    select kaoid_private.org_name_key_r27c(p_account_name) in (kaoid_private.org_name_key_r27c(lp.legal_name),
                                                               kaoid_private.org_name_key_r27c(lp.legal_name_en))
      from public.organization_legal_profiles lp
     where lp.organization_id = p_org and lp.registration_status = 'active' and lp.verification_status = 'approved'),
    false) and kaoid_private.org_name_key_r27c(p_account_name) is not null;
$$;

-- The caller acting for an organization: active account, active personal Kao ID, one of the given roles.
create or replace function kaoid_private.org_actor_r27c(p_org uuid, p_roles text[])
returns uuid
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  u uuid := auth.uid();
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_restricted' using errcode = '42501';
  end if;
  if not exists (select 1 from public.kao_id_identities k
                  where k.profile_id = u and k.identity_type = 'personal' and k.organization_id is null
                    and k.status = 'active') then
    raise exception 'KAO_ID_REQUIRED' using errcode = '42501';
  end if;
  if not exists (select 1 from public.organization_members m
                   join public.organizations o on o.id = m.organization_id and o.status = 'active'
                  where m.organization_id = p_org and m.profile_id = u and m.status = 'active'
                    and (m.ends_at is null or m.ends_at > now()) and m.role = any(p_roles)) then
    raise exception 'org_role_required' using errcode = '42501';
  end if;
  return u;
end $$;

-- ---------------------------------------------------------------------------
-- Submission
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.submit_org_bank_r27c(
  p_organization_id uuid, p_id uuid, p_bank text, p_name text, p_number text, p_branch text, p_type text,
  p_evidence text)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  u uuid := kaoid_private.org_actor_r27c(p_organization_id, array['owner', 'director', 'authorized_person']);
  b public.bank_accounts%rowtype;
  o storage.objects%rowtype;
begin
  if p_id is null or p_bank is null or length(btrim(p_bank)) not between 2 and 100
     or p_name is null or length(btrim(p_name)) not between 1 and 200
     or p_number is null or p_number !~ '^[0-9]{6,20}$'
     or p_branch is null or length(btrim(p_branch)) > 100
     or (p_bank || p_name || p_branch) ~ '[[:cntrl:]]'
     or p_type is null or p_type not in ('savings', 'current') then
    raise exception 'invalid_bank' using errcode = '22023';
  end if;
  if p_evidence is null or p_evidence <> u::text || '/business-bank/' || p_id::text || '/evidence.jpg' then
    raise exception 'invalid_document_paths' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('org-bank:' || p_organization_id, 273));
  if not exists (select 1 from public.kao_id_identities k
                  where k.organization_id = p_organization_id and k.identity_type = 'business'
                    and k.profile_id is null and k.status = 'active') then
    raise exception 'business_kao_id_required' using errcode = '42501';
  end if;

  select * into b from public.bank_accounts where id = p_id;
  if found then
    if b.organization_id = p_organization_id and b.profile_id is null and b.bank_name = btrim(p_bank)
       and b.account_name = btrim(p_name) and b.account_number = p_number and b.branch_name = btrim(p_branch)
       and b.account_type = p_type and b.evidence_path = p_evidence and b.deleted_at is null
       and exists (select 1 from public.financial_verifications f where f.bank_account_id = b.id
                      and f.submitted_by = u) then
      return jsonb_build_object('id', b.id, 'status', b.status, 'name_match', true);
    end if;
    raise exception 'bank_conflict' using errcode = '42501';
  end if;
  if not kaoid_private.org_bank_name_ok_r27c(p_organization_id, p_name) then
    raise exception 'bank_name_mismatch' using errcode = '22023';
  end if;
  if exists (select 1 from public.bank_accounts where organization_id = p_organization_id and deleted_at is null
                and is_active and status in ('pending', 'manual_review')) then
    raise exception 'bank_review_active' using errcode = '55000';
  end if;
  if exists (select 1 from public.bank_accounts where organization_id = p_organization_id and deleted_at is null
                and is_active and status not in ('rejected', 'expired')
                and lower(btrim(bank_name)) = lower(btrim(p_bank)) and account_number = p_number) then
    raise exception 'bank_duplicate' using errcode = '23505';
  end if;
  if not exists (select 1 from storage.buckets where id = 'identity-documents' and not public) then
    raise exception 'private_storage_required';
  end if;
  select * into o from storage.objects where bucket_id = 'identity-documents' and name = p_evidence for update;
  if not found or o.owner_id is distinct from u::text
     or coalesce((o.metadata->>'size')::bigint, 0) not between 1 and 10485760
     or coalesce(o.metadata->>'mimetype', '') <> 'image/jpeg' then
    raise exception 'invalid_uploaded_file' using errcode = '22023';
  end if;

  insert into public.bank_accounts(id, profile_id, organization_id, bank_code, bank_name, account_name, account_number,
                                   branch_name, account_type, currency_code, evidence_path, is_default, is_verified,
                                   is_active, status)
  values (p_id, null, p_organization_id, 'manual', btrim(p_bank), btrim(p_name), p_number, btrim(p_branch), p_type,
          'THB', p_evidence, false, false, true, 'pending');
  insert into public.financial_verifications(bank_account_id, identity_type, profile_id, organization_id,
                                             submitted_by, name_match_status, status)
  values (p_id, 'business', null, p_organization_id, u, 'matched', 'pending');
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (u, 'kyc.business_bank.submit', 'bank_accounts', p_id, null);
  return jsonb_build_object('id', p_id, 'status', 'pending', 'name_match', true);
end $$;

-- ---------------------------------------------------------------------------
-- Review: the existing bank queue now carries company accounts
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.org_bank_conflict_r27c(p_request uuid, p_reviewer uuid)
returns boolean
language sql
stable security definer
set search_path to ''
as $$
  select exists (select 1 from public.financial_verifications f
                  where f.id = p_request and f.organization_id is not null
                    and (f.submitted_by = p_reviewer
                         or exists (select 1 from public.organization_members m
                                     where m.organization_id = f.organization_id and m.profile_id = p_reviewer)));
$$;

create or replace function kaoid_private.review_org_bank_r27c(p_request uuid, p_approve boolean, p_reason text)
returns boolean
language plpgsql
security definer
set search_path to ''
as $$
declare
  f public.financial_verifications%rowtype;
  b public.bank_accounts%rowtype;
  result text := case when p_approve then 'approved' else 'rejected' end;
  recipient uuid;
begin
  if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode = '42501'; end if;
  if p_approve is null or length(coalesce(p_reason, '')) > 1000
     or (not p_approve and length(btrim(coalesce(p_reason, ''))) < 3) then
    raise exception 'invalid_decision';
  end if;
  select * into f from public.financial_verifications where id = p_request for update;
  if not found or f.organization_id is null or kaoid_private.org_bank_conflict_r27c(f.id, auth.uid()) then
    raise exception 'request_not_available' using errcode = '42501';
  end if;
  if f.status = result and f.verified_by = auth.uid() then return true; end if;
  if f.status <> 'pending' then raise exception 'request_already_reviewed'; end if;
  select * into b from public.bank_accounts where id = f.bank_account_id for update;
  if not found or b.organization_id is distinct from f.organization_id or b.profile_id is not null
     or b.deleted_at is not null or not b.is_active then
    raise exception 'invalid_document';
  end if;
  if p_approve then
    if not exists (select 1 from public.organizations o where o.id = b.organization_id and o.status = 'active')
       or not exists (select 1 from public.kao_id_identities k
                       where k.organization_id = b.organization_id and k.identity_type = 'business'
                         and k.status = 'active') then
      raise exception 'business_kao_id_required' using errcode = '42501';
    end if;
    if not kaoid_private.org_bank_name_ok_r27c(b.organization_id, b.account_name) then
      raise exception 'bank_name_mismatch' using errcode = '22023';
    end if;
    if b.evidence_path is distinct from f.submitted_by::text || '/business-bank/' || b.id::text || '/evidence.jpg'
       or not exists (select 1 from storage.objects where bucket_id = 'identity-documents' and name = b.evidence_path
                         and owner_id = f.submitted_by::text) then
      raise exception 'document_files_missing';
    end if;
    perform pg_advisory_xact_lock(hashtextextended(lower(btrim(b.bank_name)) || ':' || b.account_number, 920));
    if exists (select 1 from public.bank_accounts x
                where x.id <> b.id and x.organization_id is distinct from b.organization_id
                  and x.deleted_at is null and x.is_verified
                  and lower(btrim(x.bank_name)) = lower(btrim(b.bank_name)) and x.account_number = b.account_number) then
      raise exception 'bank_already_registered';
    end if;
  end if;

  update public.bank_accounts
     set status = case when p_approve then 'verified' else 'rejected' end, is_verified = p_approve,
         verified_by = auth.uid(), verified_at = case when p_approve then now() else null end, updated_at = now()
   where id = b.id;
  update public.financial_verifications
     set status = result, verified_by = auth.uid(), verified_at = case when p_approve then now() else null end,
         notes = btrim(p_reason), updated_at = now()
   where id = f.id;
  update public.organization_verifications
     set bank_verified = exists (select 1 from public.bank_accounts x
                                  join public.financial_verifications v on v.bank_account_id = x.id
                                 where x.organization_id = b.organization_id and x.is_verified and x.is_active
                                   and x.deleted_at is null and x.status = 'verified' and v.status = 'approved'),
         updated_at = now()
   where organization_id = b.organization_id;
  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (auth.uid(), 'kyc.business_bank.' || case when p_approve then 'approve' else 'reject' end, 'bank_accounts',
          b.id, btrim(p_reason));

  for recipient in
    select f.submitted_by
    union
    select m.profile_id from public.organization_members m
     where m.organization_id = b.organization_id and m.status = 'active'
       and m.role in ('owner', 'director', 'authorized_person', 'finance')
  loop
    perform kaoid_private.emit_notice_r10a(recipient, 'business-bank:' || b.id || ':' || result || ':' || recipient,
                                           'business_bank_' || result, b.id);
  end loop;
  return true;
end $$;

create or replace function kaoid_private.review_bank_r9c(p_request uuid, p_approve boolean, p_reason text)
returns boolean
language plpgsql
security definer
set search_path to ''
as $$
declare f public.financial_verifications%rowtype; b public.bank_accounts%rowtype; result text;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
 if exists(select 1 from public.financial_verifications where id=p_request and organization_id is not null) then
  return kaoid_private.review_org_bank_r27c(p_request,p_approve,p_reason); end if;
 if p_approve is null or length(coalesce(p_reason,''))>1000 or (not p_approve and length(btrim(coalesce(p_reason,'')))<3) then raise exception 'invalid_decision'; end if;
 select * into f from public.financial_verifications where id=p_request for update;
 if not found or f.profile_id=auth.uid() or f.organization_id is not null then raise exception 'request_not_available' using errcode='42501'; end if;
 result:=case when p_approve then 'approved' else 'rejected' end;
 if f.status=result and f.verified_by=auth.uid() then return true; end if;
 if f.status<>'pending' then raise exception 'request_already_reviewed'; end if;
 select * into b from public.bank_accounts where id=f.bank_account_id for update;
 if not found or b.profile_id<>f.profile_id or b.deleted_at is not null or not b.is_active or b.organization_id is not null then raise exception 'invalid_document'; end if;
 perform 1 from public.profiles where id=b.profile_id and account_status='active' and deleted_at is null for update;
 if not found then raise exception 'inactive_account'; end if;
 if p_approve then
  if not kaoid_private.bank_holder_name_ok_r20g(b.profile_id, b.account_name)
  then raise exception 'bank_verified_name_required'; end if;
  if b.evidence_path is distinct from b.profile_id::text||'/bank-account/'||b.id::text||'/evidence.jpg'
   or not exists(select 1 from storage.objects where bucket_id='identity-documents' and name=b.evidence_path and owner_id=b.profile_id::text)
   then raise exception 'document_files_missing'; end if;
  perform pg_advisory_xact_lock(hashtextextended(lower(btrim(b.bank_name))||':'||b.account_number,920));
  if exists(select 1 from public.bank_accounts x where x.profile_id is distinct from b.profile_id and x.deleted_at is null and x.is_verified
   and lower(btrim(x.bank_name))=lower(btrim(b.bank_name)) and x.account_number=b.account_number)
   then raise exception 'bank_already_registered'; end if;
 end if;
 update public.bank_accounts set status=case when p_approve then 'verified' else 'rejected' end,
  is_verified=p_approve,verified_by=auth.uid(),verified_at=case when p_approve then now() else null end,updated_at=now() where id=b.id;
 update public.financial_verifications set status=result,name_match_status=case when p_approve then 'matched' else 'pending' end,
  verified_by=auth.uid(),verified_at=case when p_approve then now() else null end,notes=btrim(p_reason),updated_at=now() where id=f.id;
 update public.verifications set bank_status=case when p_approve then 'verified' else 'rejected' end where profile_id=b.profile_id;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description)
 values(auth.uid(),case when p_approve then 'kyc.bank.approve' else 'kyc.bank.reject' end,'bank_accounts',b.id,btrim(p_reason));
 return true;
end $$;

-- Two-person rule: the applicant of a company account is whoever submitted it; company members never review it.
create or replace function kaoid_private.review_vote_r14a(p_id uuid,p_approve boolean,p_reason text,p_recovery boolean) returns boolean language plpgsql security definer set search_path='' as $$
declare target uuid; ar public.approval_requests%rowtype; meta jsonb; rid uuid; sid uuid; fingerprint text; kind text; first_ok boolean;begin
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
  select exists(select 1 from public.profiles p where p.id=ar.requested_by and p.account_status='active' and p.deleted_at is null
   and exists(select 1 from auth.mfa_factors f where f.user_id=p.id and f.status::text='verified')
   and (exists(select 1 from public.company_owners o where o.profile_id=p.id) or exists(select 1 from public.admin_assignments a join public.admin_roles r on r.id=a.role_id
   where a.profile_id=p.id and a.is_active and r.is_active and r.code='kyc_officer' and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now())))) into first_ok;
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
   insert into public.approval_steps(approval_request_id,role_id,step_order,status,approved_by,approved_at,comment) values(ar.id,(select id from public.admin_roles where code='kyc_officer'),2,'approved',auth.uid(),now(),p_reason) returning id into sid;
   update public.approval_requests set status='approved',completed_at=now(),updated_at=now() where id=ar.id;
   insert into public.approval_histories(approval_request_id,approval_step_id,actor_profile_id,event,previous_status,current_status,comment)
   values(ar.id,sid,auth.uid(),'completed','pending','approved',p_reason);
   return true;
  end if;
 end if;
 insert into public.approval_requests(policy_id,requested_by,resource,resource_id,status,reason,expires_at)
 select id,auth.uid(),kind,p_id,'pending',p_reason,now()+interval '24 hours' from public.approval_policies where code='kaoid_two_person_r14a' returning id into rid;
 insert into public.approval_steps(approval_request_id,role_id,step_order,status,approved_by,approved_at,comment) values(rid,(select id from public.admin_roles where code='kyc_officer'),1,'approved',auth.uid(),now(),p_reason) returning id into sid;
 insert into public.approval_histories(approval_request_id,approval_step_id,actor_profile_id,event,current_status,metadata)
 values(rid,sid,auth.uid(),'request_created','pending',jsonb_build_object('approve',p_approve,'fingerprint',fingerprint,'policy_version','r14a'));
 return false;
end $$;

create or replace function kaoid_private.staff_notice_r14b() returns trigger language plpgsql security definer set search_path='' as $$
declare recipient uuid; applicant uuid; target uuid; excluded uuid; code text; event text; ar public.approval_requests%rowtype;
begin
 if tg_table_name='verification_requests' then
  if new.status not in ('pending','under_review') then return new;end if;
  applicant:=new.requested_by;target:=new.id;code:='review_new';event:='request:'||new.id;
 elsif tg_table_name='financial_verifications' then
  if new.status<>'pending' then return new;end if;
  applicant:=coalesce(new.profile_id,new.submitted_by);target:=new.id;code:='review_new';event:='bank:'||new.id;
 elsif tg_table_name='approval_histories' then
  if new.event not in ('request_created','rejected') then return new;end if;
  select * into ar from public.approval_requests where id=new.approval_request_id and resource in ('kaoid_review','kaoid_recovery');
  if not found then return new;end if;
  target:=ar.resource_id;
  select requested_by into applicant from public.verification_requests where id=target;
  if applicant is null then select coalesce(profile_id,submitted_by) into applicant from public.financial_verifications where id=target;end if;
  if applicant is null then return new;end if;
  excluded:=case when new.event='request_created' then ar.requested_by else null end;
  code:=case when new.event='request_created' then 'review_second' else 'review_restart' end;
  event:='vote:'||new.id;
 elsif tg_table_name='activity_logs' then
  if new.action not in ('governance.role.assign','governance.role.revoke') then return new;end if;
  select profile_id into recipient from public.admin_assignments where id=new.target_id;
  if recipient is not null then
   code:=case when new.action='governance.role.assign' then 'role_assigned' else 'role_revoked' end;
   perform kaoid_private.emit_notice_r10a(recipient,'staff:'||new.id||':'||recipient,code,new.target_id);
  end if;
  return new;
 else return new;end if;
 for recipient in select * from kaoid_private.review_recipients_r14b(applicant,excluded) r(id)
   where not kaoid_private.org_bank_conflict_r27c(target,r.id) loop
  perform kaoid_private.emit_notice_r10a(recipient,'staff:'||event||':'||recipient,code,target);
 end loop;
 return new;
end $$;

-- Queue rows: company accounts appear as document_type 'business_bank' with the legal names to compare against.
create or replace function kaoid_private.review_queue_base_r10e()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare result jsonb;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
 select coalesce(jsonb_agg(to_jsonb(q)),'[]') into result from (
 select r.id,r.status,r.submitted_at,d.document_type,d.full_name,d.document_number,d.issued_date,d.expiry_date,
 d.issuing_country,d.residence_format,
 (select coalesce(jsonb_agg(f.file_path order by f.file_path),'[]') from public.document_files f where f.document_id=d.id) as paths,
 null::text bank_name,null::text identity_name,
 null::text organization_name,null::text legal_name_en,null::text business_kao_id,null::boolean name_match
 from public.verification_requests r join public.identity_documents d on d.id=r.document_id
 where r.status in ('pending','under_review') and r.requested_by<>auth.uid() and d.owner_id=r.requested_by
 and d.document_type in ('thai_national_id','passport','residence_card') and d.deleted_at is null
 union all
 select f.id,f.status,f.created_at,'bank',b.account_name,b.account_number,null::date,null::date,
 null::text,null::text,jsonb_build_array(b.evidence_path),b.bank_name,
 (select d.full_name from public.identity_documents d join public.verification_requests r on r.document_id=d.id
 where d.owner_id=b.profile_id and kaoid_private.primary_identity_r27a(d.document_type,d.issuing_country,d.thai_document_kind)
 and d.status='approved'
 and d.deleted_at is null and (d.expiry_date is null or d.expiry_date>=current_date) and r.status='approved'
 and r.reviewed_by<>b.profile_id order by d.verified_at desc limit 1),
 null::text,null::text,null::text,null::boolean
 from public.financial_verifications f join public.bank_accounts b on b.id=f.bank_account_id
 where f.status='pending' and b.profile_id=f.profile_id and b.profile_id<>auth.uid()
 and b.organization_id is null and b.deleted_at is null and b.is_active and b.evidence_path is not null
 union all
 select f.id,f.status,f.created_at,'business_bank',b.account_name,b.account_number,null::date,null::date,
 null::text,null::text,jsonb_build_array(b.evidence_path),b.bank_name,lp.legal_name,
 o.name,lp.legal_name_en,k.kao_id,kaoid_private.org_bank_name_ok_r27c(b.organization_id,b.account_name)
 from public.financial_verifications f join public.bank_accounts b on b.id=f.bank_account_id
 join public.organizations o on o.id=b.organization_id
 join public.organization_legal_profiles lp on lp.organization_id=b.organization_id
 left join public.kao_id_identities k on k.organization_id=b.organization_id and k.identity_type='business'
 where f.status='pending' and f.organization_id=b.organization_id and b.profile_id is null
 and not kaoid_private.org_bank_conflict_r27c(f.id,auth.uid())
 and b.deleted_at is null and b.is_active and b.evidence_path is not null
 order by submitted_at,id limit 50)q;
 return result;
end $$;

create or replace function kaoid_private.review_target_base_r14b(p_target uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare result jsonb;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
 select coalesce(jsonb_agg(to_jsonb(q)),'[]') into result from (
 select r.id,r.status,r.submitted_at,d.document_type,d.full_name,d.document_number,d.issued_date,d.expiry_date,
 d.issuing_country,d.residence_format,
 (select coalesce(jsonb_agg(f.file_path order by f.file_path),'[]') from public.document_files f where f.document_id=d.id) as paths,
 null::text bank_name,null::text identity_name,
 null::text organization_name,null::text legal_name_en,null::text business_kao_id,null::boolean name_match
 from public.verification_requests r join public.identity_documents d on d.id=r.document_id
 where r.id=p_target and r.status in ('pending','under_review') and r.requested_by<>auth.uid() and d.owner_id=r.requested_by
 and d.document_type in ('thai_national_id','passport','residence_card') and d.deleted_at is null
 union all
 select f.id,f.status,f.created_at,'bank',b.account_name,b.account_number,null::date,null::date,
 null::text,null::text,jsonb_build_array(b.evidence_path),b.bank_name,
 (select d.full_name from public.identity_documents d join public.verification_requests r on r.document_id=d.id
 where d.owner_id=b.profile_id and kaoid_private.primary_identity_r27a(d.document_type,d.issuing_country,d.thai_document_kind)
 and d.status='approved'
 and d.deleted_at is null and (d.expiry_date is null or d.expiry_date>=current_date) and r.status='approved'
 and r.reviewed_by<>b.profile_id order by d.verified_at desc limit 1),
 null::text,null::text,null::text,null::boolean
 from public.financial_verifications f join public.bank_accounts b on b.id=f.bank_account_id
 where f.id=p_target and f.status='pending' and b.profile_id=f.profile_id and b.profile_id<>auth.uid()
 and b.organization_id is null and b.deleted_at is null and b.is_active and b.evidence_path is not null
 union all
 select f.id,f.status,f.created_at,'business_bank',b.account_name,b.account_number,null::date,null::date,
 null::text,null::text,jsonb_build_array(b.evidence_path),b.bank_name,lp.legal_name,
 o.name,lp.legal_name_en,k.kao_id,kaoid_private.org_bank_name_ok_r27c(b.organization_id,b.account_name)
 from public.financial_verifications f join public.bank_accounts b on b.id=f.bank_account_id
 join public.organizations o on o.id=b.organization_id
 join public.organization_legal_profiles lp on lp.organization_id=b.organization_id
 left join public.kao_id_identities k on k.organization_id=b.organization_id and k.identity_type='business'
 where f.id=p_target and f.status='pending' and f.organization_id=b.organization_id and b.profile_id is null
 and not kaoid_private.org_bank_conflict_r27c(f.id,auth.uid())
 and b.deleted_at is null and b.is_active and b.evidence_path is not null)q;
 return result;
end $$;

create or replace function kaoid_private.can_read_evidence_base_r10e(p_path text)
returns boolean
language sql
stable security definer
set search_path to ''
as $$
 select kaoid_private.can_review_r7c() and (
 exists(select 1 from public.document_files f join public.identity_documents d on d.id=f.document_id
 join public.verification_requests r on r.document_id=d.id
 where f.file_path=p_path and d.document_type in ('thai_national_id','passport','residence_card') and d.deleted_at is null
 and d.owner_id=r.requested_by and d.owner_id<>auth.uid() and r.status in ('pending','under_review'))
 or exists(select 1 from public.bank_accounts b join public.financial_verifications f on f.bank_account_id=b.id
 where b.evidence_path=p_path and b.profile_id<>auth.uid() and b.profile_id=f.profile_id
 and b.organization_id is null and b.deleted_at is null and b.is_active and f.status='pending')
 or exists(select 1 from public.bank_accounts b join public.financial_verifications f on f.bank_account_id=b.id
 where b.evidence_path=p_path and b.organization_id is not null and f.organization_id=b.organization_id
 and not kaoid_private.org_bank_conflict_r27c(f.id,auth.uid())
 and b.deleted_at is null and b.is_active and f.status='pending'));
$$;

-- ---------------------------------------------------------------------------
-- Notices and the member's view of their organizations
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.notice_target_r15b(p_notice uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $$
declare
  n public.notifications%rowtype;
  q jsonb;
begin
  if auth.uid() is null or not kaoid_private.account_active_r9f() then
    raise exception 'session_required' using errcode = '42501';
  end if;
  select * into n from public.notifications
   where id = p_notice and profile_id = auth.uid() and not is_deleted and notification_type = 'kaoid';
  if not found then raise exception 'notice_unavailable' using errcode = '42501'; end if;

  if n.message in ('business_review_new', 'business_review_second', 'business_review_restart') then
    q := kaoid_private.business_review_rows_r15b(n.target_id) -> 0;
    if q is null then return jsonb_build_object('kind', 'unavailable'); end if;
    return jsonb_build_object('kind', 'business_review', 'row', q);
  elsif n.message in ('business_approved', 'business_rejected') then
    select jsonb_build_object('kind', 'result', 'status', status, 'reason', review_reason) into q
      from public.business_registrations where id = n.target_id and user_id = auth.uid();
    return coalesce(q, jsonb_build_object('kind', 'unavailable'));
  elsif n.message in ('business_bank_approved', 'business_bank_rejected') then
    select jsonb_build_object('kind', 'result', 'status', f.status, 'reason', f.notes) into q
      from public.financial_verifications f
      join public.bank_accounts b on b.id = f.bank_account_id
     where b.id = n.target_id and f.organization_id = b.organization_id
       and (f.submitted_by = auth.uid()
            or exists (select 1 from public.organization_members m
                        where m.organization_id = b.organization_id and m.profile_id = auth.uid()
                          and m.status = 'active'));
    return coalesce(q, jsonb_build_object('kind', 'unavailable'));
  end if;
  return kaoid_private.notice_target_r14b(p_notice);
end $$;

create or replace function kaoid_private.my_organizations_r27c()
returns jsonb
language plpgsql
stable security definer
set search_path to ''
as $$
declare
  u uuid := auth.uid();
begin
  if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if not kaoid_private.account_active_r9f() then
    raise exception 'account_restricted' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'organization_id', o.id,
             'name', o.name,
             'status', o.status,
             'role', m.role,
             'legal_name', lp.legal_name,
             'legal_name_en', lp.legal_name_en,
             'registration_number', lp.registration_number,
             'verification_status', lp.verification_status,
             'business_kao_id', k.kao_id,
             'kao_id_status', k.status,
             'can_manage_bank', m.role in ('owner', 'director', 'authorized_person'),
             'bank_verified', exists (select 1 from public.bank_accounts x
                                        join public.financial_verifications v on v.bank_account_id = x.id
                                       where x.organization_id = o.id and x.is_verified and x.is_active
                                         and x.deleted_at is null and x.status = 'verified'
                                         and v.status = 'approved'),
             'banks', coalesce((
               select jsonb_agg(jsonb_build_object(
                        'id', b.id, 'bank_name', b.bank_name, 'account_name', b.account_name,
                        'last4', right(b.account_number, 4), 'status', b.status,
                        'reason', case when b.status = 'rejected' then f.notes end,
                        'submitted_at', b.created_at, 'verified_at', b.verified_at) order by b.created_at desc)
                 from (select * from public.bank_accounts x
                        where x.organization_id = o.id and x.deleted_at is null
                        order by x.created_at desc limit 5) b
                 left join public.financial_verifications f on f.bank_account_id = b.id), '[]'::jsonb),
             'shop', (select jsonb_build_object('id', s.id, 'name', s.shop_name, 'status', s.shop_status)
                        from public.shops s
                       where s.organization_id = o.id and s.seller_identity_type = 'business')
           ) order by m.created_at)
      from public.organization_members m
      join public.organizations o on o.id = m.organization_id
      left join public.organization_legal_profiles lp on lp.organization_id = o.id
      left join public.kao_id_identities k on k.organization_id = o.id and k.identity_type = 'business'
     where m.profile_id = u and m.status = 'active' and o.status = 'active'
       and (m.ends_at is null or m.ends_at > now())), '[]'::jsonb);
end $$;

create or replace function public.submit_org_bank_r27c(
  p_organization_id uuid, p_id uuid, p_bank text, p_name text, p_number text, p_branch text, p_type text,
  p_evidence text)
returns jsonb
language sql
set search_path to ''
as $$
  select kaoid_private.submit_org_bank_r27c(p_organization_id, p_id, p_bank, p_name, p_number, p_branch, p_type,
                                            p_evidence);
$$;

create or replace function public.my_organizations_r27c()
returns jsonb
language sql
stable
set search_path to ''
as $$ select kaoid_private.my_organizations_r27c(); $$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
revoke all on function kaoid_private.org_name_key_r27c(text), kaoid_private.org_bank_name_ok_r27c(uuid, text),
  kaoid_private.org_actor_r27c(uuid, text[]), kaoid_private.org_bank_conflict_r27c(uuid, uuid),
  kaoid_private.review_org_bank_r27c(uuid, boolean, text)
  from public, anon, authenticated;

revoke all on function
  kaoid_private.submit_org_bank_r27c(uuid, uuid, text, text, text, text, text, text),
  kaoid_private.my_organizations_r27c(),
  public.submit_org_bank_r27c(uuid, uuid, text, text, text, text, text, text),
  public.my_organizations_r27c()
  from public, anon;
grant execute on function
  kaoid_private.submit_org_bank_r27c(uuid, uuid, text, text, text, text, text, text),
  kaoid_private.my_organizations_r27c(),
  public.submit_org_bank_r27c(uuid, uuid, text, text, text, text, text, text),
  public.my_organizations_r27c()
  to authenticated;
