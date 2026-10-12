-- R27a: Kao ID is issued from an approved permanent identity document (Thai ID card, passport, or a Thai
-- alien certificate / pink card, which carry a 13-digit Thai PID); a bank account is not required for it.
-- An individual seller needs email + phone + Kao ID + bank; the unverified price-capped tier is retired.
-- One personal shop per account and one shop per organization.

create or replace function kaoid_private.primary_identity_r27a(p_type text, p_country text, p_kind text)
returns boolean
language sql
immutable
set search_path to ''
as $$
  select coalesce(p_type in ('thai_national_id', 'passport')
                  or (p_type = 'residence_card' and p_country = 'THA'
                      and p_kind in ('residence_certificate', 'pink_card')), false);
$$;

revoke all on function kaoid_private.primary_identity_r27a(text, text, text) from public, anon, authenticated;

create or replace function kaoid_private.valid_identity_r11a(p_profile uuid)
 returns boolean
 language sql
 stable security definer
 set search_path to ''
as $function$
 select exists(select 1 from public.identity_documents d join public.verification_requests r on r.document_id=d.id
 where d.owner_id=p_profile and kaoid_private.primary_identity_r27a(d.document_type,d.issuing_country,d.thai_document_kind)
 and d.status='approved'
 and d.deleted_at is null and (d.expiry_date is null or d.expiry_date>=current_date)
 and r.requested_by=p_profile and r.status='approved' and r.reviewed_by is not null and r.reviewed_by<>p_profile);
$function$;

create or replace function kaoid_private.grant_kao_id_r27a(p_profile uuid)
returns text
language plpgsql
security definer
set search_path to ''
as $$
declare v_existing text; v_id text; i integer;
begin
 select kao_id into v_existing from public.kao_id_identities where profile_id=p_profile;
 if found then return v_existing; end if;
 for i in 1..5 loop
  v_id:=public.generate_kao_id();
  begin
   insert into public.kao_id_identities(profile_id,kao_id,status,identity_type,issued_at)
   values(p_profile,v_id,'active','personal',now());
   return v_id;
  exception when unique_violation then
   select kao_id into v_existing from public.kao_id_identities where profile_id=p_profile;
   if found then return v_existing; end if;
  end;
 end loop;
 raise exception 'identity_generation_failed';
end $$;

revoke all on function kaoid_private.grant_kao_id_r27a(uuid) from public, anon, authenticated;

create or replace function kaoid_private.issue_kao_id_r7c(p_profile_id uuid)
 returns text
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare v_existing text; v_status text;
begin
 if not kaoid_private.account_active_r9f() then raise exception 'account_restricted' using errcode='42501'; end if;
 if auth.uid() is null or p_profile_id is distinct from auth.uid() or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then
  raise exception 'not_authorized' using errcode='42501'; end if;
 perform 1 from public.profiles where id=p_profile_id and account_status='active' and deleted_at is null for update;
 if not found then raise exception 'inactive_account' using errcode='42501'; end if;
 if not kaoid_private.valid_identity_r11a(p_profile_id) then raise exception 'approved_identity_required' using errcode='42501';end if;
 select kao_id,status into v_existing,v_status from public.kao_id_identities where profile_id=p_profile_id;
 if found then
  if v_status<>'active' then raise exception 'identity_inactive' using errcode='42501'; end if;
  return v_existing;
 end if;
 if not exists(select 1 from public.verifications where profile_id=p_profile_id and status='approved') then
  raise exception 'approved_identity_required' using errcode='42501'; end if;
 return kaoid_private.grant_kao_id_r27a(p_profile_id);
end $function$;

