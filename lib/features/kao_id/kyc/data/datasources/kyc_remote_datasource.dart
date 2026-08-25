import '../models/bank_verification_model.dart';
import '../models/identity_card_model.dart';
import '../models/passport_model.dart';
import '../models/residence_permit_model.dart';
import '../models/verification_history_model.dart';
import '../models/verification_model.dart';

abstract interface class KycRemoteDataSource {
  Future<VerificationModel> getVerification();

  Future<IdentityCardModel?> getIdentityCard();

  Future<PassportModel?> getPassport();

  Future<ResidencePermitModel?> getResidencePermit();

  Future<BankVerificationModel?> getBankVerification();

  Future<List<VerificationHistoryModel>>
      getVerificationHistory();

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