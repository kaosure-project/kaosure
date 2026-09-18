import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../account/application/providers/account_providers.dart';
import '../../../account/domain/entities/profile.dart';

import '../states/dashboard_state.dart';

final class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this._ref)
      : super(DashboardState.initial());

  final Ref _ref;

  Future<void> loadDashboard() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final UserEntity? user = _ref.read(authProvider).value;

      if (user == null) {
        throw Exception('User is not logged in.');
      }

      final Profile profile = await _loadProfile(user.id);

      state = state.copyWith(
        isLoading: false,
        profile: profile,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<Profile> _loadProfile(String profileId) async {
    final getProfile = _ref.read(
      getProfileUseCaseProvider,
    );

    return getProfile(
      profileId: profileId,
    );
  }

  void clear() {
    state = DashboardState.initial();
  }
}