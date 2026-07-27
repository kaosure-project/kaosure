/// สถานะของเอกสารยืนยันตัวตน
///
/// ใช้กำหนดวงจรชีวิต (Lifecycle) ของเอกสาร
/// ตั้งแต่ผู้ใช้อัปโหลดจนถึงถูกยกเลิกหรือเก็บถาวร
enum DocumentStatus {
  /// ผู้ใช้สร้างรายการแล้ว แต่ยังไม่ได้อัปโหลดไฟล์
  draft,

  /// อัปโหลดไฟล์เรียบร้อย รอส่งตรวจสอบ
  uploaded,

  /// ส่งตรวจสอบแล้ว กำลังรอเจ้าหน้าที่ตรวจ
  pendingReview,

  /// ผ่านการตรวจสอบแล้ว
  approved,

  /// ไม่ผ่านการตรวจสอบ
  rejected,

  /// เอกสารหมดอายุ
  expired,

  /// ระงับการใช้งานชั่วคราว
  suspended,

  /// เก็บเข้าประวัติ ไม่ใช้งานแล้ว
  archived,
}

/// Extension สำหรับแปลงค่า Enum
extension DocumentStatusExtension on DocumentStatus {
  /// ค่าสำหรับเก็บใน Database
  String get value {
    switch (this) {
      case DocumentStatus.draft:
        return 'draft';

      case DocumentStatus.uploaded:
        return 'uploaded';

      case DocumentStatus.pendingReview:
        return 'pending_review';

      case DocumentStatus.approved:
        return 'approved';

      case DocumentStatus.rejected:
        return 'rejected';

      case DocumentStatus.expired:
        return 'expired';

      case DocumentStatus.suspended:
        return 'suspended';

      case DocumentStatus.archived:
        return 'archived';
    }
  }

  /// ข้อความภาษาไทยสำหรับแสดงผล
  String get label {
    switch (this) {
      case DocumentStatus.draft:
        return 'แบบร่าง';

      case DocumentStatus.uploaded:
        return 'อัปโหลดแล้ว';

      case DocumentStatus.pendingReview:
        return 'กำลังตรวจสอบ';

      case DocumentStatus.approved:
        return 'ผ่านการตรวจสอบ';

      case DocumentStatus.rejected:
        return 'ไม่ผ่านการตรวจสอบ';

      case DocumentStatus.expired:
        return 'หมดอายุ';

      case DocumentStatus.suspended:
        return 'ถูกระงับ';

      case DocumentStatus.archived:
        return 'เก็บถาวร';
    }
  }

  /// ใช้สร้าง Enum จากค่าที่อ่านมาจาก Database
  static DocumentStatus fromValue(String value) {
    switch (value) {
      case 'draft':
        return DocumentStatus.draft;

      case 'uploaded':
        return DocumentStatus.uploaded;

      case 'pending_review':
        return DocumentStatus.pendingReview;

      case 'approved':
        return DocumentStatus.approved;

      case 'rejected':
        return DocumentStatus.rejected;

      case 'expired':
        return DocumentStatus.expired;

      case 'suspended':
        return DocumentStatus.suspended;

      case 'archived':
        return DocumentStatus.archived;

      default:
        throw ArgumentError('Unknown document status: $value');
    }
  }

  /// ตรวจสอบว่าเอกสารยังใช้งานได้หรือไม่
  bool get isActive => this == DocumentStatus.approved;

  /// ตรวจสอบว่ายังสามารถแก้ไขได้หรือไม่
  bool get canEdit =>
      this == DocumentStatus.draft ||
      this == DocumentStatus.uploaded ||
      this == DocumentStatus.rejected;

  /// ตรวจสอบว่าส่งตรวจสอบได้หรือไม่
  bool get canSubmit =>
      this == DocumentStatus.draft ||
      this == DocumentStatus.uploaded ||
      this == DocumentStatus.rejected;

  /// ตรวจสอบว่าต้องต่ออายุหรือไม่
  bool get requiresRenewal => this == DocumentStatus.expired;
}