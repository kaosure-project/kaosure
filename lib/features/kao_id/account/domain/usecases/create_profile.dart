import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

final class CreateProfileUseCase {
  const CreateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<void> call({required Profile profile}) {
    return _repository.createProfile(profile: profile);
  }
}
