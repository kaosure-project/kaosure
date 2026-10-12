-- r16b: KYC for foreign residents in Thailand
--   * Passport: nationality (ICAO 3-letter code) and a Thai address are required.
--   * Thai government documents for foreigners (work permit, residence certificate,
--     pink card, Tor.Ror.13): 13-digit personal number with DOPA check digit and the
--     address on the document.
--   * Thai addresses use the 77-province list; all checks run on the server.

alter table public.identity_documents
  add column if not exists nationality text,
  add column if not exists thai_document_kind text;

alter table public.identity_documents
  drop constraint if exists identity_documents_foreign_r16b;
alter table public.identity_documents
  add constraint identity_documents_foreign_r16b check (
    (nationality is null or nationality ~ '^[A-Z]{3}$')
    and (thai_document_kind is null or thai_document_kind in
      ('work_permit', 'residence_certificate', 'pink_card', 'house_registration_tr13')));

-- ---------------------------------------------------------------------------
-- Reference checks
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.thai_provinces_r16b() returns text[]
language sql immutable set search_path = '' as $$
  select array[
    'กรุงเทพมหานคร','กระบี่','กาญจนบุรี','กาฬสินธุ์','กำแพงเพชร','ขอนแก่น','จันทบุรี','ฉะเชิงเทรา',
    'ชลบุรี','ชัยนาท','ชัยภูมิ','ชุมพร','เชียงราย','เชียงใหม่','ตรัง','ตราด','ตาก','นครนายก',
    'นครปฐม','นครพนม','นครราชสีมา','นครศรีธรรมราช','นครสวรรค์','นนทบุรี','นราธิวาส','น่าน',
    'บึงกาฬ','บุรีรัมย์','ปทุมธานี','ประจวบคีรีขันธ์','ปราจีนบุรี','ปัตตานี','พระนครศรีอยุธยา',
    'พะเยา','พังงา','พัทลุง','พิจิตร','พิษณุโลก','เพชรบุรี','เพชรบูรณ์','แพร่','ภูเก็ต',
    'มหาสารคาม','มุกดาหาร','แม่ฮ่องสอน','ยโสธร','ยะลา','ร้อยเอ็ด','ระนอง','ระยอง','ราชบุรี',
    'ลพบุรี','ลำปาง','ลำพูน','เลย','ศรีสะเกษ','สกลนคร','สงขลา','สตูล','สมุทรปราการ',
    'สมุทรสงคราม','สมุทรสาคร','สระแก้ว','สระบุรี','สิงห์บุรี','สุโขทัย','สุพรรณบุรี',
    'สุราษฎร์ธานี','สุรินทร์','หนองคาย','หนองบัวลำภู','อ่างทอง','อำนาจเจริญ','อุดรธานี',
    'อุตรดิตถ์','อุทัยธานี','อุบลราชธานี'
  ]::text[];
$$;

-- DOPA 13-digit personal number: weights 13..2 over the first 12 digits, mod 11.
create or replace function kaoid_private.valid_thai_pid_r16b(p_number text) returns boolean
language plpgsql immutable set search_path = '' as $$
declare
  total integer := 0;
begin
  if p_number is null or p_number !~ '^[0-9]{13}$' then return false; end if;
  for i in 1..12 loop
    total := total + substr(p_number, i, 1)::integer * (14 - i);
  end loop;
  return (11 - total % 11) % 10 = substr(p_number, 13, 1)::integer;
end $$;

create or replace function kaoid_private.check_thai_address_r16b(
  p_line text, p_subdistrict text, p_district text, p_province text, p_postal_code text
) returns void language plpgsql immutable set search_path = '' as $$
begin
  if btrim(p_line) is null or length(btrim(p_line)) not between 3 and 300
     or btrim(p_subdistrict) is null or length(btrim(p_subdistrict)) not between 2 and 100
     or btrim(p_district) is null or length(btrim(p_district)) not between 2 and 100
     or btrim(p_province) is null or not (btrim(p_province) = any (kaoid_private.thai_provinces_r16b()))
     or btrim(p_postal_code) is null or btrim(p_postal_code) !~ '^[1-9][0-9]{4}$' then
    raise exception 'invalid_address' using errcode = '22023';
  end if;
end $$;

