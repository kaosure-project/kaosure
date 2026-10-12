# R8C fix — evidence viewer loading state

จากผลผู้ใช้: analyzer ผ่าน; เทสต์ธนาคาร 7 ผ่าน 4 ล้ม; รวม 161 ผ่าน 4 ล้ม
สาเหตุ: _preview รอ showDialog ก่อนคืน _busy=false ทำให้ LinearProgressIndicator เคลื่อนไหวค้างใต้ dialog และ pumpAndSettle timeout
แก้ให้จบ loading หลังดาวน์โหลดภาพ ก่อนเปิด dialog โดยคงการตรวจ session และการซ่อนภาพหลังออกจากระบบ
เพิ่ม assertion ว่าไม่มี loading ค้างใต้ dialog และปิดภาพกลับมายังปุ่ม refresh ที่ใช้งานได้
ไม่ลดหรือข้ามเทสต์ และไม่เปลี่ยน timeout

ติดตั้งหลัง R8C เท่านั้น ไม่แก้ฐานข้อมูลหรือข้อมูลที่ส่งไปแล้ว
Flutter ยังไม่ได้รันที่นี่ กรุณารันบนเครื่อง:

```powershell
Expand-Archive -LiteralPath .\kaoid_bank_R8C_fix.zip -DestinationPath . -Force
flutter analyze
flutter test test/localization/bank_r8c_test.dart
flutter test test/localization
```
