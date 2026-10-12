# 1D — Account/Profile localization

ต่อจาก 1A/1B/1C เท่านั้น ไม่ใช่ชุดที่แปลทั้ง Kao ID เสร็จแล้ว
ชุดนี้แก้ 4 หน้าใน account/presentation/pages และ widget ข้อความที่เกี่ยวข้อง
ใช้ไฟล์ต้นฉบับที่ส่งมาและคำแปลต่อจาก 1C; หากมีการแก้ไฟล์เหล่านี้เพิ่ม ให้รวมการแก้ก่อนทับ

## สิ่งที่เปลี่ยน
- Account, Edit Profile, Complete Profile และหน้า Identity Verification placeholder ใช้ภาษาแอป
- แปลป้ายระดับบัญชี หัวข้อ คำอธิบาย คำใบ้ ข้อความตรวจฟอร์มและข้อความผลการบันทึก
- ใช้ ProfileState แทน dynamic ในหน้า Account
- เมนู Account ที่เดิม onTap ว่างแสดงสถานะยังไม่เปิดให้บริการและปิดการกด
- Edit Profile ตรวจ errorMessage หลังบันทึกก่อนแสดงสำเร็จและย้อนกลับ; เมื่อผิดพลาดคงฟอร์มให้แก้/ลองใหม่
- แสดงข้อผิดพลาดทั่วไปเป็นภาษาผู้ใช้ แทนการแสดง error ดิบ; ข้อมูล error เดิมยังอยู่ใน controller state
- เพิ่ม helperMaxLines ให้คำอธิบายช่องชื่อ
- คงชื่อผู้ใช้ ข้อมูลที่กรอก รหัส accountLevel และข้อมูลบันทึกเดิม ไม่แปลข้อมูลผู้ใช้

## ยังไม่เสร็จ
- ไม่ใช่คำรับรองว่าทุกหน้าแปลครบ: ดู docs/kao_id_localization_inventory.md
- Profile: กฎชื่อใน Complete Profile ยังยาวสูงสุด 100 แต่ Edit Profile ใช้ 3–30 ตามของเดิม ต้องตกลงกฎเดียวและตรวจ backend ก่อนเปลี่ยน
- Preferred Language ใน Complete Profile เป็นข้อมูลโปรไฟล์ ยังไม่ได้เชื่อมกับการตั้งค่าภาษาท้องถิ่น; ไม่ถือว่าบันทึกแล้ว UI เปลี่ยนเอง
- การบันทึกจริง/ความล้มเหลวจริง/อัปโหลดรูปต้องตรวจบนแอปที่เชื่อมบริการจริง
- รูปแบบ avatar และการตัดข้อความจอแคบยังต้องตรวจภาพจริง ไม่อ้างว่า UI ครบทุกอุปกรณ์
- หน้าปลายทาง Auth, KYC, Business, Identity, Phone verification และ Governance ยังอยู่ในคิว

## ติดตั้ง
วาง ZIP ในโฟลเดอร์โปรเจกต์ สำรองก่อน:

```powershell
$backupItems = @('lib')
if (Test-Path .\test) { $backupItems += 'test' }
if (Test-Path .\docs) { $backupItems += 'docs' }
$backupName = 'kaosure_before_1D_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path $backupItems -DestinationPath $backupName
```

เมื่อสำรองผ่าน รันทีละคำสั่ง:

```powershell
Expand-Archive -LiteralPath .\kaosure_localization_1D.zip -DestinationPath . -Force
flutter gen-l10n
flutter analyze
flutter test test/localization
```

หาก error ให้หยุดและส่ง log ไม่ข้ามไปชุดถัดไป
ปิดตัวรันเก่าก่อนเพื่อไม่ชนพอร์ต แล้วเปิดด้วย:

```powershell
flutter run -d chrome --web-port=7357 --dart-define-from-file=.env
```

## ผลตรวจและทดสอบ
ตรวจคีย์สองภาษาตรงกัน คีย์ชุด 1C ไม่หาย references และขอบเขตไฟล์ด้วยสคริปต์
เพิ่ม widget tests 7 กรณี: header สองภาษา, labels/ชื่อสั้นสองภาษา, ชื่อยาวสองภาษา,
เปลี่ยนภาษาโดยยังเก็บชื่อที่กรอกในฟอร์ม
ไม่ได้รัน Flutter analyzer/tests ฝั่งจัดทำ เนื่องจากการเรียก Flutter ก่อนหน้านี้ถูกระบบอนุมัติอัตโนมัติปฏิเสธ
tests ไม่ครอบคลุมการบันทึกสำเร็จ/ผิดพลาดจริงหรือทุกหน้าของ Account
ต้องตรวจผ่านเครื่องผู้ใช้ก่อนปิดชุดนี้

## ย้อนกลับ
คืนไฟล์ lib ตาม manifest_1D.txt จากสำรองก่อน 1D แล้ว flutter gen-l10n
ย้าย test/localization/profile_localization_1d_test.dart และเอกสารใหม่ของชุดนี้ออกหากไม่เคยมีมาก่อน
หากมีไฟล์เดิมชื่อเดียวกันให้คืนสำรองแทน