create or replace function kaoid_private.review_decision_base_r10e(p_request uuid, p_approve boolean, p_reason text)
 returns boolean
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare r public.verification_requests%rowtype; d public.identity_documents%rowtype; v_status text; paths text[]; v_primary boolean;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
 if p_approve is null or length(coalesce(p_reason,''))>1000 or (not p_approve and length(btrim(coalesce(p_reason,'')))<3) then
  raise exception 'invalid_decision' using errcode='22023'; end if;
 if exists(select 1 from public.financial_verifications where id=p_request) then
 return kaoid_private.review_bank_r9c(p_request,p_approve,p_reason); end if;
 select * into r from public.verification_requests where id=p_request for update;
 if not found or r.requested_by=auth.uid() then raise exception 'request_not_available' using errcode='42501'; end if;
 v_status:=case when p_approve then 'approved' else 'rejected' end;
 if r.status=v_status and r.reviewed_by=auth.uid() then return true; end if;
 if r.status not in ('pending','under_review') then raise exception 'request_already_reviewed' using errcode='55000'; end if;
 select * into d from public.identity_documents where id=r.document_id for update;
 if not found or d.owner_id<>r.requested_by or d.document_type not in ('thai_national_id','passport','residence_card') or d.deleted_at is not null then
  raise exception 'invalid_document' using errcode='22023'; end if;
 perform 1 from public.profiles where id=r.requested_by and account_status='active' and deleted_at is null for update;
 if not found then raise exception 'inactive_account' using errcode='42501'; end if;
 perform 1 from public.verifications where profile_id=r.requested_by for update;
 if not found then raise exception 'verification_record_missing' using errcode='55000'; end if;
 if p_approve then
  if d.status<>'pending_review' or nullif(btrim(d.full_name),'') is null
  or nullif(btrim(d.document_number),'') is null or d.issued_date>current_date
  or (d.expiry_date is not null and d.expiry_date<current_date) then
   raise exception 'document_not_ready' using errcode='22023'; end if;
  if d.document_type='thai_national_id' then
   if d.document_number !~ '^[0-9]{13}$' then raise exception 'document_not_ready'; end if;
   paths:=array[d.owner_id::text||'/national-id/'||d.id::text||'/front.jpg',d.owner_id::text||'/national-id/'||d.id::text||'/back.jpg'];
  elsif d.document_type='passport' then
   if d.expiry_date is null or d.issued_date is null or d.date_of_birth is null
    or d.date_of_birth>d.issued_date or d.expiry_date<=d.issued_date
    or nullif(btrim(d.issuing_country),'') is null then raise exception 'document_not_ready'; end if;
   paths:=array[d.owner_id::text||'/passport/'||d.id::text||'/data.jpg'];
  else
   if d.issued_date is null or d.residence_format not in ('card','paper')
    or d.residence_format is null or d.no_expiry is null
    or (d.no_expiry and d.expiry_date is not null)
    or (not d.no_expiry and (d.expiry_date is null or d.expiry_date<=d.issued_date))
    then raise exception 'document_not_ready'; end if;
   paths:=array[d.owner_id::text||'/residence/'||d.id::text||'/front.jpg'];
   if d.residence_format='card' then paths:=array_append(paths,d.owner_id::text||'/residence/'||d.id::text||'/back.jpg'); end if;
  end if;
  if (select count(distinct f.file_path) from public.document_files f join storage.objects o
     on o.bucket_id='identity-documents' and o.name=f.file_path
     where f.document_id=d.id and o.owner_id=d.owner_id::text and f.file_path=any(paths))<>cardinality(paths)
    then raise exception 'document_files_missing'; end if;
  perform pg_advisory_xact_lock(hashtextextended(d.document_type||':'||lower(btrim(coalesce(d.issuing_country,'')))||':'||upper(btrim(d.document_number)),715));
  if exists(select 1 from public.identity_documents x where x.document_type=d.document_type
     and upper(btrim(x.document_number))=upper(btrim(d.document_number))
     and (d.document_type='thai_national_id' or lower(btrim(coalesce(x.issuing_country,'')))=lower(btrim(coalesce(d.issuing_country,''))))
     and x.owner_id<>d.owner_id and x.status in ('approved','expired','revoked') and x.deleted_at is null)
     then raise exception 'identity_already_registered' using errcode='23505'; end if;
 end if;
 update public.identity_documents set status=v_status,verified_by=auth.uid(),
  verified_at=case when p_approve then now() else null end,
  rejected_reason=case when p_approve then null else btrim(p_reason) end where id=d.id;
 update public.verification_requests set status=v_status,reviewed_at=now(),reviewed_by=auth.uid(),
  rejection_reason=case when p_approve then null else btrim(p_reason) end,notes=p_reason where id=r.id;
 select exists(select 1 from public.identity_documents x join public.verification_requests q on q.document_id=x.id
  where x.owner_id=r.requested_by and kaoid_private.primary_identity_r27a(x.document_type,x.issuing_country,x.thai_document_kind)
  and x.status='approved' and x.deleted_at is null and (x.expiry_date is null or x.expiry_date>=current_date)
  and q.status='approved' and q.reviewed_by is not null and q.reviewed_by<>x.owner_id) into v_primary;
 update public.verifications set
 identity_card_status=case when d.document_type='thai_national_id' then case when p_approve then 'verified' else 'rejected' end else identity_card_status end,
 passport_status=case when d.document_type='passport' then case when p_approve then 'verified' else 'rejected' end else passport_status end,
 residence_permit_status=case when d.document_type='residence_card' then case when p_approve then 'verified' else 'rejected' end else residence_permit_status end,
 identity_expiry=case when d.document_type='thai_national_id' then d.expiry_date else identity_expiry end,
 passport_expiry=case when d.document_type='passport' then d.expiry_date else passport_expiry end,
 residence_permit_expiry=case when d.document_type='residence_card' then d.expiry_date else residence_permit_expiry end,
 status=case when v_primary then 'approved' when d.document_type='residence_card' then status else v_status end,
 account_level=case when v_primary then 'verified' when d.document_type='residence_card' then account_level else 'registered' end,
 last_reviewed_by=auth.uid(),last_verified_at=case when v_primary then now() else last_verified_at end,
 rejected_reason=case when v_primary then null when d.document_type='residence_card' then rejected_reason else btrim(p_reason) end
 where profile_id=r.requested_by;
 insert into public.verification_logs(verification_request_id,action,old_status,new_status,performed_by,notes)
 values(r.id,case when p_approve then 'approve' else 'reject' end,r.status,v_status,auth.uid(),p_reason);
 perform kaoid_private.sync_identity_r11a(r.requested_by);
 if p_approve and v_primary then perform kaoid_private.grant_kao_id_r27a(r.requested_by); end if;
 return true;
