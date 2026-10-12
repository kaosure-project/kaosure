# Kao ID — ชุด 1B: Security localization และ audit

## สิ่งที่ส่ง
- โค้ดโปรเจกต์ 7 ไฟล์: 5 Dart ของ Security และ app_en.arb / app_th.arb
- ชุดทดสอบ 1 ไฟล์: test/localization/security_localization_1b_test.dart
- บันทึกงานต่อเนื่อง: docs/kao_id_ui_localization_progress.md
- เพิ่ม 7 คีย์ต่อภาษา ใช้ security/password เดิม รวมข้อความบนหน้าจอ 9 จุด
- เก็บทุกคีย์และค่าจากชุด 1A ไว้ครบ
- ไม่รวม generated Dart, .env, pubspec, router, Auth หรือไฟล์ส่วนอื่น

## เงื่อนไขก่อนใช้
ติดตั้งชุด 1A แล้ว และไม่ได้แก้ไฟล์ภาษา / Security 5 ไฟล์เพิ่มเติมจากฐานที่ส่งมา
หากมีการแก้เพิ่มเติม ให้หยุดและส่งไฟล์ปัจจุบันมาเพื่อรวมการแก้ก่อน
ZIP ต้นฉบับไม่ได้รวม test เดิมไว้ หากมีไฟล์ทดสอบชื่อเดียวกันอยู่แล้ว อย่าทับโดยไม่ตรวจ

## ติดตั้ง
ดาวน์โหลด kaosure_localization_1B.zip และวางใน D:\Developer\projects\kaosure_sync
ใช้ PowerShell ในโฟลเดอร์นั้น รันสำรองก่อน:

```powershell
$backupItems = @('lib')
if (Test-Path .\test) { $backupItems += 'test' }
if (Test-Path .\docs) { $backupItems += 'docs' }
$backupName = 'kaosure_before_1B_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path $backupItems -DestinationPath $backupName
```

หากสำรองสำเร็จจึงแตกชุดแก้ (ไม่ลบไฟล์อื่น):

```powershell
Expand-Archive -LiteralPath .\kaosure_localization_1B.zip -DestinationPath . -Force
```

รันทีละคำสั่ง หยุดหากคำสั่งใดล้มเหลว:

```powershell
flutter gen-l10n
flutter analyze
flutter test test/localization/security_localization_1b_test.dart
```

เมื่อผ่าน เปิดแอปด้วย launch configuration `kaosure` เดิม หรือ:

```powershell
flutter run -d chrome --web-port=7357 --dart-define-from-file=.env
```

## ตรวจหน้าจอจริง
- สลับไทย/English: หัวข้อ Security และชื่อ/คำอธิบาย 4 เมนูเปลี่ยนครบ
- เมนู Settings จากชุด 1A ต้องยังแปลได้เหมือนเดิม
- ลดหน้าต่างให้แคบ ตรวจข้อความไทยยาวและข้อความล้น
- ตรวจไอคอน 4 เมนูและลูกศรยังแสดงปกติ
- กด Password ต้องไปหน้าเปลี่ยนรหัสผ่านเดิม (ไม่ต้องเปลี่ยนรหัสผ่านจริงเพื่อทดสอบชุดภาษา)
- Devices, Login History, Two-Factor ยังเป็น TODO ตามเดิม ไม่ได้อ้างว่าใช้งานได้แล้ว
- รีเฟรชด้วยพอร์ตเดิมและตรวจการจำภาษา

## ผลตรวจในฝั่งจัดทำ
ตรวจ JSON/คีย์ซ้ำ/คีย์สองภาษาตรงกัน/คีย์เดิมไม่หาย และตรวจ diff ขอบเขตการแก้
ตรวจ source ว่าไม่เปลี่ยน onTap, icon, layout, Auth หรือ routing
มีชุดทดสอบ 7 กรณี: ข้อความ+ไอคอนสองภาษา, หน้าจอ 320px ที่ขยายข้อความ 2 เท่าสองภาษา,
การนำทาง Password สองภาษา และการสลับ locale บน widget เดิม
ชุดทดสอบใช้ theme มาตรฐานและ route จำลอง ไม่ทดแทนการตรวจ AppTheme, font asset หรือ Auth จริง
ยังไม่ได้รัน Flutter analyzer/widget tests/UI ที่นี่ เนื่องจากคำสั่ง Flutter ก่อนหน้าถูกบล็อก
จึงห้ามถือว่าชุดทดสอบผ่านจนได้รับผลจากเครื่องผู้ใช้

## ย้อนกลับ
ใช้ ZIP สำรองก่อน 1B คืนเฉพาะ 7 ไฟล์โปรเจกต์ที่ชุดนี้แทนที่ แล้วรัน flutter gen-l10n ใหม่
หากเพิ่มไฟล์ทดสอบและบันทึกงานเป็นครั้งแรก ให้ย้ายสองไฟล์นั้นออกจากโปรเจกต์เมื่อย้อนกลับ
หากมีไฟล์เดิมชื่อเดียวกัน ให้คืนจากสำรองแทน อย่าใช้สำรองก่อน 1A เพราะจะเสียงาน 1A
