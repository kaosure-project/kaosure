import '../entities/passport.dart';
import '../repositories/kyc_repository.dart';

final class SubmitPassportUseCase {
  const SubmitPassportUseCase(
    this._repository,
  );

  final KycRepository _repository;

  Future<void> call(
    Passport passport,
  ) {
    return _repository.submitPassport(
      passport,
    );
  }
}