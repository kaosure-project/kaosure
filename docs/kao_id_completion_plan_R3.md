# Kao ID completion plan — R2 + R3

อัปเดตล่าสุด: อ่านผล R3 และ backend review ประกอบ รายการเดิมด้านล่างเป็นฐานก่อนแก้ R3

ฐาน: kaoid_completion_review_20260921_201617.zip (ไฟล์ล่าสุดที่ผู้ใช้ส่ง)
วันที่ตรวจ: 2026-09-21

## สถานะที่ยืนยันได้

- สำรวจรายชื่อไฟล์ Dart ทั้ง ZIP 659 ไฟล์ และเปรียบเทียบไฟล์ production R1 ทั้ง 9 ไฟล์กับชุดล่าสุด: ตรงกัน
- ผู้ใช้ยืนยันถึงชุด 1E: analyze ผ่าน และ localization tests 30 ข้อผ่าน
- พบไฟล์ R1 และชุดทดสอบ R1 ใน ZIP แต่ยังไม่มีผลรันทดสอบ R1 จากเครื่องผู้ใช้ในข้อมูลล่าสุด
- อ่านรายละเอียดหน้า Auth หลัก, Bootstrap, AppRouter, Dashboard, จุดเชื่อม KYC และตัวอย่าง data source ที่เกี่ยวกับ issuance/sessions
- การสำรวจไฟล์ทั้งหมดไม่เท่ากับตรวจทุกบรรทัดหรือยืนยันทุกฟังก์ชันทำงานจริง
- รายการภาษาในไฟล์ inventory เป็นการสแกนข้อความ literal ภาษาไทย ไม่ใช่เปอร์เซ็นต์ความครบของภาษา: อาจรวมข้อความระบบ และไม่พบข้อความอังกฤษที่ยังฝังอยู่ทั้งหมด

## ส่งมอบใน R2

1. หน้า Sign in, Sign up, Forgot password, Verify email, Reset password, Change password และ Kao ID landing รองรับข้อความไทย/อังกฤษ
2. แปล validator, snackbar, สถานะลิงก์หมดอายุ, คำแนะนำรหัสผ่าน, ปุ่มและ tooltip ซ่อน/แสดงรหัสผ่าน
3. error ของ Auth ที่เดิมแสดง exception ตรง ๆ เปลี่ยนเป็นข้อความทั่วไปของแต่ละงาน ไม่เปลี่ยน repository/use case หรือวิธีเรียก Auth
4. กันการส่ง login/register/forgot ซ้ำขณะที่กำลังรอคำขอ
5. คำแนะนำรหัสผ่านแสดง 3 เงื่อนไขที่ validator เดิมตรวจจริง: ความยาว 8, ตัวเลข, อักขระพิเศษ ไม่เพิ่ม/ลดเงื่อนไขฝั่ง validator หรือ backend
6. ซ่อนปุ่มสมัครธุรกิจจากหน้าสมัครสมาชิก เพราะปลายทางยังมีข้อความว่าไม่ได้เชื่อม Submit UseCase ไม่ลบโดเมนธุรกิจ
7. ปรับ Kao ID landing ให้เลื่อนได้และจำกัดความกว้าง; ใช้ AuthLogo แทน FlutterLogo
8. PrimaryButton รองรับข้อความหลายบรรทัดและใช้ความสูงขั้นต่ำแทนความสูงตายตัว
9. BootstrapStatus.error แสดงข้อความและ Retry แทนวงโหลดตลอด; มี mounted guard ก่อนเริ่มโหลดจาก callback
10. เพิ่ม widget tests 23 กรณีใน auth_localization_r2_test.dart ใช้ fake Auth ไม่มีการส่งอีเมลหรือเปลี่ยนบัญชีจริง

ยังไม่แก้ชื่อผู้ใช้จำลองใน auth/presentation/widgets/profile_header.dart เพราะเป็นส่วนของ ProfileDashboardPage เก่าที่ไม่พบใน AppRouter ต้องจัดการเป็นงานลบโค้ดเก่าโดยตรวจการอ้างอิงก่อน ไม่แปลข้อมูลจำลองแล้วถือว่าเป็นหน้าใช้งานจริง

## ผลแก้เพิ่ม R3

