# Audit และความต่อเนื่อง — 1C

## หลักฐานชุดก่อน
- 1B: ผู้ใช้รัน analyzer ไม่พบปัญหาและ tests ผ่าน 7 กรณี
- ภาพล่าสุดแสดง Security และ Settings ถูกต้องทั้งไทย/อังกฤษ ไอคอนปกติ ณ ขนาดภาพ
- การจำภาษาหลัง refresh, โทรศัพท์จริง และการนำทาง Password ยังไม่มีผลยืนยันในรอบนี้

## ผลตรวจและการแก้ 1C
1. Services ทุกตัวเป็น TODO: ปิดการกด ใช้ข้อความยังไม่เปิดให้บริการ ไม่สัญญาว่าจะเปิดเมื่อใด
2. DashboardAppBar ไม่มี callbacks จาก Dashboard: ซ่อน actions ที่ไม่มีการทำงาน
3. KaoPay ซ้ำสองหมวด: คงใน Services เอาออกเฉพาะการประกอบกลุ่ม quick actions
4. Quick actions เดิมบังคับ 4 คอลัมน์ + aspect ratio: เปลี่ยน Wrap ปรับคอลัมน์และความสูงตามเนื้อหา
5. VerifyAction ถูกนิยามซ้ำในไฟล์ที่ barrel widgets.dart ส่งออก: แทนสำเนาด้วย export ของตัวเดียว
6. Profile/Verify navigation คงเดิม รวม context.mounted และ loadDashboard หลังกลับจาก Profile
7. ชื่อ Kao ID เป็นแบรนด์ ใช้คีย์ kaoId เดิมของทั้งสองภาษา

## ยังต้องทำ
- SEC-01/02/03 จาก 1B: Devices, Login History, Two-Factor ยังไม่มีการทำงาน ไม่ใช่งานชุดนี้
- SET-01: Notifications/Privacy/About ในหมวด Settings ยังต้องตรวจและจัดการ TODO ต่อ
- ปุ่ม Back บน Dashboard: ตรวจ route stack จริงก่อนเปลี่ยน; ไม่ลบจากภาพอย่างเดียว
- Profile card, empty/error state ของ Dashboard และหน้าปลายทางยังไม่แปลครบ
- quick action badge เปลี่ยนเป็นอยู่ใน flow เพื่อไม่ทับชื่อ ต้องตรวจผู้ใช้ component อื่นเมื่อมีการเพิ่ม badge
- QuickActionsLayout ออกแบบสำหรับพื้นที่ที่มีความกว้างจำกัด เช่น Dashboard; ไม่ใช้ใน horizontal scroll ที่ไม่กำหนด width

## สถานะ
1C: พร้อมให้ติดตั้งและทดสอบ ไม่ได้ถือว่าผ่าน analyzer/tests/UI จนมีผลจากเครื่องผู้ใช้
UI เปลี่ยนเฉพาะบริเวณที่ระบุ ไม่มีการลบระบบบริการหรือเปลี่ยนสิทธิ์บัญชี
