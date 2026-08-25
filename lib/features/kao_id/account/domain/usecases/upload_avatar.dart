import 'dart:typed_data';

import '../repositories/profile_repository.dart';

final class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repository);

  final ProfileRepository _repository;

  Future<String> call({required String userId, required Uint8List imageBytes}) {
    return _repository.uploadAvatar(userId: userId, imageBytes: imageBytes);
  }
}
