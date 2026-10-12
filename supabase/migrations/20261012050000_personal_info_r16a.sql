-- Kao ID personal information (R16a):
--   * ID-card address captured with new Thai national ID submissions and shown to reviewers.
--   * Owner summary returns masked phone / document number only.
--   * Full values require a session that proved the password within 5 minutes; every reveal is logged.

alter table public.identity_documents
  add column if not exists address_line text,
  add column if not exists address_subdistrict text,
  add column if not exists address_district text,
  add column if not exists address_province text,
  add column if not exists address_postal_code text;

alter table public.identity_documents
  drop constraint if exists identity_documents_address_r16a;
alter table public.identity_documents
  add constraint identity_documents_address_r16a check (
    (address_line is null or length(btrim(address_line)) between 3 and 300)
    and (address_subdistrict is null or length(btrim(address_subdistrict)) between 2 and 100)
    and (address_district is null or length(btrim(address_district)) between 2 and 100)
    and (address_province is null or length(btrim(address_province)) between 2 and 100)
    and (address_postal_code is null or address_postal_code ~ '^[0-9]{5}$'));

-- ---------------------------------------------------------------------------
-- Formatting / masking helpers
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.phone_digits_r16a(p_phone text) returns text
language sql immutable set search_path = '' as $$
  select nullif(regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g'), '');
$$;

create or replace function kaoid_private.format_phone_r16a(p_phone text, p_masked boolean) returns text
language sql immutable set search_path = '' as $$
  with d as (select kaoid_private.phone_digits_r16a(p_phone) as n)
  select case
    when n is null then null
    when n ~ '^66[0-9]{9}$' then
      '0' || substr(n, 3, 2) || '-' || case when p_masked then 'XXX' else substr(n, 5, 3) end || '-' || right(n, 4)
    when length(n) >= 8 then
      '+' || left(n, 2) || ' ' || case when p_masked then repeat('X', length(n) - 6) else substr(n, 3, length(n) - 6) end
        || ' ' || right(n, 4)
    else case when p_masked then repeat('X', length(n)) else n end
  end from d;
$$;

create or replace function kaoid_private.format_document_number_r16a(p_type text, p_number text, p_masked boolean)
returns text language sql immutable set search_path = '' as $$
  select case
    when p_number is null or btrim(p_number) = '' then null
    when p_type = 'thai_national_id' and p_number ~ '^[0-9]{13}$' then
      left(p_number, 1) || '-' ||
      case when p_masked then 'XXXX-XXXXX' else substr(p_number, 2, 4) || '-' || substr(p_number, 6, 5) end
      || '-' || substr(p_number, 11, 2) || '-' || right(p_number, 1)
    when length(p_number) > 4 then
      case when p_masked then left(p_number, 2) || repeat('X', length(p_number) - 4) || right(p_number, 2)
      else p_number end
    else case when p_masked then repeat('X', length(p_number)) else p_number end
  end;
$$;

-- Most relevant identity document: a valid approved one, else the one under review, else the latest.
create or replace function kaoid_private.current_identity_document_r16a(p_owner uuid)
returns setof public.identity_documents language sql stable security definer set search_path = '' as $$
  select d.* from public.identity_documents d
  where d.owner_id = p_owner and d.deleted_at is null and d.status <> 'draft'
  order by (d.status = 'approved' and (d.expiry_date is null or d.expiry_date >= current_date)) desc,
           (d.status = 'pending_review') desc,
           d.created_at desc
  limit 1;
$$;

create or replace function kaoid_private.document_state_r16a(p_status text, p_expiry date) returns text
language sql immutable set search_path = '' as $$
  select case
    when p_status = 'approved' and (p_expiry is null or p_expiry >= current_date) then 'verified'
    when p_status = 'approved' or p_status = 'expired' then 'expired'
    when p_status = 'pending_review' then 'pending'
    when p_status = 'rejected' then 'rejected'
    when p_status = 'revoked' then 'revoked'
    else 'unverified'
  end;
$$;

-- ---------------------------------------------------------------------------
-- Owner summary (masked)
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.my_personal_info_r16a() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  u auth.users%rowtype;
  p public.profiles%rowtype;
  d public.identity_documents%rowtype;
  v_state text;
  v_profile_name text;
  v_name text;
begin
  if v_uid is null or not coalesce(kaoid_private.account_active_r9f(), false) then
    raise exception 'session_required' using errcode = '42501';
  end if;
  select * into u from auth.users where id = v_uid;
  select * into p from public.profiles where id = v_uid;
  select * into d from kaoid_private.current_identity_document_r16a(v_uid);
  v_state := case when d.id is null then 'none' else kaoid_private.document_state_r16a(d.status, d.expiry_date) end;
  v_profile_name := nullif(btrim(concat_ws(' ', p.first_name, p.last_name)), '');
  v_name := case when v_state = 'verified' then d.full_name else coalesce(v_profile_name, d.full_name) end;

  return jsonb_build_object(
    'name', jsonb_build_object(
      'value', v_name,
      'status', case when v_name is null then 'none'
                     when v_state = 'verified' then 'verified'
                     when v_state = 'pending' then 'pending'
                     else 'unverified' end),
    'email', jsonb_build_object(
      'value', nullif(u.email, ''),
      'status', case when coalesce(u.email, '') = '' then 'none'
                     when u.email_confirmed_at is not null then 'verified' else 'unverified' end),
    'phone', jsonb_build_object(
      'masked', kaoid_private.format_phone_r16a(u.phone, true),
      'status', case when kaoid_private.phone_digits_r16a(u.phone) is null then 'none'
                     when u.phone_confirmed_at is not null then 'verified' else 'unverified' end),
    'document', case when d.id is null then null else jsonb_build_object(
      'type', d.document_type,
      'masked_number', kaoid_private.format_document_number_r16a(d.document_type, d.document_number, true),
      'status', v_state,
      'issued_date', d.issued_date,
      'expiry_date', d.expiry_date,
      'country', coalesce(d.issuing_country, d.country_code)) end,
    'address', case when d.id is null or d.address_line is null then null else jsonb_build_object(
      'line', d.address_line,
      'subdistrict', d.address_subdistrict,
      'district', d.address_district,
      'province', d.address_province,
      'postal_code', d.address_postal_code,
      'status', v_state) end);
end $$;

create or replace function public.my_personal_info_r16a() returns jsonb
language sql security invoker set search_path = '' as $$ select kaoid_private.my_personal_info_r16a(); $$;

-- ---------------------------------------------------------------------------
-- Password-gated reveal of a single field
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.reveal_my_personal_field_r16a(p_field text) returns text
language plpgsql volatile security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_value text;
  v_target uuid := v_uid;
  v_table text := 'auth.users';
  d public.identity_documents%rowtype;
begin
  if v_uid is null or not coalesce(kaoid_private.account_active_r9f(), false)
     or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'session_required' using errcode = '42501';
  end if;
  if p_field is null or p_field not in ('phone', 'id_number') then
    raise exception 'invalid_field' using errcode = '22023';
  end if;
  if not exists (
    select 1 from auth.mfa_amr_claims c
    where c.session_id::text = auth.jwt()->>'session_id'
      and c.authentication_method = 'password'
      and c.updated_at > now() - interval '5 minutes') then
    raise exception 'password_required' using errcode = '42501';
  end if;
  if (select count(*) from public.activity_logs
      where profile_id = v_uid and action = 'personal_info.reveal'
        and created_at > now() - interval '1 hour') >= 30 then
    raise exception 'rate_limited' using errcode = '54000';
  end if;

  if p_field = 'phone' then
    select kaoid_private.format_phone_r16a(phone, false) into v_value from auth.users where id = v_uid;
  else
    select * into d from kaoid_private.current_identity_document_r16a(v_uid);
    v_value := kaoid_private.format_document_number_r16a(d.document_type, d.document_number, false);
    v_target := d.id;
    v_table := 'identity_documents';
  end if;
  if v_value is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;

  insert into public.activity_logs(profile_id, action, target_table, target_id, description)
  values (v_uid, 'personal_info.reveal', v_table, v_target, 'Owner revealed ' || p_field);
  return v_value;
end $$;

create or replace function public.reveal_my_personal_field_r16a(p_field text) returns text
language sql security invoker set search_path = '' as $$ select kaoid_private.reveal_my_personal_field_r16a(p_field); $$;

-- ---------------------------------------------------------------------------
-- National ID submission with address (replaces direct use of r7a by clients)
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.submit_national_id_r16a(
  p_id uuid, p_number text, p_full_name text, p_issued date, p_expiry date, p_front text, p_back text,
  p_address_line text, p_subdistrict text, p_district text, p_province text, p_postal_code text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_line text := btrim(p_address_line);
  v_sub text := btrim(p_subdistrict);
  v_dist text := btrim(p_district);
  v_prov text := btrim(p_province);
  v_post text := btrim(p_postal_code);
  d public.identity_documents%rowtype;
begin
  if v_line is null or length(v_line) not between 3 and 300
     or v_sub is null or length(v_sub) not between 2 and 100
     or v_dist is null or length(v_dist) not between 2 and 100
     or v_prov is null or length(v_prov) not between 2 and 100
     or v_post is null or v_post !~ '^[0-9]{5}$' then
    raise exception 'invalid_address' using errcode = '22023';
  end if;
  perform kaoid_private.submit_national_id_r7a(p_id, p_number, p_full_name, p_issued, p_expiry, p_front, p_back);
  select * into d from public.identity_documents where id = p_id and owner_id = v_uid for update;
  if d.address_line is null then
    if d.status is distinct from 'pending_review' then
      raise exception 'document_conflict' using errcode = '42501';
    end if;
    update public.identity_documents
       set address_line = v_line, address_subdistrict = v_sub, address_district = v_dist,
           address_province = v_prov, address_postal_code = v_post, updated_at = now()
     where id = p_id;
  elsif (d.address_line, d.address_subdistrict, d.address_district, d.address_province, d.address_postal_code)
        is distinct from (v_line, v_sub, v_dist, v_prov, v_post) then
    raise exception 'document_conflict' using errcode = '42501';
  end if;
  return p_id;
end $$;

create or replace function public.submit_national_id_r16a(
  p_id uuid, p_number text, p_full_name text, p_issued date, p_expiry date, p_front text, p_back text,
  p_address_line text, p_subdistrict text, p_district text, p_province text, p_postal_code text
) returns uuid language sql security invoker set search_path = '' as $$
  select kaoid_private.submit_national_id_r16a(p_id, p_number, p_full_name, p_issued, p_expiry, p_front, p_back,
    p_address_line, p_subdistrict, p_district, p_province, p_postal_code);
$$;

-- New national ID submissions must carry the card address.
revoke execute on function public.submit_national_id_r7a(uuid,text,text,date,date,text,text) from authenticated;
revoke execute on function kaoid_private.submit_national_id_r7a(uuid,text,text,date,date,text,text) from authenticated;

-- ---------------------------------------------------------------------------
-- Reviewer queue: include the card address next to the document
-- ---------------------------------------------------------------------------
alter function kaoid_private.review_queue_r7c() rename to review_queue_before_r16a;
revoke all on function kaoid_private.review_queue_before_r16a() from public, anon, authenticated;

create or replace function kaoid_private.review_queue_r7c() returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode = '42501'; end if;
  return (select coalesce(jsonb_agg(q || case when d.address_line is null then '{}'::jsonb else jsonb_build_object(
      'address_line', d.address_line, 'address_subdistrict', d.address_subdistrict,
      'address_district', d.address_district, 'address_province', d.address_province,
      'address_postal_code', d.address_postal_code) end order by ord), '[]'::jsonb)
    from jsonb_array_elements(kaoid_private.review_queue_before_r16a()) with ordinality a(q, ord)
    left join public.verification_requests r on r.id = (q->>'id')::uuid
    left join public.identity_documents d on d.id = coalesce(r.document_id, (q->>'id')::uuid));
end $$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
revoke all on function
  kaoid_private.phone_digits_r16a(text),
  kaoid_private.format_phone_r16a(text, boolean),
  kaoid_private.format_document_number_r16a(text, text, boolean),
  kaoid_private.current_identity_document_r16a(uuid),
  kaoid_private.document_state_r16a(text, date),
  kaoid_private.my_personal_info_r16a(),
  kaoid_private.reveal_my_personal_field_r16a(text),
  kaoid_private.submit_national_id_r16a(uuid,text,text,date,date,text,text,text,text,text,text,text),
  kaoid_private.review_queue_r7c(),
  public.my_personal_info_r16a(),
  public.reveal_my_personal_field_r16a(text),
  public.submit_national_id_r16a(uuid,text,text,date,date,text,text,text,text,text,text,text)
from public, anon, authenticated;

grant execute on function
  kaoid_private.my_personal_info_r16a(),
  kaoid_private.reveal_my_personal_field_r16a(text),
  kaoid_private.submit_national_id_r16a(uuid,text,text,date,date,text,text,text,text,text,text,text),
  kaoid_private.review_queue_r7c(),
  public.my_personal_info_r16a(),
  public.reveal_my_personal_field_r16a(text),
  public.submit_national_id_r16a(uuid,text,text,date,date,text,text,text,text,text,text,text)
to authenticated;
