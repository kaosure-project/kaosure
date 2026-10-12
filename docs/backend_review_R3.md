# Backend review R3 — หลักฐานจากระบบจริง

ตรวจแบบอ่าน metadata ของ Supabase `kaosure-project's Project` วันที่ 2026-09-21 ไม่อ่านข้อมูลส่วนบุคคลจากแถวผู้ใช้ ไม่แก้ schema/permissions และไม่เรียกอนุมัติ KYC หรือออก Kao ID

## ยืนยันได้แล้ว

- `auth.users` มี trigger `on_auth_user_created` เรียก `handle_new_user` เพื่อสร้าง profiles และ verifications ในการสมัครใหม่ ดังนั้นไม่ต้องเพิ่ม client-side createProfile เพื่อทับ trigger
- `handle_auth_user_updated` ซิงก์ email/phone confirmation จาก Auth ไปยัง profiles และ verifications
- `issue_kao_id` ตรวจ authentication, profile ownership, สถานะ verifications.status = approved ก่อนออกเลขใหม่ และมี unique constraint ของ profile_id/kao_id
- authenticated ไม่มี UPDATE privileges ของ verifications: เป็นพื้นฐานที่ถูกต้องในการไม่ให้ผู้ใช้ยืนยันตัวเอง
- ไม่พบ Edge Functions ที่ deploy ในโปรเจกต์นี้จากรายการที่ตรวจ

## P0 — สมาชิกแก้ค่าระดับสิทธิ์ของตัวเองได้

หลักฐาน: authenticated มี table-level UPDATE ของ public.profiles ทำให้ has_column_privilege(..., role, UPDATE) และทุกคอลัมน์เป็น true; RLS จำกัดเพียง id = auth.uid(); trigger บน profiles ที่พบมีเพียง set_updated_at

ผล: การซ่อนฟิลด์ใน Flutter ไม่ป้องกันการส่ง UPDATE role/account_level/account_status/seller_level/trust_score/email_verified_at/phone_verified_at โดยตรงให้แถวตัวเอง ไม่มีการยิงคำขอเปลี่ยนสิทธิ์ผู้ใช้เพื่อพิสูจน์ exploit ในรอบนี้

ข้อแก้ที่จัดไว้: `database_review/profile_column_permissions_review.sql` ถอน table-level UPDATE และให้เฉพาะ display_name/avatar_url/bio/language_code ที่ editor ปัจจุบันใช้งานจริง พร้อม assertions ตรวจสิทธิ์คอลัมน์

ผลกระทบที่ต้องรับรู้ก่อน deploy: client-side setUsername และการแก้ legal name ตรงจาก clients อื่นจะไม่ได้สิทธิ์จาก grant นี้ ต้องใช้ server operation ที่ตรวจเงื่อนไข ไม่ให้คง table-wide UPDATE เพียงเพื่อรองรับฟิลด์เหล่านี้

อ้างอิง: [Column-level security](https://supabase.com/docs/guides/database/postgres/column-level-security)

## P1 — บทบาทผู้อนุมัติ KYC ใช้คนละแหล่ง

หลักฐาน: approve_kyc_verification ตรวจ profiles.role = kyc_officer แต่ profiles_role_check อนุญาตเฉพาะ user/seller/moderator/admin/super_admin จึงไม่สามารถมีค่า kyc_officer ตาม constraint ปัจจุบัน ขณะที่ admin_roles มี kyc_officer อยู่จริง

ข้อแก้ที่จัดไว้: `database_review/kyc_reviewer_assignment_review.sql` ตรวจ active admin assignment ของ role code kyc_officer ตามรูปแบบ governance ปัจจุบัน และใช้ IS DISTINCT FROM ป้องกัน reviewer ID เป็น null หลุดการเปรียบเทียบ

ยังต้องทดสอบ: reviewer ที่มี/ไม่มีสิทธิ์, assignment หมดอายุ, reviewer ถูกพัก, request ผิดสถานะ/เอกสารไม่ครบ, concurrent approval, audit log, การพิจารณาเคสของตนเองตามกฎที่อนุมัติ ไม่ถือว่าเปลี่ยน if block แล้วทำ KYC workflow เสร็จ

## SQL ที่แนบยังไม่ใช่ migration ที่นำขึ้นจริง

SQL สองไฟล์เป็น concrete review scripts และจบด้วย ROLLBACK โดยตั้งใจ ไม่ควรเปลี่ยนเป็น COMMIT ก่อนทดสอบและอนุมัติผลกระทบ

รอบนี้ไม่มี Supabase CLI ใน runtime จึงไม่ได้สร้างชื่อ migration เองหรืออ้างว่ามี migration history การนำขึ้นจริงต้องทำผ่านกระบวนการ migration ของโปรเจกต์ เก็บ baseline จาก JSON ที่แนบ ตรวจ grants หลังแก้ และรันทดสอบ profile editor/ผู้ใช้ธรรมดา/ผู้ตรวจใน development ก่อน production

## ข้อค้นพบอื่นที่ไม่ควรตีความเกินหลักฐาน

- Security Advisors: RLS enabled/no policy 10 รายการ (INFO), mutable function search_path 5, extension in public 2, anon-executable SECURITY DEFINER 12, authenticated-executable SECURITY DEFINER 31, leaked-password protection disabled 1
- SECURITY DEFINER ที่ callable ไม่ได้แปลว่าทุกรายการเป็นช่องโหว่ ต้องอ่าน auth/ownership/permission ในแต่ละฟังก์ชันก่อน revoke
- การตั้งค่าลืมรหัส/ยืนยันอีเมล/session ต้องทดสอบด้วย Auth จริง; source signUp เดิมใช้ user ที่ตอบกลับโดยไม่แยกผลว่า session พร้อมหรือยัง จึงเป็นจุดตรวจ E2E ก่อนปิด Gate 01
- has_column_privilege เป็นการตรวจโครงสร้างสิทธิ์ ไม่ใช่ penetration test หรือผลยืนยันทุก API

Remediation links จาก Advisors:

- [RLS without policy](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy)
- [Function search_path](https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable)
- [Extensions in public](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public)
- [Anon executable definer functions](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable)
- [Authenticated executable definer functions](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable)
- [Leaked password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)
