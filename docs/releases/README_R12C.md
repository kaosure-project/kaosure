# R12C — กระเป๋ารายสมาชิกและอนุมัติพาร์ตเนอร์ขนส่ง

ต่อจาก R12B ที่ผู้ใช้ยืนยัน analyzer สะอาดและ321 tests ผ่าน

## ทางเข้า
- Owner: ศูนย์ผู้ดูแล Kao ID → พาร์ตเนอร์ขนส่ง
- Owner: จัดการสมาชิก → ค้นหาบัญชี → กระเป๋าที่ผูกกับพาร์ตเนอร์
- สมาชิก: กระเป๋าเงินกลาง → กระเป๋าที่ผูกกับพาร์ตเนอร์

## ทำงานในชุดนี้
- ขนส่งใช้ทะเบียนและขั้นอนุมัติ R12B เดิม เพิ่มชนิด finance/shipping แยกสิทธิ์ที่ฐานข้อมูล
- ขนส่งเลือกสอบถามราคา/สร้างจัดส่ง/ติดตาม/ยกเลิก โดยเป็นขอบเขตการเชื่อมต่อ ยังไม่มี carrier adapter จริง
- กดอนุญาต/ปิด/ส่งพิจารณาใหม่โดย Owner พร้อมประวัติและตรวจ readiness เดิม
- หนึ่งพาร์ตเนอร์การเงินผูกสมาชิกได้หลายคน หนึ่งสมาชิกมีหนึ่ง binding ต่อพาร์ตเนอร์/THB
- รหัสกระเป๋าฝั่งพาร์ตเนอร์ไม่ซ้ำและย้ายเจ้าของด้วยคำสั่ง link ไม่ได้
- เฉพาะ server ที่ตรวจความเป็นเจ้าของฝั่งผู้ให้บริการแล้วเท่านั้นที่สร้าง binding ได้ ไม่มีช่องให้สมาชิกหรือ Owner ใส่รหัสกระเป๋าคนอื่นเอง
- ผูกกับ profile UUID เดิม ไม่ใช้ email/phone เป็นกุญแจเชื่อม
- Snapshot พร้อมใช้/พัก/รอดำเนินการ เก็บรายงานแยกตามพาร์ตเนอร์ พร้อม observed_at และ received_at
- ส่งซ้ำ event/hash/normalized payload เดิมคืน duplicate; ข้อมูลขัดกันปฏิเสธ; sequence/time เก่าไม่ทับล่าสุด
- การรับ receipt กับการบันทึก snapshot อยู่ transaction เดียวกัน ผิดพลาด rollback ทั้งคู่
- แสดงเงินเป็น decimal string; THB สองตำแหน่งเท่านั้น ไม่ปัดเศษข้อมูลเข้าโดยเงียบ
- สมาชิกอ่านเฉพาะของตนและเฉพาะ live; Owner ดู sandbox/live ได้แยกกัน
- ไม่มี report แสดงว่าไม่มีข้อมูล ไม่ใส่ศูนย์แทน; รายงานเกิน30นาทีแจ้งว่าเก่า
- โหลดหน้าใหม่อ่าน DB ไม่ได้สั่ง provider fetch; ยังไม่มี polling provider จริง
- Owner เห็นประวัติรับรายงาน applied/older ล่าสุด20รายการ ไม่มีปุ่มแก้ยอดโดยตรง
- บัญชีที่มี partner wallet ยังปิดไม่ได้จนกว่าจะต่อการตรวจภาระฝั่ง provider ครบ แม้ snapshot เป็นศูนย์ก็ยังไม่ถือว่าไม่มีภาระ
- ภาษา7ภาษา + zh fallback

## ติดตั้ง
สำรอง lib,test แล้วแตก ZIP ทับหลัง R12B
```
flutter gen-l10n
flutter analyze
flutter test test/localization/operations_r12c_test.dart
flutter test test/localization
```
SQL migrations partner_members_shipping_r12c และ partner_receipts_concurrency_r12c ติดตั้งแล้วในโปรเจกต์ Supabase ที่เชื่อมอยู่ ไม่ต้องรันซ้ำ
Flutter SDK ไม่มีในเครื่องจัดชุด จึงยังไม่ได้รัน Flutter analyze/tests

