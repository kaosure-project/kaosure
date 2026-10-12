# Kao ID UI R4 — จัดหมวดหน้าหลัก

ใช้กับโครงการที่ติดตั้ง R2/R3 แล้วเท่านั้น
ชุดนี้มี Dart 1 ไฟล์ + ARB 2 ไฟล์ + เอกสารตรวจงาน ไม่ทับ test ที่แก้ super.ref แล้ว
คงหน้าลูก/การทำงานเดิม เปลี่ยนหน้า home เป็นหมวดที่อ่านง่าย และไม่แสดงบริการที่ยังไม่มี

## ติดตั้ง (PowerShell ที่ root โครงการ)
```powershell
$backupName = 'kaoid_before_UI_R4_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path lib -DestinationPath $backupName
Expand-Archive -LiteralPath .\kaoid_ui_R4.zip -DestinationPath . -Force
flutter gen-l10n
flutter analyze
flutter test test/localization
```
หากมีการเพิ่มคำแปลเองหลัง R3 ให้ merge 6 keys ใหม่ก่อนแทน ARB

## ตรวจด้วยมือ
เปิดหน้า /dashboard สลับไทย/อังกฤษ ตรวจชื่อ/รูปเดิมและทางเข้า 4 หมวด
ตรวจบนหน้าจอแคบและขยายตัวอักษร; ปุ่มข้อมูลส่วนตัว/ยืนยันใช้ callback เดิม
Security/Settings ใช้ named routes เดิมพร้อม AuthGuard; กดย้อนกลับต้องกลับหน้าหลัก
KYC ยังอาจแสดง error เดิม เป็นงานลำดับถัดไปในทะเบียน ไม่ใช่งานที่ผ่านแล้ว

ยังไม่ได้รัน Flutter analyzer/tests ในสภาพแวดล้อมผู้จัดทำนี้
ตรวจ static เรื่อง imports, keys ไทย/อังกฤษ, preserved ARB keys และ ZIP paths แล้ว
