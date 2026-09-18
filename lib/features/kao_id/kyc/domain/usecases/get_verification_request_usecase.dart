import '../entities/verification_request.dart';
import '../repositories/kyc_repository.dart';

final class GetVerificationRequestUseCase {
  const GetVerificationRequestUseCase(
    this._repository,
  );

  final KycRepository _repository;

  Future<VerificationRequest?> call() {
    return _repository.getVerificationRequest();
  }
}