import '../repositories/auth_repository.dart';

final class ResendEmailVerificationUseCase {
  const ResendEmailVerificationUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() {
    return _repository.resendEmailVerification();
  }
}