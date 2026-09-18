import '../models/bank_verification_model.dart';
import '../models/kyc_identity_document_model.dart';
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

  Future<void> submitVerificationRequest({
    required String documentId,
  });

  // ===========================================================================
  // Documents
  // ===========================================================================

  Future<List<KycIdentityDocumentModel>>
      getIdentityDocuments();

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


  Future<void> submitBankVerification(
    BankVerificationModel model,
  );
}