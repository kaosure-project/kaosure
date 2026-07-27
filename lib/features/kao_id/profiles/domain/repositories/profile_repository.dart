import '../entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile> getProfile({
    required String profileId,
  });

  Future<void> createProfile({
    required Profile profile,
  });

  Future<void> updateProfile({
    required Profile profile,
  });

  Future<void> deleteProfile({
    required String profileId,
  });

  Future<bool> exists({
    required String profileId,
  });
}