- เพิ่ม SignOutTile ใน Settings: dialog ยืนยัน/ยกเลิก, เรียก logout เดิม, error สองภาษา, ล้าง caches ของบัญชี/แดชบอร์ด/KYC/เอกสาร/โทรศัพท์/อุปกรณ์/เซสชัน/สิทธิ์ผู้ดูแล/เลข Kao ID/ธุรกิจ และสิทธิ์ password recovery เมื่อสำเร็จ แล้วล้าง navigation stack ไป /kao-id
- เพิ่ม /kao-id เป็นทางเข้าเฉพาะ Kao ID; ไม่เปลี่ยน root / ของเว็บมือสอง
- Bootstrap เปลี่ยนหน้าโดย named routes เพื่อเก็บชื่อ route แทน MaterialPageRoute ที่ไม่มีชื่อ
- CompleteProfile เมื่อ update สำเร็จไป Dashboard โดยไม่บังคับ KYC; การซ่อม profile ที่หายผิดปกติยังเป็นงาน backend ไม่เพิ่ม client INSERT ที่ฐานข้อมูลไม่อนุญาต
- Business argument fallback ทั้ง 3 จุดห่อ AuthGuard เหมือนเส้นทางปกติ
- KycPage โหลด profile พร้อม KYC เมื่อเข้าลิงก์ตรง และมี localized error/retry; ไม่อ้างว่าหน้าเอกสารปลายทางทุกหน้าถูกแปลแล้ว
- เพิ่มคำแปล R3 อีก 8 key และ tests 9 กรณี; รวม R2+R3 เพิ่ม 32 tests (ยังไม่ได้รันที่นี่)

งานถัดไปที่ต้องทำจริง: ปิดช่องสิทธิ์ production หลัง review, ทดสอบ Auth E2E โดยเฉพาะ email-confirmation/session, แปลหน้าปลายทาง KYC/โทรศัพท์/เอกสาร/ธุรกิจ/ผู้ตรวจที่เหลือ และเชื่อมระบบที่เป็น TODO ตามแผน R4–R10

## จุดที่ต้องจัดการตามลำดับ

พาธในตารางอ้างจาก lib/features/kao_id/ เว้นแต่ระบุเป็นอย่างอื่น

| ลำดับ/ชุด | งานและไฟล์หลัก | สิ่งที่ต้องได้ก่อนปิดชุด |
| --- | --- | --- |
| R2 — รอบนี้ | auth/presentation/pages/, widgets/auth_logo.dart, widgets/password_requirements.dart; shared/widgets/forms/; bootstrap/screens/kao_id_bootstrap_screen.dart | gen-l10n, analyze, localization tests ผ่าน และลอง flow จริงสองภาษา |
| R3 — ปิดทางเดินบัญชี | dashboard/presentation/screens/dashboard_screen.dart; เพิ่ม settings/sign_out_tile.dart; auth/application/notifiers/auth_notifier.dart; bootstrap/screens/; account/presentation/pages/complete_profile_page.dart; lib/app/router.dart | ปุ่มออกจากระบบที่เรียกกลไกเดิมจริง พร้อมยกเลิก/รอ/ล้มเหลว; บันทึกโปรไฟล์แล้วไปต่อได้; routes และ refresh/back ถูกต้อง; clear state เมื่อเปลี่ยนบัญชี |
| R4 — KYC overview และช่องทางติดต่อ | kyc/presentation/screens/kyc_page.dart; kyc/presentation/widgets/verification_section.dart, page_header.dart, verification_progress_card.dart; kyc/presentation/email/; phone_verification/presentation/pages/phone_verification_page.dart | เข้า KYC โดย URL ตรงได้ ไม่พึ่งการเปิด Home ก่อน; loading/error/retry; ไทย/อังกฤษทุกสถานะอีเมล/โทรศัพท์/OTP; ไม่อ้างว่ายืนยันแล้วจากการส่งรหัส |
| R5 — เอกสารยืนยันตัวตน | identity/presentation/screens/ และ widgets/; kyc/presentation/identity_card/; kyc/presentation/passport/; kyc/presentation/screens/residence_permit_page.dart | อัปโหลด/ดู/แก้ไข/ส่งตรวจ/ปฏิเสธ/หมดอายุครบ; รูป/ไฟล์เข้าถึงตามสิทธิ์; ปิดปุ่มใบพำนักจนเชื่อมจริง; แปลวัน เวลา สถานะ validator และ dialog |
| R6 — ผลตรวจและ Kao ID | kyc/presentation/screens/verification_history_page.dart; kyc/application/; issuance/data/datasources/supabase_kao_id_issuance_datasource.dart; issuance/application/providers/ | อ่านผลจาก backend; ตรวจ RPC issue_kao_id และตาราง kao_id_identities ว่าออกเลขหลังอนุมัติและไม่ออกซ้ำ; ห้ามให้คะแนน UI ใช้แทนสิทธิ์จริง |
| R7 — ความปลอดภัยของบัญชี | devices/presentation/screens/device_list_page.dart; devices/application/; sessions/application/ และ data/; เพิ่ม sessions/presentation/pages/session_list_page.dart | route/load/error/empty/refresh; แยกอุปกรณ์จาก session; การเพิกถอนต้องทำให้ session ใช้งานไม่ได้จริง ไม่ใช่เปลี่ยน revoked_at เฉย ๆ; ป้องกันกระทบบัญชีอื่น |
| R8 — การตั้งค่าจำเป็น | เพิ่ม settings/presentation/pages/privacy_page.dart, about_page.dart, account_closure_page.dart ตามความพร้อม; core/localization/locale_controller.dart | ภาษาใช้แหล่งข้อมูลเดียว; ข้อมูลเกี่ยวกับแอปมาจากเวอร์ชันจริง; ข้อความนโยบายที่เจ้าของระบบยืนยัน; การปิดบัญชีต้องมี backend ก่อนเปิดปุ่ม; notifications เปิดเฉพาะมีระบบรับจริง |
| R9 — ผู้ตรวจ/ธุรกิจ/ธนาคาร | governance/presentation/; business/presentation/pages/; kyc/presentation/bank/ | แยกสิทธิ์ผู้ใช้กับผู้ตรวจ; เชื่อม use case/upload/submit/cancel จริง; ไม่ใส่ธุรกิจและธนาคารในเมนูผู้ใช้ทั่วไปจนจำเป็นและพร้อม |
| R10 — เชื่อมเว็บมือสองและเก็บงาน | เพิ่ม service_membership/domain/, application/, data/ เมื่อสัญญาข้อมูลพร้อม; ตรวจ lib/app/router.dart; ลบ legacy UI หลังตรวจ references | Kao ID เป็นตัวตนกลาง; สมัครใช้ Marketplace แยก membership โดยใช้ profile เดิม; เส้นทางกลับ Kao ID; capability จาก server; ทดสอบข้ามบริการและตรวจภาษาทั้งเส้นทาง |

