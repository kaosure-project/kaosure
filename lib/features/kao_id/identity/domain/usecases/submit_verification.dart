import '../entities/verification.dart';
import '../repositories/identity_repository.dart';

final class SubmitVerification {
  const SubmitVerification(this._repository);

  final IdentityRepository _repository;

  Future<Verification> call() {
    return _repository.submitVerification();
  }
}