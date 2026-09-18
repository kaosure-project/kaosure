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

      AsyncValue<UserEntity?> authState = _ref.read(authProvider);

      while (authState.isLoading) {
        await Future.delayed(
          const Duration(milliseconds: 50),
        );

        authState = _ref.read(authProvider);
      }

      if (authState.hasError) {
        debugPrint('AUTH ERROR: ${authState.error}');

        state = BootstrapStatus.error;
        return state;
      }

      final user = authState.value;

      // ยังไม่ได้เข้าสู่ระบบ
      if (user == null) {
        state = BootstrapStatus.landing;
        return state;
      }

      debugPrint('USER ID: ${user.id}');

      final getProfile = _ref.read(getProfileUseCaseProvider);

      final profile = await getProfile(
        profileId: user.id,
      );

      debugPrint('PROFILE ID: ${profile.id}');
      debugPrint('PROFILE DISPLAY NAME: ${profile.displayName}');

      // Kao ID ไม่ใช้ Username เป็นเงื่อนไขของ Profile
      //
      // Username เป็นข้อมูลของ Service / Marketplace
      // ไม่ใช่ข้อมูลบังคับของ Kao ID
      state = BootstrapStatus.dashboard;

      return state;
    } catch (e, stackTrace) {
      debugPrint('BOOTSTRAP ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      state = BootstrapStatus.error;
      return state;
    }
  }
}