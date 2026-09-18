import '../../domain/entities/bank_verification.dart';
import '../../domain/entities/identity_card.dart';
import '../../domain/entities/passport.dart';
import '../../domain/entities/residence_permit.dart';
import '../../domain/entities/kyc_identity_document.dart';
import '../../domain/entities/verification.dart';
import '../../domain/entities/verification_history.dart';
import '../../domain/entities/verification_request.dart';
import '../../domain/repositories/kyc_repository.dart';

import '../datasources/kyc_remote_datasource.dart';

import '../models/bank_verification_model.dart';
import '../models/identity_card_model.dart';
import '../models/passport_model.dart';
import '../models/residence_permit_model.dart';

final class SupabaseKycRepository
    implements KycRepository {
  const SupabaseKycRepository(
    this._remoteDataSource,
  );

  final KycRemoteDataSource
      _remoteDataSource;

  // ===========================================================================
  // Verification
  // ===========================================================================

  @override
  Future<Verification> getVerification() async {
    final model =
        await _remoteDataSource.getVerification();

    return model.toEntity();
  }

  // ===========================================================================
  // Verification Request
  // ===========================================================================

  @override
  Future<VerificationRequest?>
      getVerificationRequest() async {
    final model =
        await _remoteDataSource
            .getVerificationRequest();

    return model?.toEntity();
  }

  @override
  Future<void> submitVerificationRequest({
    required String documentId,
  }) {
    return _remoteDataSource
        .submitVerificationRequest(
      documentId: documentId,
    );
  }

  // ===========================================================================
  // Canonical Identity Documents
  // ===========================================================================

  @override
  Future<List<KycIdentityDocument>>
      getIdentityDocuments() async {
    final models =
        await _remoteDataSource
            .getIdentityDocuments();

    return models
        .map((model) => model.toEntity())
        .toList();
  }

  // ===========================================================================
  // Bank Verification
  // ===========================================================================

  @override
  Future<BankVerification?>
      getBankVerification() async {
    final model =
        await _remoteDataSource
            .getBankVerification();

    return model?.toEntity();
  }

  // ===========================================================================
  // Verification History
  // ===========================================================================

  @override
  Future<List<VerificationHistory>>
      getVerificationHistory() async {
    final models =
        await _remoteDataSource
            .getVerificationHistory();

    return models
        .map(
          (model) => model.toEntity(),
        )
        .toList();
  }

  // ===========================================================================
  // Identity Card
  // ===========================================================================

  @override
  Future<void> submitIdentityCard(
    IdentityCard identityCard,
  ) {
    final model =
        IdentityCardModel.fromEntity(
      identityCard,
    );

    return _remoteDataSource
        .submitIdentityCard(model);
  }

  // ===========================================================================
  // Passport
  // ===========================================================================

  @override
  Future<void> submitPassport(
    Passport passport,
  ) {
    final model =
        PassportModel.fromEntity(
      passport,
    );

    return _remoteDataSource
        .submitPassport(model);
  }

  // ===========================================================================
  // Residence Permit
  // ===========================================================================

  @override
  Future<void> submitResidencePermit(
    ResidencePermit residencePermit,
  ) {
    final model =
        ResidencePermitModel.fromEntity(
      residencePermit,
    );

    return _remoteDataSource
        .submitResidencePermit(model);
  }

  // ===========================================================================
  // Bank Verification
  // ===========================================================================

  @override
  Future<void> submitBankVerification(
    BankVerification bankVerification,
  ) {
    final model =
        BankVerificationModel.fromEntity(
      bankVerification,
    );

    return _remoteDataSource
        .submitBankVerification(model);
  }
}