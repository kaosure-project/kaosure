import '../entities/bank_verification.dart';
import '../repositories/kyc_repository.dart';

final class GetBankVerificationUseCase {
  const GetBankVerificationUseCase(
    this._repository,
  );

  final KycRepository _repository;

  Future<BankVerification?> call() {
    return _repository.getBankVerification();
  }
}