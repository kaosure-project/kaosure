import 'package:supabase_flutter/supabase_flutter.dart';

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
    await client.auth.refreshSession();

    final user = client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _mapUser(user);
  }

  @override
  Future<void> logout() async {
    await client.auth.signOut();
  }
}