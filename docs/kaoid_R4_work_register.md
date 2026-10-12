# Kao ID — ทะเบียนงาน R4

ฐานตรวจ: snapshot 20260921_201617 + overlay R2/R3 ที่ผู้ใช้ติดตั้งแล้ว
ตรวจแบบ static เท่านั้น; ไม่เท่ากับยืนยันการทำงานจริงครบทุกไฟล์
ผู้ใช้รายงาน analyze ผ่านและ localization 69 tests ผ่านก่อน R4

| ลำดับ | หมวด | หลักฐาน/ไฟล์หลัก | สถานะและงานถัดไป |
|---|---|---|---|
| 1 | หน้าหลัก | dashboard/presentation/widgets/dashboard_home_content.dart | R4 จัดเป็นข้อมูลส่วนตัว ความปลอดภัย ยืนยันตัวตน ตั้งค่า; รอตรวจ UI บนเครื่องจริง |
| 2 | ข้อมูลส่วนตัว | account/presentation/pages/account_page.dart, edit_profile_page.dart | คงของเดิม; ผู้ใช้ทดสอบ localization ผ่าน; ยังต้องทดสอบ upload/บันทึกจริง |
| 3 | ความปลอดภัย | auth/presentation/pages/change_password_page.dart | คงรหัสผ่านเดิม; devices_tile, login_history_tile, two_factor_tile มี TODO จึงไม่เปิดเพิ่ม |
| 4 | ยืนยันตัวตน | kyc/presentation/screens/kyc_page.dart, application/controllers/kyc_controller.dart | ต้องแก้ก่อนขยาย: controller โหลดหลายแหล่งใน try เดียว; หน้า R3 ซ่อนเนื้อหาเมื่อแหล่งใดผิดพลาด; ยังไม่ทราบ runtime error จริง |
| 5 | เอกสาร | kyc/presentation/screens/residence_permit_page.dart | พบ TODO อัปโหลด; ตรวจบัตรประชาชน/หนังสือเดินทางแยกเป็นชุด |
| 6 | การตั้งค่า | dashboard/presentation/widgets/settings/ | คง language และ sign_out; notifications/privacy/about ยังมี TODO |
| 7 | บริการเชื่อมต่อ | dashboard/presentation/widgets/services/ | Marketplace/Auction/KaoPay เป็น TODO; ไม่แสดงบนหน้าหลัก; ออกแบบสมัครบริการแยกเมื่อพร้อม |
| 8 | จัดการข้อมูลและวงจรบัญชี | ตรวจเพิ่มเติมหลัง KYC | ยังไม่ยืนยัน export/close/delete account; ต้องกำหนดเงื่อนไขและ backend ก่อนสร้างปุ่ม |
| 9 | ธุรกิจ/เจ้าหน้าที่ | business/, governance/ | มีโค้ดและ routes แต่ยังไม่ถือว่าผ่าน E2E; คง permission guard เดิม |

## เกณฑ์ปิดงานรายหมวด
- ภาษาไทย/อังกฤษครบ รวม validation, loading, empty, error, retry
- ไม่มีปุ่มที่กดแล้วไม่ทำงาน; ไม่มีสถานะ verified ที่อนุมานจากโหลดผิดพลาด
- ใช้ข้อมูลจริงและตรวจสิทธิ์ฝั่ง server; ทดสอบบัญชีของตน/สิทธิ์ไม่พอ
- ทดสอบมือถือ 320px, desktop, ขยายตัวอักษร, refresh, back และ deep link
- บันทึกหลักฐานแยก static / widget tests / manual E2E

## ขอบเขต R4
เปลี่ยนเฉพาะหน้า hub และเพิ่มคำแปล ไม่เปลี่ยน Auth, profile editor, password,
locale controller, sign out, guards, backend หรือ KYC flow
หน้ายืนยันตัวตนยังมีปัญหาเดิม: R4 ไม่อ้างว่าแก้การโหลดแล้ว
ไม่ลบไฟล์ legacy เพราะอาจยังมีผู้เรียกใช้; เก็บรายการ TODO ใน CSV เพื่อตัดสินใจทีละหมวด
CSV ระบุว่าพบ AppLocalizations หรือไม่ เป็นสัญญาณตรวจเท่านั้น ไม่ใช่คะแนนความครบของภาษา
