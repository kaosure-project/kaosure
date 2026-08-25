import 'dart:typed_data';

import '../../domain/entities/profile.dart';

final class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,

    // Avatar Preview
    this.selectedAvatarBytes,
    this.selectedAvatarName,
    this.selectedAvatarSize,
  });

  final Profile? profile;
  final bool isLoading;
  final String? errorMessage;

  /// รูปที่เลือกไว้ แต่ยังไม่ Upload
  final Uint8List? selectedAvatarBytes;

  /// ชื่อไฟล์
  final String? selectedAvatarName;

  /// ขนาดไฟล์ (Byte)
  final int? selectedAvatarSize;

  ProfileState copyWith({
    Profile? profile,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,

    Uint8List? selectedAvatarBytes,
    String? selectedAvatarName,
    int? selectedAvatarSize,

    bool clearSelectedAvatar = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),

      selectedAvatarBytes: clearSelectedAvatar
          ? null
          : (selectedAvatarBytes ?? this.selectedAvatarBytes),

      selectedAvatarName: clearSelectedAvatar
          ? null
          : (selectedAvatarName ?? this.selectedAvatarName),

      selectedAvatarSize: clearSelectedAvatar
          ? null
          : (selectedAvatarSize ?? this.selectedAvatarSize),
    );
  }

  factory ProfileState.initial() {
    return const ProfileState();
  }
}