## จุดบกพร่องที่พบจาก source (ดูผลแก้ R3 ด้านบน)

- **R3 / ไม่มีปุ่ม logout ใน shell ใหม่:** DashboardScreen มี Home/Account/Security/Settings และใช้ password/language/governance แต่ไม่เรียก logout ที่มีอยู่ใน AuthNotifier
- **R3 / บันทึกโปรไฟล์แรกไม่ไปต่อ:** complete_profile_page.dart มี comment ระบุว่าไม่ navigate จนตรวจ KYC flow ครบ ต้องตัดสินจาก profile-ready ตาม Bootstrap ไม่ควรบังคับ KYC เพื่อเข้าหน้าบัญชี
- **R3 / fallback route ธุรกิจ:** lib/app/router.dart กรณี arguments ไม่ใช่ Map ใน BusinessDocument/Review/Completed คืน BusinessRegistrationPage โดยไม่ห่อ AuthGuard เหมือนเส้นทางปกติ ต้องแก้ความสม่ำเสมอของ route; นี่ไม่ใช่ผลทดสอบสิทธิ์ database
- **R3 / URL กับหน้าที่แสดง:** Bootstrap ใช้ MaterialPageRoute ไม่มีชื่อ route จึงต้องตรวจ refresh/back; AppRouter root และ unknown route ยังกลับ LandingScreen ของ secondhand ต้องแยกจุดเข้า Kao ID ให้ชัดก่อนเชื่อมหลายบริการ
- **R4 / KYC direct entry:** KycPage เรียก load() ของ KYC แต่ใช้ profile จาก dashboardControllerProvider โดยไม่โหลด profile เอง ถ้าเข้าลิงก์ตรงอาจไม่มี profile แม้มีบัญชี
- **R4 / KYC errors:** ต้องตรวจ kycState.hasError/ผลล้มเหลวครบก่อนทำให้หน้า empty ดูเหมือนผู้ใช้ไม่มีข้อมูล
- **R5 / ใบพำนัก:** verification_section.dart เปิด ResidencePermitPage ที่ปุ่ม Upload เป็น TODO และสถานะเป็นข้อความตายตัว
- **R7 / อุปกรณ์:** DeviceListPage ดู state แต่ไม่เรียก loadDevices และไม่พบ route ใน AppRouter; ยังไม่แสดง error state แยกจากไม่มีอุปกรณ์
- **R7 / sessions:** data source ที่อ่านมีการ update sessions.revoked_at แต่ใน method นี้ไม่มีการเพิกถอน Auth token ต้องตรวจกลไก server ที่ใช้ฟิลด์นี้ก่อนระบุว่าบังคับออกจากระบบได้
- **R9 / ธุรกิจ:** BusinessRegistrationPage มีข้อความไม่ได้เชื่อม UseCase/upload/submit/cancel หลายจุด; BusinessReviewPage ยังไม่เชื่อม submit จริง
- **UI cleanup:** มี legacy DashboardSecuritySection/ServicesSection/SettingsSection ที่ shell ใหม่ไม่ได้ใช้ และ profile dashboard จำลอง ควรตรวจ references และ tests ก่อนลบ ไม่ลบทั้ง folder ตามชื่อ
- **ความสอดคล้องของข้อมูล:** CompleteProfile ใช้ขีดจำกัด display name 100 แต่ EditProfile ใช้ 3–30; ต้องเทียบ schema/กฎจริงก่อนรวม validator
- **ภาษา:** profile.languageCode กับ locale controller ในเครื่องยังต้องกำหนดว่าตัวไหนเป็นค่าหลักและซิงก์เมื่อใด

