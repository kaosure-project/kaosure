# R12A — กระเป๋าเงินกลาง: อ่านข้อมูลจริง

ต่อจาก R11A fix ที่ผู้ใช้รายงาน analyze ผ่าน และ 299 tests ผ่าน
เข้า หน้าหลัก → กระเป๋าเงินกลาง (ท้ายหน้า)

## ขอบเขตที่ทำ
- อ่าน public.wallets ของผู้ใช้ที่ลงชื่อเข้าใช้และเซสชันยังทำงานเท่านั้น
- แยกไม่มี wallet ออกจาก wallet ที่ balance เป็นศูนย์ ไม่สร้าง wallet อัตโนมัติ
- แสดง balance / hold_balance เป็นค่าที่บันทึกโดยตรง ไม่คำนวณยอดพร้อมใช้จากความหมายที่ยังไม่ตกลง
- ส่งเลขทศนิยมเป็น string ไม่แปลงผ่าน double หรือปัดจำนวนเงิน
- ประวัติ public.wallet_transactions ครั้งละ 30 รายการ เรียงวันเวลาและ UUID พร้อม cursor
- ไม่สร้างสถานะธุรกรรมใหม่ ใช้รหัสจริงจากฐานข้อมูล จึงติดป้ายว่าเป็นรหัสสถานะ/ประเภท
- โหลดผิดพลาดมี retry, ซ่อนข้อมูลเมื่อเปลี่ยนบัญชี, ไม่ใช้ผลตอบกลับเก่าข้ามบัญชี
- UI ใหม่ครบ 7 ภาษา + zh fallback
- ลบนโยบายเขียน wallet/transaction โดย client ที่ไม่ควรใช้ โดยสิทธิ์ตารางเดิมก็ไม่อนุญาตเขียนอยู่แล้ว

## ติดตั้ง
สำรอง lib,test ก่อน แตก ZIP ทับโปรเจกต์เดิมที่มี R11A fix แล้ว
```
flutter gen-l10n
flutter analyze
flutter test test/localization/wallet_r12a_test.dart
flutter test test/localization
```
ไม่จำเป็นต้อง upgrade Flutter เพราะมีข้อความแจ้งเวอร์ชันใหม่

## ฐานข้อมูลและผลตรวจ
wallet_read_r12a ติดตั้งแล้วใน Supabase ที่เชื่อมกับโปรเจกต์นี้ ไม่ต้องรัน SQL ซ้ำ
SQL regression ผ่าน: missing wallet, exact decimal strings, foreign-user rejection, 30+1 pagination, update/insert denial, revoked-session rejection, anonymous grant rejection
ใช้ fixture ชั่วคราวใน transaction และ rollback; หลังทดสอบ wallet/transaction ยังไม่มีรายการจริง
เพิ่มดัชนี wallet_id, created_at, id สำหรับประวัติ
Flutter SDK ไม่มีในสภาพแวดล้อมจัดชุด จึงยังไม่ได้รัน analyze หรือ Flutter tests ที่นี่
ไฟล์ทดสอบ Dart เป็น fixture ไม่ใช่หลักฐานว่าการรับเงิน/ซื้อจริงสำเร็จ

## ยังไม่เปิดใช้
ไม่มีปุ่มเติมเงิน ซื้อสินค้า ถอนเงิน หรือสร้างเงินทดสอบให้บัญชีจริง
ยังต้องตกลงแหล่งเงิน: เติมเงินเอง / เงินคืน / รายได้จากการขาย และเลือกบริการรับชำระเงิน
ก่อนเปิดซื้อ ต้องต่อ ledger ที่ตรวจยอดได้, กฎยอดพร้อมใช้และเงินพัก, คำสั่งซื้อ, transaction lock, idempotency, ยืนยันผลจากผู้ให้บริการ, คืนเงิน/กระทบยอด และทดสอบส่งซ้ำ/พร้อมกัน
ไม่ถือว่า R12A เป็นกระเป๋าเงินพร้อมใช้เงินจริงหรือระบบองค์กรเสร็จแล้ว
Kao ID งานค้างเดิม: E2E, SMS, event email, retention, security/load และองค์กรยังคงค้างตามเดิม

## Security advisor ที่ยังค้างนอกชุดนี้
ตรวจหลัง migration แล้วยังมีข้อสังเกตเดิมเรื่อง public extensions, exposed SECURITY DEFINER functions ของระบบเดิม, leaked-password protection และ private tables ที่เปิด RLS ไม่มี policy (deny by default) ไม่ถือว่าทั้งระบบผ่าน security audit
อ้างอิงแนวทางแก้:
- https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public
- https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable
- https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable
- https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
