import '../models/bank_verification_model.dart';
import '../models/identity_card_model.dart';
import '../models/passport_model.dart';
import '../models/residence_permit_model.dart';
import '../models/verification_history_model.dart';
import '../models/verification_model.dart';
import '../models/verification_request_model.dart';

abstract interface class KycRemoteDataSource {
  // ===========================================================================
  // Verification
  // ===========================================================================

  Future<VerificationModel> getVerification();

  // ===========================================================================
  // Verification Request
  // ===========================================================================

  Future<VerificationRequestModel?>
      getVerificationRequest();

  Future<void> submitVerificationRequest();

  // ===========================================================================
  // Documents
  // ===========================================================================

  Future<IdentityCardModel?> getIdentityCard();

  Future<PassportModel?> getPassport();

  Future<ResidencePermitModel?>
      getResidencePermit();

  // ===========================================================================
  // Bank Verification
  // ===========================================================================

  Future<BankVerificationModel?>
      getBankVerification();

  // ===========================================================================
  // Verification History
  // ===========================================================================

  Future<List<VerificationHistoryModel>>
      getVerificationHistory();

  // ===========================================================================
  // Submit Documents
  // ===========================================================================

  Future<void> submitIdentityCard(
    IdentityCardModel model,
  );

  Future<void> submitPassport(
    PassportModel model,
  );

  Future<void> submitResidencePermit(
    ResidencePermitModel model,
  );

  Future<void> submitBankVerification(
    BankVerificationModel model,
  );
}