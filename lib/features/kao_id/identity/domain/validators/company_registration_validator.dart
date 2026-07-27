import 'document_validator.dart';

/// Validator สำหรับเลขทะเบียนนิติบุคคล
///
/// ปัจจุบันตรวจสอบรูปแบบทั่วไปเท่านั้น
/// แต่ละประเทศสามารถสร้าง Validator เฉพาะได้ในอนาคต
final class CompanyRegistrationValidator implements DocumentValidator {
  const CompanyRegistrationValidator();

  static final RegExp _pattern = RegExp(r'^[A-Za-z0-9\-]{5,30}$');

  @override
  bool isValid(String documentNumber) {
    final number = documentNumber.trim();

    if (number.isEmpty) {
      return false;
    }

    return _pattern.hasMatch(number);
  }

  @override
  String get errorMessage => 'เลขทะเบียนนิติบุคคลไม่ถูกต้อง';
}