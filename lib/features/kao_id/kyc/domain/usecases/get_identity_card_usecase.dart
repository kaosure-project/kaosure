import '../entities/identity_card.dart';
import '../repositories/kyc_repository.dart';

final class GetIdentityCardUseCase {
  const GetIdentityCardUseCase(
    this._repository,
  );

  final KycRepository _repository;

  Future<IdentityCard?> call() {
    return _repository.getIdentityCard();
  }
}