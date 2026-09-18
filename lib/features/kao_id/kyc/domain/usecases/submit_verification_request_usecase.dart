import '../repositories/kyc_repository.dart';

final class SubmitVerificationRequestUseCase {
  const SubmitVerificationRequestUseCase(
    this._repository,
  );

  final KycRepository _repository;

  Future<void> call() {
    return _repository.submitVerificationRequest();
  }
}