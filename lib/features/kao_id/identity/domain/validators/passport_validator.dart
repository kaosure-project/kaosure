import 'document_validator.dart';

/// Validator สำหรับตรวจสอบหมายเลขหนังสือเดินทาง (Passport)
///
/// หมายเหตุ:
/// - แต่ละประเทศมีรูปแบบ Passport แตกต่างกัน
/// - Validator นี้ตรวจสอบรูปแบบมาตรฐานเบื้องต้นเท่านั้น
/// - หากต้องการตรวจสอบเชิงลึก ควรใช้กฎเฉพาะของแต่ละประเทศ
final class PassportValidator implements DocumentValidator {
  const PassportValidator();

  static final RegExp _pattern = RegExp(r'^[A-Za-z0-9]{6,20}$');

  @override
  bool isValid(String documentNumber) {
    final number = documentNumber.trim();

    if (number.isEmpty) {
      return false;
    }

    return _pattern.hasMatch(number);
  }

  @override
  String get errorMessage => 'หมายเลขหนังสือเดินทางไม่ถูกต้อง';
}