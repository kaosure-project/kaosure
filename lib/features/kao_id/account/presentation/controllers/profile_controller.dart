import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../core/services/image_picker_service.dart';
import '../../application/providers/account_providers.dart';
import '../../domain/entities/profile.dart';
import '../states/profile_state.dart';

final class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._ref)
      : super(ProfileState.initial());

  final Ref _ref;

  Future<void> loadCurrentProfile() async {
    final currentUser =
        Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      state = state.copyWith(
        errorMessage: 'User is not signed in.',
      );
      return;
    }

    await loadProfile(
      profileId: currentUser.id,
    );
  }

  Future<void> loadProfile({
    required String profileId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final profile = await _ref.read(
        getProfileUseCaseProvider,
      ).call(
        profileId: profileId,
      );

      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadCurrentProfile();
  }

  Future<void> createProfile({
    required Profile profile,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _ref.read(
        createProfileUseCaseProvider,
      ).call(
        profile: profile,
      );

      await loadCurrentProfile();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void selectAvatar({
    required PickedImage image,
  }) {
    state = state.copyWith(
      selectedAvatarBytes: image.bytes,
      selectedAvatarName: image.fileName,
      selectedAvatarSize: image.fileSize,
    );
  }

  void clearSelectedAvatar() {
    state = state.copyWith(
      clearSelectedAvatar: true,
    );
  }

  Future<void> updateProfile({
    required Profile profile,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final currentUser =
          Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('User is not signed in.');
      }

      if (state.selectedAvatarBytes != null) {
        await _ref.read(
          uploadAvatarUseCaseProvider,
        ).call(
          userId: currentUser.id,
          imageBytes: state.selectedAvatarBytes!,
        );
      }

      await _ref.read(
        updateProfileUseCaseProvider,
      ).call(
        profile: profile,
      );

      await loadCurrentProfile();

      state = state.copyWith(
        clearSelectedAvatar: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> deleteProfile({
    required String profileId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _ref.read(
        deleteProfileUseCaseProvider,
      ).call(
        profileId: profileId,
      );

      state = ProfileState.initial();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }
}