import '../repositories/profile_repository.dart';

final class DeleteProfileUseCase {
  const DeleteProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<void> call({
    required String profileId,
  }) {
    return _repository.deleteProfile(
      profileId: profileId,
    );
  }
}