# Kao ID redesign R1 — เปลี่ยนโครงสร้างหน้าใช้งานจริง

ใช้ต่อจากชุด 1E ที่ผ่าน 30 tests; ไม่ใช่การเปิดใช้ระบบใหม่ทั้ง 40 หน้าของต้นแบบ
ย้ายเมนูหลัก/หน้าหลักและการนำทางเข้าสู่ Flutter จริง โดยใช้ provider และการทำงานเดิม

## สิ่งที่เปลี่ยน
- หน้าหลักเหลือข้อมูลโปรไฟล์และทางเข้าตรวจสถานะยืนยันตัวตน
- เมนูหลัก 4 ส่วน: Home / My account / Security / Settings
- จอกว้างใช้เมนูด้านข้าง จอแคบหรือข้อความใหญ่ใช้เมนูล่างที่ขึ้นหลายแถวได้
- ไม่มีบริการอนาคตและปุ่ม TODO ในหน้าหลัก/ความปลอดภัย/ตั้งค่าใหม่
- ความปลอดภัยมีปุ่ม Password ที่เชื่อมหน้าเดิม การตั้งค่ามีการเลือกภาษาที่บันทึกได้จริง
- ทางเข้าผู้ดูแลยังอยู่ในการตั้งค่า และยังใช้ governanceAccessProvider ตรวจสิทธิ์เหมือนเดิม
- Account ใช้เนื้อหาเดิมใน shell ไม่มี AppBar ซ้อนกัน; standalone AccountPage ยังรองรับ
- เพิ่ม /profile /security /settings ผ่าน AuthGuard เดิม
- /profile/edit ใช้ named route พร้อมข้อมูลโปรไฟล์; หากเปิดตรง/refresh ไม่มี arguments จะกลับเนื้อหาบัญชีให้เลือกแก้ไขใหม่
- แท็บหลักแทนที่ route ปัจจุบัน เพื่อลดการสะสมแท็บใน Back stack
- เปอร์เซ็นต์ความครบถ้วนถูกเอาออกจากหน้าหลัก ไม่ใช้เป็นคะแนนยืนยันตัวตนหรือสิทธิ์
- คำแปลเดิมเก็บครบ เพิ่ม 7 คีย์

## ขอบเขตที่ยังไม่เปลี่ยน
ไม่ได้สร้าง MFA, devices, sessions, เปลี่ยนอีเมล, ปิดบัญชี, การสมัครบริการ หรือ KYC ใหม่
Login/Register/Reset password/KYC และหน้าแก้ไขโปรไฟล์ยังใช้ UI/flow เดิมที่มีอยู่
40 หน้าต้นแบบเป็นเป้าหมายการออกแบบ ไม่ใช่ผลส่งมอบระบบทำงานจริงทั้งหมดใน ZIP นี้
ไม่เปลี่ยน auth provider, AuthGuard, Supabase, database, สิทธิ์, dependency หรือ .env
ไม่ลบไฟล์ฟีเจอร์อนาคตหรือ router เดิม

## ก่อนติดตั้ง
ZIP นี้แทน lib/app/router.dart ด้วยฐานจากไฟล์ที่ส่งมาและเพิ่มเฉพาะ route ใหม่
หากมีการแก้ router หรือไฟล์เป้าหมายนอกชุด 1A–1E ให้รวมการแก้ก่อนทับ
สำรองไฟล์ตามคำสั่งด้านล่างเพื่อย้อนกลับได้

```powershell
$backupItems = @('lib')
if (Test-Path .\test) { $backupItems += 'test' }
if (Test-Path .\docs) { $backupItems += 'docs' }
$backupName = 'kaosure_before_redesign_R1_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path $backupItems -DestinationPath $backupName
```

เมื่อสำรองสำเร็จ รันทีละคำสั่งและหยุดถ้ามี error:

```powershell
Expand-Archive -LiteralPath .\kaosure_redesign_R1.zip -DestinationPath . -Force
flutter gen-l10n
flutter analyze
flutter test test/localization
```

เพิ่ม 7 tests; รวมควรเป็น 37 หากชุดเดิมยังอยู่ครบและไม่มี tests อื่น
หยุด Flutter ตัวเดิมก่อนเปิดใหม่:

```powershell
flutter run -d chrome --web-port=7357 --dart-define-from-file=.env
```

## ตรวจบนแอปจริง
1. เข้า Dashboard ตรวจหน้าหลักใหม่และไม่มี Marketplace/Auction/KaoPay/Kao Code
2. สลับเมนู 4 ส่วน ดู URL /dashboard /profile /security /settings
3. เข้า Account → Edit Profile ตรวจชื่อ/รูปเดิม บันทึกและกลับหน้าบัญชี
4. เปลี่ยนภาษาใน Settings แล้วสลับทุกเมนู ตรวจภาษาและข้อมูลผู้ใช้ไม่หาย
5. Security → Password เปิดหน้าเดิม; ทดสอบกลับโดยไม่ต้องเปลี่ยนรหัสจริง
6. Home → ตรวจสถานะยืนยันตัวตน เปิด KYC เดิมแล้วกลับ หน้าหลักโหลดข้อมูลใหม่
7. Refresh บนแต่ละ URL; /profile/edit เมื่อไม่มี arguments ต้องแสดงบัญชี ไม่แสดงข้อมูลตัวอย่าง
8. เปิด URL ใหม่โดยยังไม่ลงชื่อเข้าใช้ ต้องผ่าน AuthGuard เดิมและแสดงหน้า Login
9. ตรวจ Back ของ browser, หน้าจอ 320px, ตัวอักษรใหญ่ และรูปที่โหลดไม่ได้
10. บัญชีปกติไม่เห็นเมนูผู้ดูแล; บัญชีมีสิทธิ์ยังเข้า Governance ตามเดิม

## ผลตรวจ
ตรวจคีย์/placeholder เดิม/relative imports/ขอบเขต diff router และไฟล์แพ็กด้วยสคริปต์
tests เพิ่มตรวจเมนู responsive ทั้งสองภาษา, callbacks หน้าหลัก, route metadata และการครอบ AuthGuard
route test ตรวจการประกอบ widget เท่านั้น ไม่ยืนยันการรักษาความปลอดภัย backend หรือการคืน session จริง
ยังไม่ได้รัน Flutter analyzer/tests ฝั่งจัดทำ เพราะการเรียก Flutter ก่อนหน้าถูกระบบอนุมัติอัตโนมัติปฏิเสธ
ต้องยืนยันผลบนเครื่องผู้ใช้; ไม่อ้างว่าชุดใหม่ผ่านจาก tests ชุดเก่า

## ย้อนกลับ
คืนไฟล์ที่เคยมีตาม manifest จากสำรองก่อน R1 และย้ายไฟล์ใหม่ที่ไม่อยู่ในสำรองออก
ไฟล์ใหม่หลัก: kao_id_scaffold.dart, dashboard_home_content.dart, kao_id_redesign_r1_test.dart
แล้ว flutter gen-l10n ใหม่ อย่าใช้ ZIP ก่อน 1A เพราะจะเสียคำแปลชุดหลัง