## Server contract
server/member_wallet_gateway.mjs เป็นโมดูลรอติดตั้งใน backend ที่เหมาะสม ยังไม่ deploy endpoint
registry เริ่มว่าง ไม่มี fake provider หรือกุญแจจริง
adapter verifyAndNormalizeBalance ต้องตรวจ raw signature, freshness, event schema, merchant/account identity ก่อน normalize
normalized currency ต้อง THB, available/held/pending เป็น string, sequence เป็น string integer เพิ่มขึ้นตามข้อมูลต้นทาง ไม่ใช้ JS floating-point กับยอดเงิน
sequence ต้องครอบคลุมกระเป๋าแต่ละใบและคงลำดับข้าม retries; หาก API ไม่มี sequence ต้องออกแบบ authoritative fetch/version handling ของเจ้านั้นก่อนเปิด
ต้องส่งผ่าน public.wallet_sync_r12c โดย service role ฝั่ง server เท่านั้น ไม่เรียก generic receive ก่อน wallet sync
binding code/kind/environment มาจาก server configuration ไม่รับตาม JSON ผู้ส่ง
public.wallet_link_r12c เป็น trusted-server operation ไม่ตรวจเอกสาร KYC ของพาร์ตเนอร์เอง; provider adapter ต้องพิสูจน์ ownership/consent ก่อนเรียก
การมี binding ไม่เปลี่ยนสถานะ KYC, Kao ID, สิทธิ์ Owner หรือความพร้อมจ่ายเงิน
shared row lock บน provider ให้รายการคนละสมาชิกทำงานได้พร้อมกัน; owner disable ใช้ update lock; unique event constraints และ link locks กันชน แต่ยังไม่ใช่หลักฐาน load capacity

## ตรวจแล้ว
- SQL link_regression: หลายสมาชิก/partner, retry link, conflict, shipping cannot link money, cross-user denial, client cannot link, closure guard — ผ่าน rollback
- SQL sync_regression: applied, duplicate, older, normalized conflict, wrong environment, final amount and event count — ผ่าน rollback
- SQL shipping_regression: reject finance scope, accept tracking receipt, reject payment, reject after disable — ผ่าน rollback
- Node tests8ผ่าน
- Dart grammar/ARB keys ตรวจผ่าน ไม่ใช่ Flutter compile
- Flutter testsใหม่11รายการแนบไว้ ยังต้องรันบนเครื่องผู้ใช้
- ไม่ได้สร้าง binding/report/carrier จริง ไม่ได้ย้ายเงินจริง

## ยังไม่ครบการใช้งานจริงทั้งหมด
ชุดนี้ปิดส่วนทะเบียนอนุมัติขนส่งและจุดเชื่อม/การแสดงข้อมูลรายสมาชิก ไม่มีตัวเชื่อมผู้ให้บริการจริง
ยังต้องทำ/เชื่อม: provisioning กระเป๋าตาม API, credentials rotation, webhook endpoint, durable processing/retry/error queue, ledger/reconciliation, payment/refund/payout กับคำสั่งซื้อ และการปิดกระเป๋าที่มีภาระ
ยังไม่มีหน้าสร้างพัสดุ/ค่าส่งจริง/ใบปะหน้า/ติดตามสถานะขนส่งจาก provider
Owner ยังไม่มีเครื่องมือครบทุกหมวดทั้ง ecosystem; ไม่ควรนับการอนุมัติ provider ว่าระบบการเงินและขนส่งเสร็จแล้ว
ก่อนเปิด live ต้องมี provider sandbox/end-to-end/security/concurrency/load tests; ตัวเลขสมาชิกที่รองรับยังไม่รับรอง
ข้อค้าง Kao ID/องค์กร/SMS/event-email/retention เดิมคงอยู่

## Security advisor
ตรวจหลัง migration มีข้อสังเกตเดิมเรื่อง public extensions, legacy public SECURITY DEFINER และ leaked-password protection; private RLS/no policy ใช้ปิด client โดยตั้งใจ
https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable
https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public
https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
