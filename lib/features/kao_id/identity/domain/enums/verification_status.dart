/// สถานะของกระบวนการตรวจสอบเอกสาร
///
/// ใช้แยก "สถานะการตรวจสอบ"
/// ออกจาก "สถานะของเอกสาร"
enum VerificationStatus {
  /// ยังไม่ได้ส่งตรวจ
  notSubmitted,

  /// ส่งตรวจแล้ว
  submitted,

  /// เจ้าหน้าที่กำลังตรวจสอบ
  underReview,

  /// ขอข้อมูลเพิ่มเติม
  additionalInformationRequired,

  /// ผ่านการตรวจสอบ
  approved,

  /// ไม่ผ่านการตรวจสอบ
  rejected,

  /// ยกเลิกคำขอตรวจสอบ
  cancelled,
}

extension VerificationStatusExtension on VerificationStatus {
  /// ค่าสำหรับจัดเก็บใน Database
  String get value {
    switch (this) {
      case VerificationStatus.notSubmitted:
        return 'not_submitted';

      case VerificationStatus.submitted:
        return 'submitted';

      case VerificationStatus.underReview:
        return 'under_review';

      case VerificationStatus.additionalInformationRequired:
        return 'additional_information_required';

      case VerificationStatus.approved:
        return 'approved';

      case VerificationStatus.rejected:
        return 'rejected';

      case VerificationStatus.cancelled:
        return 'cancelled';
    }
  }

  /// ข้อความสำหรับแสดงผล
  String get label {
    switch (this) {
      case VerificationStatus.notSubmitted:
        return 'ยังไม่ได้ส่งตรวจ';

      case VerificationStatus.submitted:
        return 'ส่งตรวจแล้ว';

      case VerificationStatus.underReview:
        return 'กำลังตรวจสอบ';

      case VerificationStatus.additionalInformationRequired:
        return 'ต้องการข้อมูลเพิ่มเติม';

      case VerificationStatus.approved:
        return 'ผ่านการตรวจสอบ';

      case VerificationStatus.rejected:
        return 'ไม่ผ่านการตรวจสอบ';

      case VerificationStatus.cancelled:
        return 'ยกเลิก';
    }
  }

  static VerificationStatus fromValue(String value) {
    switch (value) {
      case 'not_submitted':
        return VerificationStatus.notSubmitted;

      case 'submitted':
        return VerificationStatus.submitted;

      case 'under_review':
        return VerificationStatus.underReview;

      case 'additional_information_required':
        return VerificationStatus.additionalInformationRequired;

      case 'approved':
        return VerificationStatus.approved;

      case 'rejected':
        return VerificationStatus.rejected;

      case 'cancelled':
        return VerificationStatus.cancelled;

      default:
        throw ArgumentError('Unknown verification status: $value');
    }
  }

  /// ตรวจสอบว่ายังอยู่ในขั้นตอนการตรวจสอบหรือไม่
  bool get isInProgress =>
      this == VerificationStatus.submitted ||
      this == VerificationStatus.underReview;

  /// ตรวจสอบว่าตรวจเสร็จแล้วหรือไม่
  bool get isCompleted =>
      this == VerificationStatus.approved ||
      this == VerificationStatus.rejected ||
      this == VerificationStatus.cancelled;

  /// ตรวจสอบว่าผ่านการตรวจสอบหรือไม่
  bool get isApproved =>
      this == VerificationStatus.approved;
}