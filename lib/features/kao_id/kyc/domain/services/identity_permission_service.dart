import '../entities/verification.dart';
import '../enums/verification_status.dart';

final class IdentityPermissionService {
  const IdentityPermissionService._();

  /// สามารถเข้าสู่ระบบได้
  static bool canLogin() => true;

  /// แก้ไขโปรไฟล์ได้
  static bool canEditProfile() => true;

  /// ต้องยืนยันอีเมลหรือไม่
  static bool isEmailVerified(
    Verification verification,
  ) {
    return verification.emailVerified;
  }

  /// ต้องยืนยันเบอร์หรือไม่
  static bool isPhoneVerified(
    Verification verification,
  ) {
    return verification.phoneVerified;
  }

  /// อัปโหลดบัตรประชาชนได้
  static bool canUploadIdentityCard() => true;

  /// อัปโหลด Passport ได้
  static bool canUploadPassport() => true;

  /// อัปโหลด Residence Permit ได้
  static bool canUploadResidencePermit() => true;

  /// อัปโหลดบัญชีธนาคารได้
  static bool canUploadBank() => true;

  /// ดูประวัติ KYC ได้
  static bool canViewHistory() => true;

  /// ยืนยันตัวตนเสร็จสมบูรณ์
  static bool isFullyVerified(
    Verification verification,
  ) {
    return verification.verificationStatus ==
        VerificationStatus.approved;
  }

  /// บัตรประชาชนผ่านแล้ว
  static bool hasApprovedIdentityCard(
    Verification verification,
  ) {
    return verification.identityCardVerificationStatus ==
        VerificationStatus.approved;
  }

  /// Passport ผ่านแล้ว
  static bool hasApprovedPassport(
    Verification verification,
  ) {
    return verification.passportVerificationStatus ==
        VerificationStatus.approved;
  }

  /// Residence Permit ผ่านแล้ว
  static bool hasApprovedResidencePermit(
    Verification verification,
  ) {
    return verification.residencePermitVerificationStatus ==
        VerificationStatus.approved;
  }

  /// บัญชีธนาคารผ่านแล้ว
  static bool hasApprovedBank(
    Verification verification,
  ) {
    return verification.bankVerificationStatus ==
        VerificationStatus.approved;
  }
}