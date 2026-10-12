# R12B — Owner จัดการพาร์ตเนอร์การเงินหลายเจ้า

ฐานก่อนติดตั้ง: R12A ผู้ใช้รายงาน analyze สะอาด เทสต์กระเป๋า11 และรวม310ผ่าน
เข้า ศูนย์ผู้ดูแล Kao ID → พาร์ตเนอร์การเงิน

## ใช้งานได้ในชุดนี้
1. Owner ลงทะเบียนชื่อพาร์ตเนอร์จริง รหัสเฉพาะ เลือก sandbox/live และขอบเขตบริการ
2. กดอนุญาตหรือปฏิเสธจากหน้าจอ พร้อมเหตุผล
3. เมื่อฝั่งเซิร์ฟเวอร์รายงานผลตรวจตัวเชื่อมที่ยังใช้ได้ จึงกดเปิดการเชื่อมต่อได้
4. ปิดการเชื่อมต่อได้ และส่งกลับพิจารณาใหม่ได้โดยไม่ลบประวัติ
5. แยกสถานะอนุญาต / พร้อมทางเทคนิค / เปิดการเชื่อมต่อชัดเจน
6. ประวัติ20รายการล่าสุดระบุ UUID ผู้ทำจริงและบทบาทขณะทำรายการ ระบบแสดงเป็นระบบ
7. หน้าจอใหม่ครบ7ภาษา พร้อม zh fallback; ซ่อนข้อมูลและกันคำสั่งหลังเปลี่ยนบัญชี

ตอนนี้เป็นการลงทะเบียนโดย Owner ไม่มีหน้าให้บุคคลภายนอกสมัครเป็นพาร์ตเนอร์เอง
ไม่มีพาร์ตเนอร์จริงถูกลงทะเบียน/อนุญาตแทน Owner
ยังไม่มีตัวเชื่อมผู้ให้บริการจริง กุญแจ หรือ endpoint รับเว็บฮุกที่เปิดใช้งาน
ปุ่มเปิดจะถูกปิดไว้ตามข้อมูลจริง จนกว่าจะมีรายงานจากเซิร์ฟเวอร์

## ติดตั้ง Flutter
สำรอง lib,test แตก ZIP แล้ว:
```
flutter gen-l10n
flutter analyze
flutter test test/localization/partners_r12b_test.dart
flutter test test/localization
```
ฐานข้อมูลติดตั้ง migrations partner_control_r12b และ partner_service_schema_r12b แล้ว ไม่ต้องรันซ้ำในโปรเจกต์ที่เชื่อมอยู่นี้
Flutter SDK ไม่พร้อมในเครื่องจัดชุด ยังไม่ได้รัน Flutter analyze/tests

## การออกแบบ
- แต่ละคู่ code+environment มีทะเบียนและสิทธิ์ของตัวเอง ไม่มี provider ค่าเริ่มต้นแบบสุ่ม
- เงินแต่ละพาร์ตเนอร์ยังไม่ถูกรวมยอดหรือโอนไปมาระหว่างเจ้า
- ขอบเขต balance/payment/refund/payout/topup เป็นรายการสิทธิ์ที่เตรียมไว้ ไม่ยืนยันว่าบริการเหล่านี้เชื่อมจริงแล้ว
- Owner ใช้สิทธิ์ company_owners เดิมและ active live session ตรวจฝั่งฐานข้อมูลทุกคำสั่ง
- version/revision ป้องกันสองหน้าจออนุมัติข้อมูลเก่าชนกัน ผู้ใช้ต้องโหลดใหม่เมื่อข้อมูลเปลี่ยน
- ส่งลงทะเบียนชื่อ/ขอบเขตเดิมซ้ำได้รายการเดิม; เปลี่ยนข้อมูลโดยใช้ code เดิมถูกปฏิเสธ
- ยังไม่มี UI เปลี่ยน code/โหมด/ขอบเขตของรายการเดิม เพื่อไม่เปลี่ยนสิ่งที่อนุญาตไว้โดยเงียบ
- ตาราง private เปิด RLS และไม่ให้ client เขียนโดยตรง public functions เป็น invoker; ตัวที่ต้องยกระดับอยู่ private และตรวจ Owner
- รายงาน readiness และรับเหตุการณ์ให้ service_role เท่านั้น ห้ามนำ service key เข้า Flutter
- readiness ระบุ adapter version, scopes, credentials-ready, test evidence และวันหมดอายุสูงสุด30วัน ต้องออกจากกระบวนการตรวจจริงฝั่งเซิร์ฟเวอร์
- เมื่อ adapter/config report เปลี่ยน จะปิด enabled และต้องให้ Owner เปิดอีกครั้ง แม้ผลตรวจใหม่ผ่าน
- ประวัตินี้เป็น timeline ของ configuration พาร์ตเนอร์ ไม่ใช่ ledger หรือประวัติธุรกรรมเงิน

