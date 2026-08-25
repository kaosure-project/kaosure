import 'dart:typed_data';

import '../../models/profile_model.dart';

abstract interface class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile({required String profileId});

  Future<void> createProfile({required ProfileModel profile});

  Future<void> updateProfile({required ProfileModel profile});

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
