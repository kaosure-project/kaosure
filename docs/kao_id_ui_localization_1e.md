# สถานะและ audit 1E

- 1D: ผู้ใช้ยืนยัน UI ไทย/อังกฤษผ่าน และ analyzer/tests รวม 24 ผ่านหลังแก้ test helper
- 1E: เพิ่มภาษาส่วนข้อมูลโปรไฟล์ Dashboard และลดเมนู/ข้อความซ้ำ ยังรอ analyzer/tests/UI
- แปลทุกหน้าของ Kao ID ยังไม่ครบ ดูรายการสำรวจ 1D ประกอบ

## การจัดเมนู
Dashboard เป็นจุดรวมเมนูหลัก; Account เน้นข้อมูลโปรไฟล์
Identity/Devices/Sessions/Language/Notifications เดิมบน Account เป็น callback ว่างทั้งหมด
จึงเอาออกจาก Account โดยไม่สร้างการนำทางใหม่หรือกระทบเมนูหลัก
Bank accounts/Organizations เดิมยังไม่ทำงาน ซ่อนไว้และคง requirement ในแผนอนาคต
ไม่ตีความ Sessions ว่าเป็น Login History; ต้องตรวจ domain และข้อมูลก่อนเชื่อม

## จุดที่พบแต่ยังไม่แก้
- ภาพ Account/Edit Profile แสดง URL /security/password: ต้องตรวจ named/unnamed routes,
  browser Back และ reload ก่อนแก้ router; ยังไม่มีหลักฐานว่าเป็นปัญหาสิทธิ์หรือเข้า Account ผ่าน Password โดยตรง
- ระดับบัญชี Standard ยังใช้ไอคอน verified สีเทาใน Account ตามเดิม; ควรแยกสัญลักษณ์ตามระดับหลังตรวจ mapping จริง
- completion ใช้ username และชื่อจริงตามสูตรเดิม อาจไม่สอดคล้องกับ Kao ID profile ที่ไม่บังคับ service username
  ต้องกำหนดเกณฑ์ใหม่ร่วมกับกฎโดเมนก่อนเปลี่ยน ห้ามนำเปอร์เซ็นต์นี้ไปใช้ตัดสินสิทธิ์
- ชื่อ Complete/Edit Profile ยังมีกฎความยาวต่างกัน 100 และ 3–30; ต้องตรวจ backend ก่อนรวมกฎ
- ปุ่ม Security/Settings ที่เป็น TODO ยังต้องทำตามแผนเดิม ไม่ถือว่าใช้งานจริงได้จากการแปล

## คิวถัดไป
Auth และ Phone verification: แปลหน้า/validator/dialog/snackbar โดยคง foundation และ flow เดิม
จากนั้น KYC/Identity/Issuance, Business และ Governance ตาม inventory