## จุดเชื่อมฝั่งเซิร์ฟเวอร์
server/partner_gateway.mjs เป็นโมดูล Node ที่เตรียมไว้ ยังไม่ได้ deploy เป็น endpoint
registry ของ adapters เริ่มว่าง ไม่มี fake adapter เปิดใช้จริง
ตัวเชื่อมแต่ละเจ้าต้อง implement verifyAndNormalize ให้ตรวจลายเซ็นจาก raw bytes, freshness/replay, merchant identity, schema, currency/amount และ event type ตาม API ของเจ้านั้น
binding ต้องค้นจาก config ฝั่งเซิร์ฟเวอร์ ห้ามเชื่อ partner_id/environment จาก JSON ผู้ส่ง
หลังตรวจแล้วจึงเรียก public.partner_receive_r12b ด้วยสิทธิ์เซิร์ฟเวอร์
ฐานข้อมูลตรวจซ้ำว่า Owner อนุญาต เปิดใช้งาน ผลตรวจไม่หมดอายุ โหมดและบริการตรงกัน
event_id เดิม+hashเดิมได้ receipt เดิม; hash ต่างกันปฏิเสธเพื่อตรวจสอบ
receipt บันทึกเฉพาะรหัส/hash ไม่เก็บข้อมูลการเงินดิบ และไม่เพิ่มยอด/settleเงิน
การปิดหยุดรับรายการใหม่หลังคำสั่งปิดสำเร็จ ไม่ย้อนยกเลิกเหตุการณ์ที่รับไว้แล้วหรือเงินที่ส่งไปแล้ว
ยังต้องต่อการประมวลผล durable inbox/outbox, retries, ledger/reconciliation, payment/refund/payout และข้อผิดพลาดของบริการจริงก่อนใช้เงินจริง
รายงาน readiness ปัจจุบันเป็นสัญญาการเชื่อมต่อฝั่ง server ไม่ใช่เครื่องสแกน API key หรือตรวจใบอนุญาตอัตโนมัติ

## ผลตรวจ
- SQL rollback ทดสอบแยกกลุ่มผ่าน: Owner create/approve/report/enable/receive; ordinary-member denial; client report/direct-write denial; stale session; duplicate create; stale revision; unready block; event dedupe/conflicting hash; environment/scope; disable; audit; expired readiness; new report requires enable again
- คำสั่ง regression รวมบางครั้งติดขัดที่เครื่องมือ จึงแยกรันทดสอบกลุ่มสำคัญ ไม่อ้างว่าคำสั่งรวมรันผ่าน
- Node tests4ผ่าน: unknown adapter, verification rejection, server binding/hash, invalid event/body limit
- Dart grammar และ ARB key parity ผ่าน; ไม่แทนผล Flutter
- ข้อมูล SQL ทดสอบถูก rollback ไม่มีเงินเคลื่อนไหวและไม่มีพาร์ตเนอร์จริงถูกเพิ่ม

## งานก่อนพาร์ตเนอร์จริงรายแรก
เลือกบริการ/ประเทศและตกลง API contract; deploy ตัวเชื่อมเฉพาะเจ้า; เก็บ/หมุน/ถอน secrets ผ่านระบบเซิร์ฟเวอร์; ตรวจ signature และบัญชีผู้รับให้ตรง; ทำ health checks/alerts และ replay control; ทดสอบ sandbox; เชื่อม ledger และคำสั่งซื้อ; ทดสอบก่อน Owner เปิด live
ดังนั้นหน้าจอ Owner พร้อมจัดการทะเบียนและอนุญาต แต่ยังไม่ใช่เพียงกดรับแล้วต่อ API ของทุกเจ้าได้ทันที

## Security advisor
ตรวจหลังเปลี่ยนแล้ว ยังคงมีข้อสังเกตเดิมเรื่อง public extensions, legacy SECURITY DEFINER และ leaked password protection; ตาราง private ชุดนี้ RLS/no policy เป็นการปิด client โดยตั้งใจ ไม่ถือว่าระบบทั้งหมดผ่าน audit
https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable
https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public
https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
