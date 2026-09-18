import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../core/services/image_picker_service.dart';
import '../../application/providers/account_providers.dart';
import '../../domain/entities/profile.dart';
import '../states/profile_state.dart';

/// Controls the current Kao ID profile.
///
/// Responsibilities:
/// - Load profile
/// - Create profile
/// - Update profile
/// - Delete profile
/// - Manage selected avatar
///
/// Business rules should remain inside use cases / domain layers.
final class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._ref) : super(ProfileState.initial());

  final Ref _ref;

  // ===========================================================================
  // PROFILE
  // ===========================================================================

  /// Loads the profile belonging to the currently authenticated user.
  Future<void> loadCurrentProfile() async {
    final user = _currentUser;

    if (user == null) {
      _setError('User is not signed in.');
      return;
    }

    await loadProfile(profileId: user.id);
  }

  /// Loads a profile by profile ID.
  Future<void> loadProfile({
    required String profileId,
  }) async {
    _setLoading();

    try {
      final profile = await _ref
          .read(getProfileUseCaseProvider)
          .call(profileId: profileId);

      state = state.copyWith(
        profile: profile,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      _setError(error);
    }
  }

  /// Refreshes the currently authenticated user's profile.
  Future<void> refresh() async {
    await loadCurrentProfile();
  }

  /// Creates a new profile.
  Future<void> createProfile({
    required Profile profile,
  }) async {
    _setLoading();

    try {
      await _ref
          .read(createProfileUseCaseProvider)
          .call(profile: profile);

      await loadCurrentProfile();
    } catch (error) {
      _setError(error);
    }
  }

  /// Updates an existing profile.
  ///
  /// If an avatar has been selected, the image is uploaded first.
  /// The resulting avatar URL is then included in the profile update.
  Future<void> updateProfile({
    required Profile profile,
  }) async {
    _setLoading();

    try {
      final user = _requireCurrentUser();

      final updatedProfile = await _prepareProfileUpdate(
        profile: profile,
        userId: user.id,
      );

      await _ref
          .read(updateProfileUseCaseProvider)
          .call(profile: updatedProfile);

      await loadCurrentProfile();

      _clearSelectedAvatar();
    } catch (error) {
      _setError(error);
    }
  }

  /// Deletes a profile.
  Future<void> deleteProfile({
    required String profileId,
  }) async {
    _setLoading();

    try {
      await _ref
          .read(deleteProfileUseCaseProvider)
          .call(profileId: profileId);

      state = ProfileState.initial();
    } catch (error) {
      _setError(error);
    }
  }

  // ===========================================================================
  // AVATAR
  // ===========================================================================

  /// Stores the selected avatar temporarily in controller state.
  ///
  /// The image is uploaded only when [updateProfile] is called.
  void selectAvatar({
    required PickedImage image,
  }) {
    state = state.copyWith(
      selectedAvatarBytes: image.bytes,
      selectedAvatarName: image.fileName,
      selectedAvatarSize: image.fileSize,
      clearError: true,
    );
  }

  /// Removes the currently selected avatar from local controller state.
  void clearSelectedAvatar() {
    _clearSelectedAvatar();
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  User? get _currentUser {
    return Supabase.instance.client.auth.currentUser;
  }

  User _requireCurrentUser() {
    final user = _currentUser;

    if (user == null) {
      throw Exception('User is not signed in.');
    }

    return user;
  }

  Future<Profile> _prepareProfileUpdate({
    required Profile profile,
    required String userId,
  }) async {
    final avatarBytes = state.selectedAvatarBytes;

    if (avatarBytes == null) {
      return profile;
    }

    final avatarUrl = await _ref
        .read(uploadAvatarUseCaseProvider)
        .call(
          userId: userId,
          imageBytes: avatarBytes,
        );

    return profile.copyWith(
      avatarUrl: avatarUrl,
    );
  }

  void _setLoading() {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );
  }

  void _setError(Object error) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: error.toString(),
    );
  }

  void _clearSelectedAvatar() {
    state = state.copyWith(
      clearSelectedAvatar: true,
    );
  }
}