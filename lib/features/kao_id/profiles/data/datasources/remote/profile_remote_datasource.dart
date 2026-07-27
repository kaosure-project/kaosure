import '../../models/profile_model.dart';

abstract interface class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile({
    required String profileId,
  });

  Future<void> createProfile({
    required ProfileModel profile,
  });

  Future<void> updateProfile({
    required ProfileModel profile,
  });

  Future<void> deleteProfile({
    required String profileId,
  });

  Future<bool> exists({
    required String profileId,
  });
}