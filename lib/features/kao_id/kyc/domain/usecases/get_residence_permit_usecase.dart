import '../entities/residence_permit.dart';
import '../repositories/kyc_repository.dart';

final class GetResidencePermitUseCase {
  const GetResidencePermitUseCase(
    this._repository,
  );

  final KycRepository _repository;

  Future<ResidencePermit?> call() {
    return _repository.getResidencePermit();
  }
}