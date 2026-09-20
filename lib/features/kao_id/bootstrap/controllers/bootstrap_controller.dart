import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/application/providers/account_providers.dart';
import '../../auth/application/providers/auth_provider.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../states/bootstrap_state.dart';

final class BootstrapController extends StateNotifier<BootstrapStatus> {
  BootstrapController(this._ref) : super(BootstrapStatus.loading);

  final Ref _ref;

  Future<BootstrapStatus> bootstrap() async {
    try {
      state = BootstrapStatus.loading;

      final authState = await _waitForAuthState();

      if (authState.hasError) {
        debugPrint('AUTH ERROR: ${authState.error}');
        return _setStatus(BootstrapStatus.error);
      }

      final user = authState.value;

      // No authenticated user.
      if (user == null) {
        return _setStatus(BootstrapStatus.landing);
      }

      debugPrint('USER ID: ${user.id}');

      // Registration is enough to enter Kao ID.
      // Email, phone, and KYC verification are capability gates,
      // not application-entry gates.
      final existsProfile = _ref.read(
        existsProfileUseCaseProvider,
      );

      final profileExists = await existsProfile(
        profileId: user.id,
      );

      // Every authenticated account needs its base profile record.
      // Verification is handled separately from profile readiness.
      if (!profileExists) {
        return _setStatus(BootstrapStatus.completeProfile);
      }

      return _setStatus(BootstrapStatus.dashboard);
    } catch (e, stackTrace) {
      debugPrint('BOOTSTRAP ERROR: $e');
      debugPrintStack(
        stackTrace: stackTrace,
      );

      return _setStatus(BootstrapStatus.error);
    }
  }

  Future<AsyncValue<UserEntity?>> _waitForAuthState() async {
    var authState = _ref.read(authProvider);

    while (authState.isLoading) {
      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );

      authState = _ref.read(authProvider);
    }

    return authState;
  }

  BootstrapStatus _setStatus(BootstrapStatus status) {
    state = status;
    return status;
  }
}