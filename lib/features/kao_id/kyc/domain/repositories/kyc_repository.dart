import '../entities/bank_verification.dart';
import '../entities/identity_card.dart';
import '../entities/passport.dart';
import '../entities/residence_permit.dart';
import '../entities/verification.dart';
import '../entities/verification_history.dart';
import '../entities/verification_request.dart';

abstract interface class KycRepository {
  // ===========================================================================
  // Verification
  // ===========================================================================

  Future<Verification> getVerification();

  // ===========================================================================
  // Verification Request
  // ===========================================================================

  Future<VerificationRequest?>
      getVerificationRequest();

  Future<void> submitVerificationRequest();

  // ===========================================================================
  // Documents
  // ===========================================================================

  Future<IdentityCard?> getIdentityCard();

  Future<Passport?> getPassport();

  Future<ResidencePermit?> getResidencePermit();

  // ===========================================================================
  // Bank Verification
  // ===========================================================================

  Future<BankVerification?> getBankVerification();

  // ===========================================================================
  // Verification History
  // ===========================================================================

  Future<List<VerificationHistory>>
      getVerificationHistory();

  // ===========================================================================
  // Submit Documents
  // ===========================================================================

  Future<void> submitIdentityCard(
    IdentityCard identityCard,
  );

  Future<void> submitPassport(
    Passport passport,
  );

  Future<void> submitResidencePermit(
    ResidencePermit residencePermit,
  );

  Future<void> submitBankVerification(
    BankVerification bankVerification,
  );
}