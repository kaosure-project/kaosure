# Kao ID — บันทึกงานภาษา / UI / ฟังก์ชันค้าง

## กติกา
ทำเป็นชุดเล็ก ใช้ ARB ล่าสุดต่อเนื่อง ไม่แก้ Auth/สิทธิ์/ฐานข้อมูลแฝงในชุดภาษา
analyzer ผ่านไม่เท่ากับ UI สวยหรือฟังก์ชันครบ ปิดชุดเมื่อมีหลักฐานทดสอบตามขอบเขต

## สถานะ
| ชุด | จัดทำ/ติดตั้ง | การตรวจ | ยังเหลือ |
|---|---|---|---|
| ส่วนกลางภาษา | ผู้ใช้ติดตั้งแล้ว | ผู้ใช้แสดงภาพการสลับภาษาได้ | ยังไม่มีคำยืนยันชัดเจนเรื่องจำค่าหลังรีเฟรช |
| 1A Settings | ส่งแล้ว ผู้ใช้แตก ZIP แล้ว | ผู้ใช้รายงาน No issues found (2.9s) | รอภาพไทย/อังกฤษและตรวจหน้าจอแคบ |
| 1B Security | จัดทำแล้ว รอติดตั้ง | ตรวจ JSON และขอบเขต diff แล้ว | รอ gen-l10n/analyze/widget tests/UI จากผู้ใช้ |

## ชุด 1B: รายการไฟล์และสิ่งที่ทำ
ฐานโฟลเดอร์: lib/features/kao_id/dashboard/presentation/widgets/security/

| ไฟล์ | งานที่ทำ |
|---|---|
| dashboard_security_section.dart | เปลี่ยนหัวข้อเป็น l10n.security |
| password_tile.dart | ใช้ l10n.password / passwordChangeDescription; คง onTap เดิม |
| devices_tile.dart | แปลชื่อ/คำอธิบาย; คง TODO |
| login_history_tile.dart | แปลชื่อ/คำอธิบาย; คง TODO |
| two_factor_tile.dart | แปลชื่อ/คำอธิบาย; คง TODO |
| lib/l10n/app_en.arb | เก็บคีย์ 1A ครบ และเพิ่มคีย์ 1B จำนวน 7 คีย์ |
| lib/l10n/app_th.arb | คีย์ตรงกับอังกฤษและแปลครบ |
| test/localization/security_localization_1b_test.dart | เพิ่ม 7 กรณีทดสอบ แต่ยังไม่รันที่นี่ |

## ข้อค้นพบที่ต้องทำเป็นชุดแยก

### SEC-01 — Devices ยังไม่เชื่อมและ route ไม่ตรงกัน
- ไฟล์: lib/features/kao_id/dashboard/presentation/widgets/security/devices_tile.dart
- onTap ยังเป็น TODO
- lib/features/kao_id/router/kao_id_routes.dart ใช้ /devices
- lib/features/kao_id/devices/presentation/screens/device_list_page.dart ใช้ /kao-id/devices
- AppRouter ใน lib/app/router.dart ฉบับที่ตรวจไม่มี case ของ Devices
- ผลกระทบ: ผู้ใช้เห็นปุ่มแต่กดแล้วไม่มีการทำงาน
- งานต่อ: ตรวจ provider/data source/สิทธิ์ผู้ใช้และตกลง route กลางก่อนเชื่อม ไม่เดาเส้นทาง
- ความสำคัญ: ต้องแก้ก่อนประกาศว่า Devices ใช้งานได้

### SEC-02 — Login History ยังไม่เชื่อม
- ไฟล์: lib/features/kao_id/dashboard/presentation/widgets/security/login_history_tile.dart
- onTap ยังเป็น TODO
- งานต่อ: ตรวจว่ามีหน้าประวัติและแหล่งข้อมูลใด ห้ามถือว่า /sessions คือประวัติการเข้าสู่ระบบโดยอัตโนมัติ

### SEC-03 — Two-Factor ยังไม่เชื่อม
- ไฟล์: lib/features/kao_id/dashboard/presentation/widgets/security/two_factor_tile.dart
- onTap ยังเป็น TODO
- งานต่อ: แยกออกแบบ/ตรวจ MFA และ recovery flow ไม่เติมระบบความปลอดภัยในชุดภาษา

### SET-01 — Settings 3 เมนูมีแต่คำแปล ยังไม่มีฟังก์ชัน
- ไฟล์ใน lib/features/kao_id/dashboard/presentation/widgets/settings/:
  notifications_tile.dart, privacy_tile.dart, about_tile.dart
- onTap ยังเป็น TODO ตามฐานเดิม
- งานต่อ: ตรวจหน้าปลายทางและขอบเขตแต่ละฟีเจอร์ก่อนเชื่อม

### UI-01 — ต้องตรวจภาพจริงก่อนปรับหน้าตา
- dashboard_menu_tile.dart รับข้อความและใช้ ListTile ไม่ได้กำหนดความกว้างข้อความตายตัว
- ยังไม่ได้แก้ layout เนื่องจากไม่มีภาพหลังติดตั้งชุด 1A/1B สำหรับประเมินปัญหาเฉพาะจุด
- ชื่อ Two-Factor ภาษาไทยยาว: เพิ่มกรณีทดสอบที่ 320px และ text scale 2
- ทดสอบนี้เป็นค่า theme มาตรฐาน ไม่รับประกันความถูกต้องของ theme/font/ทุกหน้าจอจริง
- ไอคอน: ผู้ใช้ยืนยันว่ากลับมาปกติหลังเปิดแอปด้วยค่ารันเดิมก่อนเริ่มชุด 1A; ชุด 1B ไม่แก้ไอคอน

## ขั้นถัดไป
1. รับผล gen-l10n/analyze/test และภาพ Security/Settings ไทย–อังกฤษ
2. แก้ความผิดพลาดของชุด 1B ก่อนขยายขอบเขต
3. เลือกชุดถัดไปให้ชัด: UI Settings/Security หรือเมนู Dashboard กลุ่มอื่น
4. SEC-01 ถึง SEC-03 เป็นงานแยกที่ยังไม่เริ่ม ไม่ใช่ฟังก์ชันที่เสร็จแล้ว

## สิ่งที่ยังไม่อยู่ในขอบเขตชุด 1B
ภาษาเพิ่มเติมนอกจากไทย/อังกฤษ, แปลทุกหน้า, Backend errors, KYC, Marketplace,
เปลี่ยนโครงสร้าง Auth/สิทธิ์, ปรับ schema และฟังก์ชัน MFA
