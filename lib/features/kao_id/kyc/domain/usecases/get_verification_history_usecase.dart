import '../entities/verification_history.dart';
import '../repositories/kyc_repository.dart';

final class GetVerificationHistoryUseCase {
  const GetVerificationHistoryUseCase(
    this._repository,
  );

  final KycRepository _repository;

  Future<List<VerificationHistory>> call() {
    return _repository.getVerificationHistory();
  }
}