end $function$;

create or replace function kaoid_private.sync_identity_r11a(p_profile uuid)
 returns void
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare valid boolean; affected integer;
begin
 perform 1 from public.profiles where id=p_profile for update;
 valid:=kaoid_private.valid_identity_r11a(p_profile);
 if not valid then
  update public.kao_id_identities set status='suspended',updated_at=now()
   where profile_id=p_profile and identity_type='personal' and status='active';
  get diagnostics affected=row_count;
  if affected>0 then insert into kaoid_private.identity_holds_r11a(profile_id) values(p_profile) on conflict do nothing;end if;
 else
  if exists(select 1 from public.profiles where id=p_profile and account_status='active' and deleted_at is null) then
   update public.kao_id_identities set status='active',updated_at=now() where profile_id=p_profile and identity_type='personal'
    and status='suspended' and exists(select 1 from kaoid_private.identity_holds_r11a where profile_id=p_profile);
   delete from kaoid_private.identity_holds_r11a where profile_id=p_profile;
  end if;
 end if;
 update public.verifications v set status=case when valid then 'approved'
    when exists(select 1 from public.identity_documents where owner_id=p_profile and kaoid_private.primary_identity_r27a(document_type,issuing_country,thai_document_kind) and status='revoked') then 'revoked'
    when exists(select 1 from public.identity_documents where owner_id=p_profile and kaoid_private.primary_identity_r27a(document_type,issuing_country,thai_document_kind) and (status='expired' or (status='approved' and expiry_date<current_date))) then 'expired' else v.status end,
  account_level=case when valid then 'verified' else 'registered' end,
  identity_card_status=coalesce((select case when status='approved' and (expiry_date is null or expiry_date>=current_date) then 'verified' when status='approved' then 'expired' else status end from public.identity_documents where owner_id=p_profile and document_type='thai_national_id' and deleted_at is null order by created_at desc,id desc limit 1),v.identity_card_status),
  passport_status=coalesce((select case when status='approved' and (expiry_date is null or expiry_date>=current_date) then 'verified' when status='approved' then 'expired' else status end from public.identity_documents where owner_id=p_profile and document_type='passport' and deleted_at is null order by created_at desc,id desc limit 1),v.passport_status),
  residence_permit_status=coalesce((select case when status='approved' and (expiry_date is null or expiry_date>=current_date) then 'verified' when status='approved' then 'expired' else status end from public.identity_documents where owner_id=p_profile and document_type='residence_card' and deleted_at is null order by created_at desc,id desc limit 1),v.residence_permit_status),
  updated_at=now() where profile_id=p_profile;
end $function$;

create or replace function kaoid_private.bank_holder_name_ok_r20g(p_profile_id uuid, p_account_name text)
 returns boolean
 language plpgsql
 stable security definer
 set search_path to ''
as $function$
declare
  v_key text := kaoid_private.holder_name_key_r20g(p_account_name);
  v_has_identity boolean;
