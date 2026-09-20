import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../providers/auth_dependencies.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadCurrentUser();
  }

  final Ref _ref;

  Future<void> loadCurrentUser() async {
    state = const AsyncValue.loading();

    try {
      final useCase = _ref.read(getCurrentUserUseCaseProvider);
      final user = await useCase();

      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final useCase = _ref.read(loginUseCaseProvider);

      final user = await useCase(
        email: email,
        password: password,
      );

      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      final useCase = _ref.read(registerUseCaseProvider);

      final user = await useCase(
        email: email,
        password: password,
      );

      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    final useCase = _ref.read(forgotPasswordUseCaseProvider);

    await useCase(
      email: email,
    );
  }

  Future<void> resendEmailVerification() async {
    final useCase = _ref.read(
      resendEmailVerificationUseCaseProvider,
    );

    await useCase();
  }

  Future<UserEntity?> refreshCurrentUser() async {
    try {
      final useCase = _ref.read(
        refreshCurrentUserUseCaseProvider,
      );

      final user = await useCase();

      state = AsyncValue.data(user);

      return user;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    final useCase = _ref.read(logoutUseCaseProvider);

    await useCase();

    state = const AsyncValue.data(null);
  }
}