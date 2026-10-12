import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/config/app_config.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(
    this.client,
  );

  final SupabaseClient client;

  UserModel _mapUser(User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['display_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      emailConfirmed: user.emailConfirmedAt != null,
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _mapUser(user);
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw const AuthException(
        'Login failed.',
      );
    }

    return _mapUser(user);
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw const AuthException(
        'Register failed.',
      );
    }

    return _mapUser(user);
  }

  @override
  Future<void> forgotPassword({
    required String email,
  }) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: AppConfig.passwordRecoveryUrl,
    );
  }

  @override
  Future<void> updatePassword({
    required String password,
  }) async {
    final user = client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'Password recovery session is not available.',
      );
    }

    await client.auth.updateUser(
      UserAttributes(
        password: password,
      ),
    );
  }

  @override
  Future<void> reauthenticate() async {
    final session = client.auth.currentSession;

    if (session == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    await client.auth.reauthenticate();
  }

  @override
  Future<void> changePassword({
    required String password,
    required String nonce,
  }) async {
    final session = client.auth.currentSession;

    if (session == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    final trimmedNonce = nonce.trim();

    if (trimmedNonce.isEmpty) {
      throw const AuthException(
        'Reauthentication code is required.',
      );
    }

    await client.auth.updateUser(
      UserAttributes(
        password: password,
        nonce: trimmedNonce,
      ),
    );
  }

  @override
  Future<void> resendEmailVerification() async {
    final user = client.auth.currentUser;

    if (user == null || user.email == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    await client.auth.resend(
      type: OtpType.signup,
      email: user.email!,
    );
  }

  @override
  Future<UserModel?> refreshCurrentUser() async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) {
      return null;
    }
    final user = (await client.auth.getUser()).user;
    if (user == null || user.id != owner || client.auth.currentUser?.id != owner) {
      throw const AuthException('Session changed.');
    }
    return _mapUser(user);
  }

  @override
  Future<void> logout() async {
    await client.auth.signOut();
  }
}