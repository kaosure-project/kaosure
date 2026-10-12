# Kao ID Localization — Batch 1A: Settings

## ขอบเขต
แก้ไฟล์โปรเจกต์ 5 ไฟล์: app_en.arb, app_th.arb และ notifications_tile.dart,
privacy_tile.dart, about_tile.dart ใน dashboard/presentation/widgets/settings
เพิ่ม 6 คีย์ต่อภาษา และเชื่อมข้อความ 6 จุดเข้ากับ AppLocalizations
ไม่แก้ icon, layout, onTap, Auth, router, dependencies, database หรือระบบเลือกภาษา
เมนูที่เป็น TODO ยังคงเป็น TODO ตามต้นฉบับ ไม่ได้เพิ่มการทำงานใหม่

## ต้นฉบับ
ใช้ kaosure_localization_review.zip ที่ผู้ใช้ส่งมาเป็นฐาน ไม่ใช้การแก้ค้างจากรอบใหญ่
ถ้าแก้ 5 ไฟล์นี้เพิ่มเติมหลังส่ง ZIP ให้หยุดก่อนแทนที่ และส่งฉบับปัจจุบันมาเพื่อรวมการแก้

## ติดตั้งทีละขั้น
1. เก็บ kaosure_localization_1A.zip ไว้ใน D:\Developer\projects\kaosure_sync
2. สำรองโฟลเดอร์ lib ปัจจุบันก่อน (ชื่อสำรองไม่ซ้ำ):

```powershell
$backupName = 'kaosure_before_1A_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path lib -DestinationPath $backupName
```

3. หลังสำรองสำเร็จ แตกชุดนี้ในโฟลเดอร์โปรเจกต์:

```powershell
Expand-Archive -LiteralPath .\kaosure_localization_1A.zip -DestinationPath . -Force
```

ZIP มีเฉพาะไฟล์โปรเจกต์ที่เปลี่ยน 5 ไฟล์และเอกสารนี้ จึงไม่ได้แทนที่ lib ทั้งโฟลเดอร์
ไม่รวม generated Dart: ให้ Flutter สร้างจาก ARB บนเครื่องของคุณ

4. รันทีละคำสั่ง หากคำสั่งแรกผิดพลาด ให้หยุดและส่งข้อความกลับ:

```powershell
flutter gen-l10n
flutter analyze
```

5. เปิดแอปด้วย VS Code configuration `kaosure` เดิม หรือคำสั่ง:

```powershell
flutter run -d chrome --web-port=7357 --dart-define-from-file=.env
```

## เกณฑ์ผ่าน
- gen-l10n สำเร็จ และ analyze ไม่มีปัญหา
- เลือกไทย: การแจ้งเตือน / ความเป็นส่วนตัว / เกี่ยวกับ Kao ID พร้อมคำอธิบายเป็นไทย
- เลือก English: Notifications / Privacy / About Kao ID พร้อมคำอธิบายเป็นอังกฤษ
- ไอคอนและการจัดวางคงเดิม ตรวจที่หน้าจอแคบด้วย
- รีเฟรชบน URL และพอร์ตเดิมแล้วยังจำภาษาที่เลือก
- ภาษาใน Security และ Governance ยังไม่ได้ทำในชุดนี้

## ผลตรวจและข้อจำกัด
ตรวจ JSON, คีย์สองภาษาตรงกัน, คีย์เดิมไม่ถูกลบหรือเปลี่ยน และชื่อคีย์ที่ widget เรียกแล้ว
ตรวจ diff ว่าเปลี่ยนเฉพาะ import, การอ่าน AppLocalizations และข้อความ title/subtitle
ยังไม่ได้รัน Flutter gen-l10n/analyze หรือ UI ในสภาพแวดล้อมนี้:
การรัน Flutter ก่อนหน้าถูกระบบความปลอดภัยบล็อก จึงต้องตรวจบนเครื่องผู้ใช้ก่อนปิดชุด

## บันทึกส่งต่องาน
- จัดทำแล้ว: ชุด 1A จำนวน 5 ไฟล์ เพิ่ม 6 คีย์ไทย–อังกฤษ
- รอ: ผล gen-l10n, analyze และการทดสอบหน้าจอจากผู้ใช้
- ขั้นถัดไป: ชุด 1B Security (5 Dart + 2 ARB)
- ใช้ ARB จากชุด 1A เป็นฐานของชุดถัดไป ห้ามย้อนทับด้วย ARB ก่อนชุด 1A
- คืนค่าได้จาก ZIP สำรอง โดยแทนเฉพาะ 5 ไฟล์นี้ แล้วรัน gen-l10n ใหม่
