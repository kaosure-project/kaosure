import 'dart:typed_data';

import '../entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile> getProfile({required String profileId});

  Future<void> createProfile({required Profile profile});

  Future<void> updateProfile({required Profile profile});

  Future<void> deleteProfile({required String profileId});

  Future<bool> exists({required String profileId});

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
  });

  Future<bool> isUsernameAvailable({required String username});

  Future<void> setUsername({
    required String profileId,
    required String username,
  });
}
