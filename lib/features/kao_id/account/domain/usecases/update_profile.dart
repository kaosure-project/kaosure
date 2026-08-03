import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

final class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<void> call({
    required Profile profile,
  }) {
    return _repository.updateProfile(
      profile: profile,
    );
  }
}