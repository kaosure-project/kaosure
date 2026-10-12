# 1D test fix

แก้เฉพาะ test/localization/profile_localization_1d_test.dart หลังติดตั้งชุด 1D
จาก log: analyzer ผ่าน แต่ tests 4 กรณีแตะปุ่มที่ตำแหน่ง y=612 นอกหน้าจอสูง 600
แก้โดย unfocus/hide test keyboard รอ layout แล้วเลื่อนปุ่มเข้าสู่ viewport รอ layout อีกครั้ง
ตรวจ hitTestable ก่อนแตะจริง คง assertions ภาษาและ validation ทั้งหมด ไม่ปิด warning
ไม่เปลี่ยนขนาดหน้าจอทดสอบ ไม่เรียก validator โดยตรง และไม่แก้โค้ดแอปเพื่อให้ test ผ่าน

สำรองไฟล์ test เดิมก่อนแตก ZIP นี้ แล้วรันทีละคำสั่ง:

```powershell
flutter analyze
flutter test test/localization/profile_localization_1d_test.dart
flutter test test/localization
```

ยังไม่ได้รัน Flutter ในฝั่งจัดทำ ต้องยืนยันผลจากเครื่องผู้ใช้
คาดว่าชุดโปรไฟล์มี 7 กรณีและชุดรวมมี 24 กรณี หากไม่มีการเพิ่ม test อื่น
ไม่ต้อง flutter gen-l10n เพราะไม่ได้แก้ ARB