begin
  if p_profile_id is null or v_key is null then
    return false;
  end if;
  select exists (
    select 1
      from public.identity_documents d
      join public.verification_requests r on r.document_id = d.id
     where d.owner_id = p_profile_id and d.status = 'approved'
       and kaoid_private.primary_identity_r27a(d.document_type, d.issuing_country, d.thai_document_kind)
       and d.deleted_at is null
       and (d.expiry_date is null or d.expiry_date >= current_date)
       and r.status = 'approved' and r.reviewed_by <> p_profile_id)
    into v_has_identity;
  if v_has_identity then
    return exists (
      select 1
        from public.identity_documents d
        join public.verification_requests r on r.document_id = d.id
       where d.owner_id = p_profile_id and d.status = 'approved'
         and kaoid_private.primary_identity_r27a(d.document_type, d.issuing_country, d.thai_document_kind)
         and d.deleted_at is null
         and (d.expiry_date is null or d.expiry_date >= current_date)
         and r.status = 'approved' and r.reviewed_by <> p_profile_id
         and kaoid_private.holder_name_key_r20g(d.full_name) = v_key);
  end if;
  return exists (
    select 1 from public.profiles p
     where p.id = p_profile_id
       and nullif(btrim(p.first_name), '') is not null and nullif(btrim(p.last_name), '') is not null
       and kaoid_private.holder_name_key_r20g(concat_ws(' ', p.first_name, p.last_name)) = v_key);
end $function$;

create or replace function kaoid_private.review_queue_base_r10e()
 returns jsonb
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare result jsonb;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
 select coalesce(jsonb_agg(to_jsonb(q)),'[]') into result from (
 select r.id,r.status,r.submitted_at,d.document_type,d.full_name,d.document_number,d.issued_date,d.expiry_date,
 d.issuing_country,d.residence_format,
 (select coalesce(jsonb_agg(f.file_path order by f.file_path),'[]') from public.document_files f where f.document_id=d.id) as paths,
 null::text bank_name,null::text identity_name
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
 and r.reviewed_by<>b.profile_id order by d.verified_at desc limit 1)
 from public.financial_verifications f join public.bank_accounts b on b.id=f.bank_account_id
 where f.status='pending' and b.profile_id=f.profile_id and b.profile_id<>auth.uid()
 and b.organization_id is null and b.deleted_at is null and b.is_active and b.evidence_path is not null
 order by submitted_at,id limit 50)q;
 return result;
end $function$;

create or replace function kaoid_private.review_target_base_r14b(p_target uuid)
 returns jsonb
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare result jsonb;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
 select coalesce(jsonb_agg(to_jsonb(q)),'[]') into result from (
 select r.id,r.status,r.submitted_at,d.document_type,d.full_name,d.document_number,d.issued_date,d.expiry_date,
 d.issuing_country,d.residence_format,
 (select coalesce(jsonb_agg(f.file_path order by f.file_path),'[]') from public.document_files f where f.document_id=d.id) as paths,
 null::text bank_name,null::text identity_name
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
 and r.reviewed_by<>b.profile_id order by d.verified_at desc limit 1)
 from public.financial_verifications f join public.bank_accounts b on b.id=f.bank_account_id
 where f.id=p_target and f.status='pending' and b.profile_id=f.profile_id and b.profile_id<>auth.uid()
 and b.organization_id is null and b.deleted_at is null and b.is_active and b.evidence_path is not null
 order by submitted_at,id limit 50)q;
 return result;
end $function$;

create or replace function secondhand.seller_status_r20f(p_profile_id uuid)
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to ''
as $function$
declare
  v_email boolean := false;
  v_phone boolean := false;
  v_bank boolean := false;
  v_kao_id boolean := false;
  v_can_list boolean;
begin
  if p_profile_id is not null then
    select u.email_confirmed_at is not null, u.phone_confirmed_at is not null
      into v_email, v_phone
      from auth.users u where u.id = p_profile_id;
    v_bank := exists (
      select 1
        from public.financial_verifications fv
        join public.bank_accounts ba on ba.id = fv.bank_account_id
       where fv.identity_type = 'personal' and fv.profile_id = p_profile_id and fv.organization_id is null
         and fv.status = 'approved' and fv.name_match_status = 'matched'
         and ba.profile_id = p_profile_id and ba.organization_id is null
         and ba.is_verified and ba.is_active and ba.deleted_at is null and ba.status = 'verified'
         and kaoid_private.bank_holder_name_ok_r20g(p_profile_id, ba.account_name));
    v_kao_id := exists (
      select 1 from public.kao_id_identities k
       where k.profile_id = p_profile_id and k.organization_id is null
         and k.identity_type = 'personal' and k.status = 'active');
  end if;
  v_email := coalesce(v_email, false);
  v_phone := coalesce(v_phone, false);
  v_can_list := v_email and v_phone and v_bank and v_kao_id;
  return jsonb_build_object(
    'email', v_email,
    'phone', v_phone,
    'bank', v_bank,
    'kao_id', v_kao_id,
    'verified', v_can_list,
    'can_list', v_can_list,
    'price_limit', null
  );
end $function$;

create unique index if not exists shops_one_personal_r27a on public.shops (owner_id)
  where seller_identity_type = 'personal';
create unique index if not exists shops_one_business_r27a on public.shops (organization_id)
  where seller_identity_type = 'business';
