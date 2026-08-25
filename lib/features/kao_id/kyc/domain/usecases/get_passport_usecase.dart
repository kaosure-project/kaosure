import '../entities/passport.dart';
import '../repositories/kyc_repository.dart';

final class GetPassportUseCase {
  const GetPassportUseCase(
    this._repository,
  );

  final KycRepository _repository;

  Future<Passport?> call() {
    return _repository.getPassport();
  }
}