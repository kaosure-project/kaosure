import '../enums/document_type_enum.dart';
import '../validators/company_registration_validator.dart';
import '../validators/document_validator.dart';
import '../validators/passport_validator.dart';
import '../validators/residence_card_validator.dart';
import '../validators/thai_id_validator.dart';

/// Domain Service สำหรับตรวจสอบข้อมูลเอกสาร
///
/// ทำหน้าที่เลือก Validator ที่เหมาะสมตามประเภทเอกสาร
/// โดยไม่ให้ส่วนอื่นของระบบต้องรู้รายละเอียดการตรวจสอบ
final class DocumentValidationService {
  const DocumentValidationService();

  /// ตรวจสอบความถูกต้องของหมายเลขเอกสาร
  bool validate({
    required DocumentTypeEnum documentType,
    required String documentNumber,
  }) {
    return _getValidator(documentType).isValid(documentNumber);
  }

  /// คืนข้อความเมื่อการตรวจสอบไม่ผ่าน
  String validationMessage(DocumentTypeEnum documentType) {
    return _getValidator(documentType).errorMessage;
  }

  /// เลือก Validator ตามประเภทเอกสาร
  DocumentValidator _getValidator(DocumentTypeEnum type) {
    switch (type) {
      case DocumentTypeEnum.thaiNationalId:
        return const ThaiIdValidator();

      case DocumentTypeEnum.passport:
        return const PassportValidator();

      case DocumentTypeEnum.residenceCard:
        return const ResidenceCardValidator();

      case DocumentTypeEnum.companyRegistration:
        return const CompanyRegistrationValidator();

      case DocumentTypeEnum.drivingLicense:
      case DocumentTypeEnum.taxDocument:
      case DocumentTypeEnum.other:
        return const PassportValidator();
    }
  }
}