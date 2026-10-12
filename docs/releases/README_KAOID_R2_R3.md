# Kao ID R2 + R3 — ชุดรวมแก้ Auth, navigation และ backend review

ใช้กับ ZIP ล่าสุด kaoid_completion_review_20260921_201617.zip ที่มี R1 อยู่แล้ว
ติดตั้งชุดนี้เพียงชุดเดียว ไม่ต้องติดตั้ง kaoid_completion_R2.zip แยก

## โค้ดที่แก้ให้ในชุดนี้

- ภาษาไทย/อังกฤษใน 7 หน้าหลักของ Auth รวม validation, snackbar และปุ่มแสดง/ซ่อนรหัสผ่าน
- เพิ่ม Settings → ออกจากระบบ พร้อมยืนยัน/ยกเลิก/ข้อผิดพลาด; ใช้ Auth เดิมและล้าง caches บัญชีที่เกี่ยวข้องหลังสำเร็จ
- เพิ่ม /kao-id สำหรับหน้าเข้า Kao ID และเปลี่ยน Bootstrap ให้ใช้ named routes
- CompleteProfile ที่บันทึกสำเร็จกลับ Dashboard ได้ ไม่บังคับ KYC
- เข้า KYC โดยลิงก์ตรงแล้วโหลด profile พร้อม KYC; เมื่อโหลดล้มเหลวแสดง Retry
- ห่อ AuthGuard ใน fallback ธุรกิจ 3 จุด
- ซ่อนปุ่มสมัครธุรกิจที่ปลายทางยังไม่เชื่อม submit
- ปุ่มหลักรองรับข้อความยาว และ Bootstrap ไม่หมุนค้างเมื่อ error
- เพิ่มข้อความ 73 key และ widget tests 32 กรณี

นี่เป็น patch source เฉพาะไฟล์ที่แก้ ไม่ใช่โปรเจกต์เต็ม และยังไม่ใช่การรับรองว่าทุกหน้า/KYC/ระบบหลังบ้านเสร็จสมบูรณ์ ภาษาหน้าปลายทางเอกสาร โทรศัพท์ ธุรกิจ และผู้ตรวจยังมีงานตาม inventory

## ผลตรวจระบบจริงที่ต้องอ่าน

อ่าน docs/backend_review_R3.md ก่อนนำ Kao ID เปิดใช้งานจริง:

1. มี trigger สร้าง profiles/verifications อยู่แล้ว ไม่ต้องสร้างซ้ำจาก client
2. สมาชิกมี UPDATE privilege ของ profiles.role และฟิลด์ระดับบัญชีของตัวเอง — ต้องปิดช่องนี้
3. approve_kyc_verification ตรวจ profiles.role = kyc_officer แต่ constraint ไม่อนุญาตค่านี้; role ผู้ตรวจอยู่ใน admin_roles/admin_assignments
4. issue_kao_id มี auth/ownership/KYC approved gate และ unique constraints อยู่แล้ว ต้องทดสอบ E2E ต่อ

database_review/*.sql เป็นข้อเสนอที่ตรวจทานได้ มี ROLLBACK ท้ายไฟล์ ยังไม่ได้ใช้กับฐานข้อมูลจริง ไม่ถูกเรียกโดย Flutter หรือการแตก ZIP

## ติดตั้งทีละขั้น

หยุด runner เดิมด้วย Ctrl+C หรือ Stop Debug แล้วดาวน์โหลด kaoid_completion_R2_R3.zip มาไว้ใน D:\Developer\projects\kaosure_sync

รันจากโฟลเดอร์โปรเจกต์:

```powershell
$backupItems = @('lib')
if (Test-Path .\test) { $backupItems += 'test' }
if (Test-Path .\docs) { $backupItems += 'docs' }
$backupName = 'kaoid_before_R2_R3_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path $backupItems -DestinationPath $backupName
Expand-Archive -LiteralPath .\kaoid_completion_R2_R3.zip -DestinationPath . -Force
flutter gen-l10n
if ($LASTEXITCODE -ne 0) { throw 'gen-l10n failed' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'analyze failed' }
flutter test test/localization
if ($LASTEXITCODE -ne 0) { throw 'localization tests failed' }
```

จาก source ของชุดทดสอบที่มีใน ZIP ฐาน คาดว่ารวม 69 tests (เดิม 37 + ใหม่ 32) เป็นจำนวนที่เขียน ไม่ใช่ผลรันในสภาพแวดล้อมนี้

เปิดเว็บใหม่:

```powershell
flutter run -d chrome --web-port=7357 --dart-define-from-file=.env
```

ถ้าพอร์ตถูกใช้อยู่ ให้หยุด runner เดิมก่อน ไม่ต้อง flutter clean เพื่อแก้ปัญหาพอร์ต

## ตรวจหน้าจอหลังติดตั้ง

- Sign in / Register / Forgot / Verify email / Reset / Change password เป็นไทยและอังกฤษ รวมกรอกผิด/คำขอล้มเหลว
- Settings → Sign out: Cancel อยู่หน้าเดิม, ยืนยันออกกลับ /kao-id; back ไม่กลับบัญชีเดิม
- บันทึกโปรไฟล์สำเร็จไป Dashboard; บันทึกล้มเหลวต้องอยู่หน้าเดิม
- เปิด /identity/verification โดยตรง แล้วลองกรณีโหลดล้มเหลว/Retry
- หน้าจอแคบและขยายตัวอักษร: ปุ่มข้อความยาวไม่ล้น
- ทดสอบบัญชีใหม่/บัญชีที่ยืนยันอีเมลแล้ว/ยังไม่ยืนยัน และสถานะ session จริงก่อนปิด Auth gate

## ตรวจอะไรแล้ว

- Static checks ผ่าน: ARB key parity/ไม่มี key ซ้ำ/คงค่าก่อนหน้า, getter references, imports, delimiter balance, const subtree, password validator regex/length เดิม, hash และ ZIP integrity
- อ่าน schema/trigger/function/grants/policies และ security advisors จาก Supabase จริงแบบไม่แก้ไข
- ยังไม่ได้รัน Flutter analyze/tests หรือ render R2+R3 ที่นี่: การเตรียม Flutter runtime ในรอบก่อนถูก automatic approval review ปฏิเสธ จึงต้องใช้ Flutter บนเครื่องผู้ใช้ยืนยัน
- SQL proposals ยังไม่ได้ทดสอบใน development branch หรือนำขึ้น production

## ไฟล์ติดตามงาน

- docs/kao_id_completion_plan_R3.md — ลำดับงานที่ยังต้องทำจนปิด Kao ID
- docs/kao_id_source_inventory_R3.csv — ไฟล์ lib 654 ไฟล์; literal ไทยเป็นเพียงตัวช่วยค้นหา ไม่ใช่คะแนนความครบภาษา
- docs/kao_id_R3_file_manifest.json — hash ฐานและ patch; baseline null หมายถึงไฟล์ใหม่
- docs/backend_metadata_evidence_R3.json — metadata รองรับข้อค้นพบ ไม่มีข้อมูลแถวผู้ใช้
- docs/backend_security_advisors_R3.json — รายการ advisor พร้อม remediation URL

## ย้อนกลับ

หยุด runner และแตก ZIP backup เพื่อคืน lib/test/docs แล้ว gen-l10n และ analyze
Expand-Archive ไม่ลบไฟล์ใหม่: ถ้าย้อนทั้งชุด ต้องนำไฟล์ baseline null ใน manifest และ tests ใหม่ 2 ไฟล์ออกด้วย
