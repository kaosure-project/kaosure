import '../enums/document_status.dart';
import '../enums/verification_status.dart';

/// Domain Service สำหรับจัดการกฎของกระบวนการยืนยันตัวตน
///
/// รับผิดชอบเฉพาะ Business Rules
/// ไม่ติดต่อฐานข้อมูล ไม่เรียก API และไม่ส่ง Notification
final class VerificationService {
  const VerificationService();

  /// สามารถส่งเอกสารเข้าตรวจสอบได้หรือไม่
  bool canSubmit({
    required DocumentStatus documentStatus,
    required VerificationStatus verificationStatus,
  }) {
    if (!documentStatus.canSubmit) {
      return false;
    }

    return verificationStatus == VerificationStatus.notSubmitted ||
        verificationStatus == VerificationStatus.rejected ||
        verificationStatus ==
            VerificationStatus.additionalInformationRequired;
  }

  /// สามารถอนุมัติเอกสารได้หรือไม่
  bool canApprove({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus == VerificationStatus.underReview;
  }

  /// สามารถปฏิเสธเอกสารได้หรือไม่
  bool canReject({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus == VerificationStatus.underReview;
  }

  /// สามารถขอข้อมูลเพิ่มเติมได้หรือไม่
  bool canRequestAdditionalInformation({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus == VerificationStatus.underReview;
  }

  /// สามารถยกเลิกคำขอตรวจสอบได้หรือไม่
  bool canCancel({
    required VerificationStatus verificationStatus,
  }) {
    return verificationStatus == VerificationStatus.submitted ||
        verificationStatus == VerificationStatus.underReview;
  }

  /// การตรวจสอบเสร็จสิ้นแล้วหรือไม่
  bool isCompleted(VerificationStatus status) {
    return status.isCompleted;
  }
}