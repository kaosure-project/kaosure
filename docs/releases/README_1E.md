# 1E — Dashboard profile localization และลด UI ซ้ำ

ใช้ต่อจาก 1D ที่แก้ tests แล้วและผ่าน 24 tests เท่านั้น
หากแก้ไฟล์เป้าหมายเพิ่มเติมนอกชุดก่อน ต้องรวมการแก้ก่อนทับ ZIP

## สิ่งที่เปลี่ยน
- แปลชื่อสำรอง/username ที่ยังไม่ได้ตั้ง/ระดับบัญชี/เปอร์เซ็นต์ความครบถ้วนบน Dashboard
- แปล Dashboard empty/error state โดยใช้ข้อความทั่วไปแทน error ดิบ
- เพิ่ม mounted guard ก่อนเรียกโหลด Dashboard หลัง frame
- หน้า Account เหลือการ์ดโปรไฟล์พร้อมสถานะโหลด/ผิดพลาด/รีเฟรช
- เอาเมนูซ้ำ Identity/Devices/Sessions/Language/Notifications ออกจากหน้า Account; เมนูหลักยังอยู่ Dashboard
- ซ่อน Bank accounts และ Companies/organizations ที่เดิมเป็นปุ่มว่างจากหน้า Account จนพร้อมใช้งาน
- ลบเฉพาะ private widget ของเมนูที่หน้า Account ไม่ใช้อีกแล้ว ไม่ลบระบบธนาคาร/องค์กรหรือ routes
- ปุ่ม Details เปลี่ยนเป็น Edit profile ให้ตรงกับหน้าที่เปิด
- เอาคำอธิบายซ้ำพร้อมไอคอนสีแดงออกจากหน้า Edit Profile โดยเก็บ helper ของช่องชื่อไว้
- Avatar ไม่จองความสูง 180 คงที่ ปรับตามเนื้อหา ชื่อไฟล์/ขนาดไฟล์ยังแสดงเมื่อเลือกรูป

## ตรวจแล้ว / ยังไม่ยืนยัน
ตรวจ static references/คำแปลเดิม/metadata placeholder/diff และ ZIP แล้ว
เพิ่ม tests 6 กรณีสำหรับระดับบัญชี/ชื่อสำรองและชื่อผู้ใช้/เปอร์เซ็นต์ทั้งสองภาษา
ยังไม่ได้รัน Flutter analyzer/tests ที่นี่ เพราะการเรียก Flutter ก่อนหน้านี้ถูกระบบอนุมัติอัตโนมัติปฏิเสธ
ต้องรันบนเครื่องผู้ใช้และตรวจ UI จริงก่อนถือว่าผ่าน
ไม่แก้ข้อมูลผู้ใช้หรือหลักการคำนวณความครบถ้วน
ความครบถ้วนเป็นเกณฑ์ UI เดิม ไม่ใช่สิทธิ์เข้าใช้บริการหรือสถานะ KYC ที่เชื่อถือได้ฝั่ง backend

## ติดตั้ง
วาง ZIP ใน D:\Developer\projects\kaosure_sync แล้วสำรอง:

```powershell
$backupItems = @('lib')
if (Test-Path .\test) { $backupItems += 'test' }
if (Test-Path .\docs) { $backupItems += 'docs' }
$backupName = 'kaosure_before_1E_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path $backupItems -DestinationPath $backupName
```

รันทีละคำสั่ง หยุดหากมี error:

```powershell
Expand-Archive -LiteralPath .\kaosure_localization_1E.zip -DestinationPath . -Force
flutter gen-l10n
flutter analyze
flutter test test/localization
```

ควรมีรวม 30 กรณีเมื่อไม่มี test เพิ่มจาก 24 เดิม
หยุดตัวรันเดิมก่อนเปิด เพื่อไม่ชนพอร์ต:

```powershell
flutter run -d chrome --web-port=7357 --dart-define-from-file=.env
```

## ตรวจ UI
- Dashboard บนสุดสองภาษา: ชื่อผู้ใช้ไม่ถูกแปล ระดับและเปอร์เซ็นต์ตรงภาษา
- Account ไม่มีเมนูซ้ำ/ปุ่มที่ยังไม่เปิดให้บริการ การ์ดโปรไฟล์ยังโหลดและรีเฟรชได้
- ปุ่ม Edit profile เปิดหน้าเดิม
- หน้า Edit Profile มีคำอธิบายช่องชื่อชุดเดียว ช่องว่างใต้รูปลดลง
- เลือกรูปที่ชื่อยาว ตรวจชื่อไฟล์ไม่ล้นหรือชนข้อความและปุ่ม
- ตรวจจอแคบ/ตัวอักษรใหญ่และย้อนกลับ

## ย้อนกลับ
คืนไฟล์ lib ตาม manifest_1E.txt จากสำรองก่อน 1E แล้ว flutter gen-l10n
เอา test ใหม่และเอกสารชุดนี้ออกเฉพาะหากไม่เคยมีมาก่อน หากมีให้คืนสำรองเดิม
