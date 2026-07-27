import 'document_validator.dart';

/// Validator สำหรับตรวจสอบเลขบัตรประชาชนไทย 13 หลัก
final class ThaiIdValidator implements DocumentValidator {
  const ThaiIdValidator();

  @override
  bool isValid(String documentNumber) {
    final number = documentNumber.replaceAll(RegExp(r'\D'), '');

    // ต้องมี 13 หลัก
    if (number.length != 13) {
      return false;
    }

    // ต้องเป็นตัวเลขทั้งหมด
    if (!RegExp(r'^\d{13}$').hasMatch(number)) {
      return false;
    }

    int sum = 0;

    for (int i = 0; i < 12; i++) {
      sum += int.parse(number[i]) * (13 - i);
    }

    final checkDigit = (11 - (sum % 11)) % 10;

    return checkDigit == int.parse(number[12]);
  }

  @override
  String get errorMessage =>
      'หมายเลขบัตรประชาชนไม่ถูกต้อง';
}