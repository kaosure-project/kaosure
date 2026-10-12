-- R20g: a bank account can be verified before identity verification (KYC).
--   * With an approved, unexpired identity document the holder name must match
--     that document (as before).
--   * Without one, it must match the profile first + last name. The reviewer
--     still checks the bank evidence by hand.
--   * Titles (นาย, นาง, นางสาว, Mr., Ms., ...) and spacing are ignored.
-- The same rule decides whether the Secondhand seller tier counts the bank, so
-- a later identity document with a different name stops the account counting.
-- A Kao ID is still issued only after identity verification.

create or replace function kaoid_private.holder_name_key_r20g(p_name text)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(btrim(regexp_replace(
    regexp_replace(lower(btrim(coalesce(p_name, ''))),
      '^((นางสาว|นาง|นาย|น\.ส\.|ด\.ช\.|ด\.ญ\.)\s*|(mr|mrs|ms|miss|dr)(\.\s*|\s+))', ''),
    '\s+', ' ', 'g')), '')
$$;

create or replace function kaoid_private.bank_holder_name_ok_r20g(p_profile_id uuid, p_account_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
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
       and d.document_type in ('thai_national_id', 'passport') and d.deleted_at is null
       and (d.expiry_date is null or d.expiry_date >= current_date)
       and r.status = 'approved' and r.reviewed_by <> p_profile_id)
    into v_has_identity;
  if v_has_identity then
    return exists (
      select 1
        from public.identity_documents d
        join public.verification_requests r on r.document_id = d.id
       where d.owner_id = p_profile_id and d.status = 'approved'
         and d.document_type in ('thai_national_id', 'passport') and d.deleted_at is null
         and (d.expiry_date is null or d.expiry_date >= current_date)
         and r.status = 'approved' and r.reviewed_by <> p_profile_id
         and kaoid_private.holder_name_key_r20g(d.full_name) = v_key);
  end if;
  return exists (
    select 1 from public.profiles p
     where p.id = p_profile_id
       and nullif(btrim(p.first_name), '') is not null and nullif(btrim(p.last_name), '') is not null
       and kaoid_private.holder_name_key_r20g(concat_ws(' ', p.first_name, p.last_name)) = v_key);
end $$;

revoke all on function kaoid_private.holder_name_key_r20g(text) from public, anon, authenticated;
revoke all on function kaoid_private.bank_holder_name_ok_r20g(uuid, text) from public, anon, authenticated;

-- R9c review with the holder name rule above.
create or replace function kaoid_private.review_bank_r9c(p_request uuid, p_approve boolean, p_reason text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare f public.financial_verifications%rowtype; b public.bank_accounts%rowtype; result text;
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501'; end if;
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
  if exists(select 1 from public.bank_accounts x where x.profile_id<>b.profile_id and x.deleted_at is null and x.is_verified
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
end $function$;

-- ---------------------------------------------------------------------------
-- Secondhand seller tier (R20f) counts only a bank account whose holder name
-- still passes the rule.
-- ---------------------------------------------------------------------------
create or replace function secondhand.seller_status_r20f(p_profile_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_email boolean := false;
  v_phone boolean := false;
  v_bank boolean := false;
  v_kao_id boolean := false;
  v_verified boolean;
  v_can_list boolean;
  v_limit numeric(12,2);
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
  v_verified := v_kao_id and v_bank;
  v_can_list := v_verified or (v_email and v_phone and v_bank);
  if not v_verified then
    select s.unverified_max_price into v_limit from secondhand.market_settings s where s.id;
  end if;
  return jsonb_build_object(
    'email', v_email,
    'phone', v_phone,
    'bank', v_bank,
    'kao_id', v_kao_id,
    'verified', v_verified,
    'can_list', v_can_list,
    'price_limit', v_limit
  );
end $$;

revoke all on function secondhand.seller_status_r20f(uuid) from public, anon, authenticated;
