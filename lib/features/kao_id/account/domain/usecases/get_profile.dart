import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

final class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Profile> call({
    required String profileId,
  }) {
    return _repository.getProfile(
      profileId: profileId,
    );
  }
}