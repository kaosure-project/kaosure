import '../../domain/entities/profile.dart';
import '../models/profile_model.dart';

final class ProfileMapper {
  const ProfileMapper._();

  static Profile toEntity(ProfileModel model) {
    return model.toEntity();
  }

  static ProfileModel toModel(Profile entity) {
    return ProfileModel.fromEntity(entity);
  }
}