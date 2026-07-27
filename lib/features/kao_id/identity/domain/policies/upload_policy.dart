import '../enums/document_status.dart';
import '../enums/verification_status.dart';

/// Business Policy สำหรับการอัปโหลดเอกสาร
///
/// Policy จะตอบคำถามว่า "อนุญาตหรือไม่"
/// โดยไม่มีการแก้ไขข้อมูลหรือเรียกใช้งานภายนอก
final class UploadPolicy {
  const UploadPolicy();

  /// สามารถอัปโหลดเอกสารใหม่ได้หรือไม่
  bool canUpload({
    required DocumentStatus documentStatus,
    required VerificationStatus verificationStatus,
  }) {
    if (documentStatus == DocumentStatus.archived) {
      return false;
    }

    if (verificationStatus == VerificationStatus.underReview) {
      return false;
    }

    if (verificationStatus == VerificationStatus.approved) {
      return false;
    }

    return true;
  }

  /// สามารถแทนที่ไฟล์เอกสารเดิมได้หรือไม่
  bool canReplace({
    required DocumentStatus documentStatus,
    required VerificationStatus verificationStatus,
  }) {
    return canUpload(
      documentStatus: documentStatus,
      verificationStatus: verificationStatus,
    );
  }

  /// สามารถลบเอกสารได้หรือไม่
  bool canDelete({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus != VerificationStatus.underReview;
  }
}