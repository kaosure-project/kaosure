import '../entities/bank_verification.dart';
import '../entities/identity_card.dart';
import '../entities/passport.dart';
import '../entities/residence_permit.dart';
import '../entities/verification.dart';
import '../entities/verification_history.dart';

abstract interface class KycRepository {
  /// ภาพรวมสถานะ KYC
  Future<Verification> getVerification();

  /// เอกสารแต่ละประเภท
  Future<IdentityCard?> getIdentityCard();

  Future<Passport?> getPassport();

  Future<ResidencePermit?> getResidencePermit();

  /// บัญชีธนาคาร
  Future<BankVerification?> getBankVerification();

  /// ประวัติการยืนยันตัวตน
  Future<List<VerificationHistory>>
      getVerificationHistory();

  /// ส่งเอกสาร
  Future<void> submitIdentityCard(
    IdentityCard identityCard,
  );

  Future<void> submitPassport(
    Passport passport,
  );

  Future<void> submitResidencePermit(
    ResidencePermit residencePermit,
  );

  /// ส่งบัญชีธนาคาร
  Future<void> submitBankVerification(
    BankVerification bankVerification,
  );
}