## ข้อมูล backend ที่ตรวจเพิ่มแล้วใน R3

ตรวจ metadata ผ่าน Supabase ของ kaosure-project's Project ได้แล้ว จึงไม่ต้องส่ง schema ซ้ำเพื่อยืนยัน trigger/สิทธิ์ที่อ่านในรอบนี้ พบ trigger handle_new_user สร้าง profiles และ verifications จริง, issue_kao_id มี auth/ownership/approved gate และ unique profile_id, แต่พบช่องสิทธิ์ profiles UPDATE และความไม่ตรงกันของบทบาท KYC officer รายละเอียดอยู่ใน backend_review_R3.md

ไม่มีการแก้ฐานข้อมูลจริงหรือเรียกอนุมัติ/ออก Kao ID ในรอบนี้ ยังต้องทดสอบบัญชีใหม่และ KYC E2E ในสภาพแวดล้อมทดสอบหลังแก้ประเด็นสิทธิ์

## เกณฑ์ก่อนเริ่มเชื่อมเว็บมือสองจริง

- สมัคร/เข้า/ออก/กู้รหัส/เปลี่ยนรหัส/สร้างและแก้โปรไฟล์ เดินทางจนจบได้
- Thai/English ครบทุกหน้าที่เปิดให้ใช้งาน รวม dialog, validation, error และข้อมูลวันที่
- KYC และ Kao ID issuance ใช้สถานะ server ที่ตรวจสิทธิ์แล้ว; ผู้ไม่ผ่านไม่รับสิทธิ์จากการแก้ UI
- ไม่มีปุ่มที่ดูพร้อมแต่ callback ว่าง ไม่มีสถานะยืนยันตัวตนจำลอง
- แยกบัญชี Kao ID ออกจากการสมัครใช้บริการ Marketplace และสิทธิ์ของบริการ
- ทดสอบเปิดลิงก์ตรง, รีเฟรช, back, มือถือ, ตัวอักษรใหญ่, session หมดอายุ และการเปลี่ยนบัญชี
- analyze/tests ผ่าน ไม่ถือว่า UI tests ผ่านเท่ากับ backend พร้อม production

## ขอบเขตการตรวจ R2

ตรวจเชิง static: JSON/ARB key parity, เก็บข้อความเดิมครบ, getter references, import targets, delimiter balance, regex/password-length validators เดิม, ZIP integrity

ยังไม่ได้รัน Flutter analyze/test หรือ render หน้าจอ R2 ในสภาพแวดล้อมนี้ การติดตั้ง Flutter ในรอบก่อนถูก automatic approval review ปฏิเสธเพราะติดต่อ metadata endpoint จึงไม่พยายามใช้วิธีอื่นข้ามข้อจำกัด ชุดทดสอบที่แนบต้องรันบน Flutter ในเครื่องผู้ใช้ก่อนถือว่าผ่าน

อ้างอิง API ที่ตรวจประกอบ: https://docs.flutter.dev/ui/internationalization และ https://api.flutter.dev/flutter/flutter_test/TestTextInput/hide.html (hide คืน void จึงไม่ใช้ await)
