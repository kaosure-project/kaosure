import '../entities/bank_verification.dart';
import '../entities/kyc_identity_document.dart';
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

  Future<void> submitVerificationRequest({
    required String documentId,
  });

  // ===========================================================================
  // Documents
  // ===========================================================================

  Future<List<KycIdentityDocument>>
      getIdentityDocuments();

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