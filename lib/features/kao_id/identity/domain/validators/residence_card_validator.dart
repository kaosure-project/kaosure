import 'document_validator.dart';

/// Validator สำหรับตรวจสอบ Residence Card
///
/// หมายเหตุ:
/// - แต่ละประเทศมีรูปแบบ Residence Card แตกต่างกัน
/// - Validator นี้ตรวจสอบรูปแบบมาตรฐานเบื้องต้นเท่านั้น
final class ResidenceCardValidator implements DocumentValidator {
  const ResidenceCardValidator();

  static final RegExp _pattern = RegExp(r'^[A-Za-z0-9\-]{6,20}$');

  @override
  bool isValid(String documentNumber) {
    final number = documentNumber.trim();

    if (number.isEmpty) {
      return false;
    }

    return _pattern.hasMatch(number);
  }

  @override
  String get errorMessage => 'หมายเลข Residence Card ไม่ถูกต้อง';
}