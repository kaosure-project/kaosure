import '../enums/document_status.dart';
import '../enums/verification_status.dart';

/// Business Policy สำหรับกฎของการยืนยันตัวตน
///
/// Policy มีหน้าที่ตอบว่า "อนุญาตหรือไม่"
/// โดยไม่มีการเปลี่ยนแปลงข้อมูลหรือเรียกใช้งานระบบภายนอก
final class VerificationPolicy {
  const VerificationPolicy();

  /// สามารถเริ่มกระบวนการยืนยันตัวตนได้หรือไม่
  bool canStartVerification({
    required DocumentStatus documentStatus,
    required VerificationStatus verificationStatus,
  }) {
    return documentStatus.canSubmit &&
        verificationStatus == VerificationStatus.notSubmitted;
  }

  /// สามารถส่งตรวจซ้ำได้หรือไม่
  bool canResubmit({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus == VerificationStatus.rejected ||
        verificationStatus ==
            VerificationStatus.additionalInformationRequired;
  }

  /// สามารถตรวจสอบเอกสารได้หรือไม่
  bool canReview({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus == VerificationStatus.submitted;
  }

  /// สามารถอนุมัติได้หรือไม่
  bool canApprove({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus == VerificationStatus.underReview;
  }

  /// สามารถปฏิเสธได้หรือไม่
  bool canReject({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus == VerificationStatus.underReview;
  }

  /// กระบวนการยืนยันเสร็จสมบูรณ์แล้วหรือไม่
  bool isCompleted({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus.isCompleted;
  }
}