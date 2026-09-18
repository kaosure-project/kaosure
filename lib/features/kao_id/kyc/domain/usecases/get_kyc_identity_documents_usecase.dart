import '../entities/kyc_identity_document.dart';
import '../repositories/kyc_repository.dart';

final class GetKycIdentityDocumentsUseCase {
  const GetKycIdentityDocumentsUseCase(
    this._repository,
  );

  final KycRepository _repository;

  Future<List<KycIdentityDocument>> call() {
    return _repository.getIdentityDocuments();
  }
}
