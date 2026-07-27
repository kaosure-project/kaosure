/// ประเภทของเอกสารยืนยันตัวตน
///
/// เป็นประเภทมาตรฐานของระบบ
/// ส่วนชื่อที่แสดงผลสามารถปรับได้จากฐานข้อมูล
enum DocumentTypeEnum {
  thaiNationalId,
  passport,
  residenceCard,
  drivingLicense,
  companyRegistration,
  taxDocument,
  other,
}

extension DocumentTypeEnumExtension on DocumentTypeEnum {
  /// ค่าสำหรับจัดเก็บใน Database
  String get value {
    switch (this) {
      case DocumentTypeEnum.thaiNationalId:
        return 'thai_national_id';

      case DocumentTypeEnum.passport:
        return 'passport';

      case DocumentTypeEnum.residenceCard:
        return 'residence_card';

      case DocumentTypeEnum.drivingLicense:
        return 'driving_license';

      case DocumentTypeEnum.companyRegistration:
        return 'company_registration';

      case DocumentTypeEnum.taxDocument:
        return 'tax_document';

      case DocumentTypeEnum.other:
        return 'other';
    }
  }

  /// ชื่อสำหรับแสดงผล
  String get label {
    switch (this) {
      case DocumentTypeEnum.thaiNationalId:
        return 'บัตรประชาชน';

      case DocumentTypeEnum.passport:
        return 'หนังสือเดินทาง';

      case DocumentTypeEnum.residenceCard:
        return 'Residence Card';

      case DocumentTypeEnum.drivingLicense:
        return 'ใบขับขี่';

      case DocumentTypeEnum.companyRegistration:
        return 'หนังสือรับรองบริษัท';

      case DocumentTypeEnum.taxDocument:
        return 'เอกสารภาษี';

      case DocumentTypeEnum.other:
        return 'อื่น ๆ';
    }
  }

  static DocumentTypeEnum fromValue(String value) {
    switch (value) {
      case 'thai_national_id':
        return DocumentTypeEnum.thaiNationalId;

      case 'passport':
        return DocumentTypeEnum.passport;

      case 'residence_card':
        return DocumentTypeEnum.residenceCard;

      case 'driving_license':
        return DocumentTypeEnum.drivingLicense;

      case 'company_registration':
        return DocumentTypeEnum.companyRegistration;

      case 'tax_document':
        return DocumentTypeEnum.taxDocument;

      case 'other':
        return DocumentTypeEnum.other;

      default:
        throw ArgumentError('Unknown document type: $value');
    }
  }

  /// เป็นเอกสารส่วนบุคคล
  bool get isPersonal =>
      this != DocumentTypeEnum.companyRegistration;

  /// เป็นเอกสารนิติบุคคล
  bool get isCompany =>
      this == DocumentTypeEnum.companyRegistration;
}