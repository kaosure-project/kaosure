import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/profile_providers.dart';
import '../../domain/entities/profile.dart';
import '../states/profile_state.dart';

final class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._ref) : super(ProfileState.initial());

  final Ref _ref;

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

  Future<void> updateProfile({
    required Profile profile,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _ref.read(
        updateProfileUseCaseProvider,
      ).call(
        profile: profile,
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