-- Attach the foreign-resident fields to a document the caller has just submitted.
-- A retry with identical values is accepted; anything else is a conflict.
create or replace function kaoid_private.attach_foreign_fields_r16b(
  p_id uuid, p_nationality text, p_kind text,
  p_line text, p_subdistrict text, p_district text, p_province text, p_postal_code text
) returns void language plpgsql security definer set search_path = '' as $$
declare
  d public.identity_documents%rowtype;
  v_line text := btrim(p_line);
  v_sub text := btrim(p_subdistrict);
  v_dist text := btrim(p_district);
  v_prov text := btrim(p_province);
  v_post text := btrim(p_postal_code);
begin
  select * into d from public.identity_documents where id = p_id and owner_id = auth.uid() for update;
  if not found then raise exception 'document_conflict' using errcode = '42501'; end if;
  if d.address_line is null and d.nationality is null then
    if d.status is distinct from 'pending_review' then
      raise exception 'document_conflict' using errcode = '42501';
    end if;
    update public.identity_documents
       set nationality = p_nationality, thai_document_kind = p_kind,
           address_line = v_line, address_subdistrict = v_sub, address_district = v_dist,
           address_province = v_prov, address_postal_code = v_post, updated_at = now()
     where id = p_id;
  elsif (d.nationality, d.thai_document_kind, d.address_line, d.address_subdistrict,
         d.address_district, d.address_province, d.address_postal_code)
        is distinct from (p_nationality, p_kind, v_line, v_sub, v_dist, v_prov, v_post) then
    raise exception 'document_conflict' using errcode = '42501';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Passport with nationality and Thai address
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.submit_passport_r16b(
  p_id uuid, p_number text, p_given text, p_family text, p_single boolean, p_family_first boolean,
  p_nationality text, p_birth date, p_issued date, p_expiry date, p_path text,
  p_address_line text, p_subdistrict text, p_district text, p_province text, p_postal_code text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_number text := upper(btrim(p_number));
  v_nationality text := upper(btrim(p_nationality));
begin
  if v_number is null or v_number !~ '^[A-Z0-9]{5,20}$'
     or v_nationality is null or v_nationality !~ '^[A-Z]{3}$' then
    raise exception 'invalid_passport' using errcode = '22023';
  end if;
  perform kaoid_private.check_thai_address_r16b(p_address_line, p_subdistrict, p_district, p_province, p_postal_code);
  perform kaoid_private.submit_passport_r8a(p_id, v_number, p_given, p_family, p_single, p_family_first,
    v_nationality, p_birth, p_issued, p_expiry, p_path);
  perform kaoid_private.attach_foreign_fields_r16b(p_id, v_nationality, null,
    p_address_line, p_subdistrict, p_district, p_province, p_postal_code);
  return p_id;
end $$;

create or replace function public.submit_passport_r16b(
  p_id uuid, p_number text, p_given text, p_family text, p_single boolean, p_family_first boolean,
  p_nationality text, p_birth date, p_issued date, p_expiry date, p_path text,
  p_address_line text, p_subdistrict text, p_district text, p_province text, p_postal_code text
) returns uuid language sql security invoker set search_path = '' as $$
  select kaoid_private.submit_passport_r16b(p_id, p_number, p_given, p_family, p_single, p_family_first,
    p_nationality, p_birth, p_issued, p_expiry, p_path,
    p_address_line, p_subdistrict, p_district, p_province, p_postal_code);
$$;

-- ---------------------------------------------------------------------------
-- Thai government document for foreigners (stored as residence_card, issued by THA)
-- ---------------------------------------------------------------------------
create or replace function kaoid_private.submit_thai_foreign_document_r16b(
  p_id uuid, p_kind text, p_number text, p_given text, p_family text, p_single boolean,
  p_family_first boolean, p_nationality text, p_format text, p_no_expiry boolean,
  p_issued date, p_expiry date, p_front text, p_back text,
  p_address_line text, p_subdistrict text, p_district text, p_province text, p_postal_code text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_number text := btrim(p_number);
  v_nationality text := upper(btrim(p_nationality));
begin
  if p_kind is null or p_kind not in ('work_permit', 'residence_certificate', 'pink_card', 'house_registration_tr13')
     or not kaoid_private.valid_thai_pid_r16b(v_number)
     or v_nationality is null or v_nationality !~ '^[A-Z]{3}$' then
    raise exception 'invalid_residence' using errcode = '22023';
  end if;
  perform kaoid_private.check_thai_address_r16b(p_address_line, p_subdistrict, p_district, p_province, p_postal_code);
  perform kaoid_private.submit_residence_r8b(p_id, v_number, p_given, p_family, p_single, p_family_first,
    'THA', p_format, p_no_expiry, p_issued, p_expiry, p_front, p_back);
  perform kaoid_private.attach_foreign_fields_r16b(p_id, v_nationality, p_kind,
    p_address_line, p_subdistrict, p_district, p_province, p_postal_code);
  return p_id;
end $$;

create or replace function public.submit_thai_foreign_document_r16b(
  p_id uuid, p_kind text, p_number text, p_given text, p_family text, p_single boolean,
  p_family_first boolean, p_nationality text, p_format text, p_no_expiry boolean,
  p_issued date, p_expiry date, p_front text, p_back text,
  p_address_line text, p_subdistrict text, p_district text, p_province text, p_postal_code text
) returns uuid language sql security invoker set search_path = '' as $$
  select kaoid_private.submit_thai_foreign_document_r16b(p_id, p_kind, p_number, p_given, p_family, p_single,
    p_family_first, p_nationality, p_format, p_no_expiry, p_issued, p_expiry, p_front, p_back,
    p_address_line, p_subdistrict, p_district, p_province, p_postal_code);
$$;

-- New foreign submissions must carry nationality and address.
revoke execute on function public.submit_passport_r8a(uuid,text,text,text,boolean,boolean,text,date,date,date,text) from authenticated;
revoke execute on function kaoid_private.submit_passport_r8a(uuid,text,text,text,boolean,boolean,text,date,date,date,text) from authenticated;
revoke execute on function public.submit_residence_r8b(uuid,text,text,text,boolean,boolean,text,text,boolean,date,date,text,text) from authenticated;
revoke execute on function kaoid_private.submit_residence_r8b(uuid,text,text,text,boolean,boolean,text,text,boolean,date,date,text,text) from authenticated;

-- ---------------------------------------------------------------------------
-- Reviewer queue: nationality and Thai document kind next to the document
-- ---------------------------------------------------------------------------
alter function kaoid_private.review_queue_r7c() rename to review_queue_before_r16b;
revoke all on function kaoid_private.review_queue_before_r16b() from public, anon, authenticated;

create or replace function kaoid_private.review_queue_r7c() returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode = '42501'; end if;
  return (select coalesce(jsonb_agg(q || jsonb_strip_nulls(jsonb_build_object(
      'nationality', d.nationality, 'thai_document_kind', d.thai_document_kind)) order by ord), '[]'::jsonb)
    from jsonb_array_elements(kaoid_private.review_queue_before_r16b()) with ordinality a(q, ord)
    left join public.verification_requests r on r.id = (q->>'id')::uuid
    left join public.identity_documents d on d.id = coalesce(r.document_id, (q->>'id')::uuid));
end $$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
revoke all on function
  kaoid_private.thai_provinces_r16b(),
  kaoid_private.valid_thai_pid_r16b(text),
  kaoid_private.check_thai_address_r16b(text,text,text,text,text),
  kaoid_private.attach_foreign_fields_r16b(uuid,text,text,text,text,text,text,text),
  kaoid_private.submit_passport_r16b(uuid,text,text,text,boolean,boolean,text,date,date,date,text,text,text,text,text,text),
  kaoid_private.submit_thai_foreign_document_r16b(uuid,text,text,text,text,boolean,boolean,text,text,boolean,date,date,text,text,text,text,text,text,text),
  kaoid_private.review_queue_r7c(),
  public.submit_passport_r16b(uuid,text,text,text,boolean,boolean,text,date,date,date,text,text,text,text,text,text),
  public.submit_thai_foreign_document_r16b(uuid,text,text,text,text,boolean,boolean,text,text,boolean,date,date,text,text,text,text,text,text,text)
from public, anon, authenticated;

grant execute on function
  kaoid_private.submit_passport_r16b(uuid,text,text,text,boolean,boolean,text,date,date,date,text,text,text,text,text,text),
  kaoid_private.submit_thai_foreign_document_r16b(uuid,text,text,text,text,boolean,boolean,text,text,boolean,date,date,text,text,text,text,text,text,text),
  kaoid_private.review_queue_r7c(),
  public.submit_passport_r16b(uuid,text,text,text,boolean,boolean,text,date,date,date,text,text,text,text,text,text),
  public.submit_thai_foreign_document_r16b(uuid,text,text,text,text,boolean,boolean,text,text,boolean,date,date,text,text,text,text,text,text,text)
to authenticated;
