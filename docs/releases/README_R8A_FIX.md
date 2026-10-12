# R8A FIX — ข้อความผิดพลาดบังปุ่มส่งซ้ำ

จาก log: analyze ผ่าน, 144 tests ผ่าน, 2 tests ล้มที่การกดส่งซ้ำ เพราะ SnackBar อยู่บนปุ่ม ไม่ใช่ผลทดสอบการส่งจริงจากฐานข้อมูล

แก้ PassportPage ให้แสดงข้อความผิดพลาดในเนื้อหาฟอร์มเหนือปุ่มส่ง ไม่ใช้ SnackBar ทับปุ่ม ข้อผิดพลาดโหลดหน้าคงแสดงด้านบนเมื่อไม่มีฟอร์ม
ปรับเทสต์ให้ตรวจว่าปุ่ม hitTestable และข้อความผิดพลาดยังอยู่ก่อนส่งซ้ำ คง assertion ว่าต้องส่งสองครั้งด้วย ID เดิม

ติดตั้งต่อจาก R8A มีเฉพาะหน้า passport และ test ไม่มี SQL/ARB/การเปลี่ยนคำขอจริง
ยังไม่ได้รัน Flutter ในสภาพแวดล้อมผู้จัดทำ

flutter analyze
flutter test test/localization/passport_r8a_test.dart
flutter test test/localization
