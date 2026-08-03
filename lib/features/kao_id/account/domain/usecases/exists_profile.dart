import '../repositories/profile_repository.dart';

final class ExistsProfileUseCase {
  const ExistsProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<bool> call({
    required String profileId,
  }) {
    return _repository.exists(
      profileId: profileId,
    );
  }
}