# ชุด 1C — บริการ แถบบน และเมนูลัด

ใช้ต่อจากชุด 1A และ 1B ที่ติดตั้งแล้วเท่านั้น หากแก้ไฟล์เป้าหมายเพิ่มเติม ให้รวมการแก้ก่อนทับ

## เปลี่ยนอะไร
- เพิ่มคำแปลไทย/อังกฤษ 14 คีย์ เก็บทุกคีย์และค่าของชุด 1B
- บริการ 4 รายการแสดง “ยังไม่เปิดให้บริการ” ปิดการกดและเอาลูกศรออก เพราะโค้ดเดิมเป็น TODO
- แถบบนใช้ชื่อ Kao ID จากคำแปล และซ่อนกระดิ่ง/เฟืองเมื่อไม่มี callback; หากมี callback ยังใช้งานได้ตามเดิม
- เอา KaoPay ออกจากกลุ่มเมนูลัดเพื่อลดความซ้ำ แต่ยังอยู่ในบริการ ไม่ลบไฟล์ฟังก์ชันเดิม
- เมนูลัดเหลือ Profile, Verify identity, Kao Code โดย Kao Code ระบุสถานะและปิดการกด
- การ์ดปรับจำนวนคอลัมน์ตามพื้นที่และขนาดตัวอักษร ใช้ความสูงตามเนื้อหา ไม่ตัดชื่อเหลือสองบรรทัด
- รวม VerifyAction ที่ซ้ำใน quick_actions.dart ให้ export ตัวจริงจาก verify_action.dart
- คง callback โปรไฟล์/ยืนยันตัวตนและการโหลดข้อมูลหลังกลับจากโปรไฟล์
- คงปุ่มย้อนกลับเดิมจนกว่าจะตรวจประวัติการนำทางจริง ไม่แก้ Auth/router/backend

## ติดตั้ง
วาง ZIP ใน D:\Developer\projects\kaosure_sync แล้วสำรองก่อน

```powershell
$backupItems = @('lib')
if (Test-Path .\test) { $backupItems += 'test' }
if (Test-Path .\docs) { $backupItems += 'docs' }
$backupName = 'kaosure_before_1C_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path $backupItems -DestinationPath $backupName
```

เมื่อสำรองสำเร็จ รันทีละคำสั่งและหยุดเมื่อมี error

```powershell
Expand-Archive -LiteralPath .\kaosure_localization_1C.zip -DestinationPath . -Force
flutter gen-l10n
flutter analyze
flutter test test/localization
```

ปิด Flutter ตัวเก่าด้วย q หรือ Stop Debugging แล้วเปิดใหม่

```powershell
flutter run -d chrome --web-port=7357 --dart-define-from-file=.env
```

## ตรวจจริง
- ถ่าย Dashboard บนสุดทั้งไทยและอังกฤษ แล้วตรวจความกว้างมือถือ/เดสก์ท็อปและตัวอักษรใหญ่
- Services/เมนูลัด/แถบบนแปลตรงภาษา; Security/Settings ของชุดก่อนยังถูกต้อง
- ไม่มี KaoPay ซ้ำในเมนูลัด กระดิ่ง/เฟืองที่ไม่มี callback ถูกซ่อน
- บริการและ Kao Code กดแล้วไม่เปิดหน้าหรือส่งคำขอใด ๆ และมีข้อความแจ้งสถานะ
- Profile และ Verify identity ยังเปิดหน้าเดิมได้; การตรวจนี้ยังไม่ยืนยันกระบวนการ KYC ทั้งระบบ
- รีเฟรชตรวจจำภาษาและตรวจปุ่ม Back โดยไม่สมมติว่าปลอดภัยจาก widget test

## การตรวจที่ทำแล้วและข้อจำกัด
ตรวจ JSON, คีย์ภาษา, การคงคำแปลเดิม, imports และขอบเขต diff ด้วยสคริปต์
มี widget tests ใหม่ 10 กรณีสำหรับบริการ/แถบบน/ปุ่มปิดใช้งาน/จอแคบ/ข้อความใหญ่
ยังไม่ได้รัน Flutter analyze หรือ tests ฝั่งจัดทำ: การเรียก Flutter ก่อนหน้านี้ถูกระบบอนุมัติอัตโนมัติปฏิเสธ
ต้องใช้ผลจากเครื่องผู้ใช้ก่อนสรุปว่าผ่าน ไม่รับรอง production UI จาก source อย่างเดียว
ชุดนี้ไม่แปล Profile card, สถานะบัญชี, หน้าปลายทาง หรือ Dashboard error/empty state ทั้งหมด

## ย้อนกลับ
คืนไฟล์เดิมตามรายการใน manifest_1C.txt จาก ZIP ก่อน 1C
ไฟล์ใหม่ที่ไม่มีในสำรองให้ย้ายออก: quick_actions_layout.dart, dashboard_localization_1c_test.dart,
docs/kao_id_ui_localization_1c.md และไฟล์เอกสารของชุดนี้ แล้วรัน flutter gen-l10n
อย่าคืนสำรองก่อน 1A/1B เพราะจะเสียงานชุดก่อนหน้า
