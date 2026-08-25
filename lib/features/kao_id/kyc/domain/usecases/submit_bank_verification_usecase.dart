import '../entities/bank_verification.dart';
import '../repositories/kyc_repository.dart';

final class SubmitBankVerificationUseCase {
  const SubmitBankVerificationUseCase(
    this._repository,
  );

  final KycRepository _repository;

  Future<void> call(
    BankVerification bankVerification,
  ) {
    return _repository.submitBankVerification(
      bankVerification,
    );
  }
}