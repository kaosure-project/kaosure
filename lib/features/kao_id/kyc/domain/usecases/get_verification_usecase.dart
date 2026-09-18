import '../entities/verification.dart';
import '../repositories/kyc_repository.dart';

final class GetVerificationUseCase {
  const GetVerificationUseCase(
    this._repository,
  );

  final KycRepository _repository;

  Future<Verification> call() {
    return _repository.getVerification();
  }
}