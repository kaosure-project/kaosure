/// Contract สำหรับตรวจสอบข้อมูลเอกสาร
///
/// Validator แต่ละประเภท เช่น Thai ID, Passport หรือ Residence Card
/// จะต้อง implement interface นี้
abstract interface class DocumentValidator {
  /// ตรวจสอบว่าเลขเอกสารถูกต้องหรือไม่
  bool isValid(String documentNumber);

  /// ข้อความอธิบายเมื่อไม่ผ่านการตรวจสอบ
  String get errorMessage;
}