import '../enums/document_status.dart';
import '../enums/verification_status.dart';

/// Business Policy สำหรับการต่ออายุเอกสาร
///
/// Policy นี้กำหนดเฉพาะกฎทางธุรกิจ
/// ไม่มีการเรียกฐานข้อมูลหรือ API
final class RenewalPolicy {
  const RenewalPolicy();

  /// สามารถต่ออายุเอกสารได้หรือไม่
  bool canRenew({
    required DocumentStatus documentStatus,
    required VerificationStatus verificationStatus,
  }) {
    if (verificationStatus == VerificationStatus.underReview) {
      return false;
    }

    return documentStatus == DocumentStatus.expired ||
        documentStatus == DocumentStatus.approved ||
        documentStatus == DocumentStatus.rejected;
  }

  /// จำเป็นต้องต่ออายุหรือไม่
  bool requiresRenewal({
    required DocumentStatus documentStatus,
  }) {
    return documentStatus == DocumentStatus.expired;
  }

  /// สามารถส่งคำขอต่ออายุใหม่ได้หรือไม่
  bool canResubmitRenewal({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus == VerificationStatus.rejected;
  }

  /// สามารถยกเลิกคำขอต่ออายุได้หรือไม่
  bool canCancelRenewal({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus == VerificationStatus.submitted ||
        verificationStatus == VerificationStatus.underReview;
  }
}