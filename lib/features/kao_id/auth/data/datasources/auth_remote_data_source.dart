import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> getCurrentUser();

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String email,
    required String password,
  });

  Future<void> forgotPassword({
    required String email,
  });

  /// Updates the password during the password recovery flow.
  Future<void> updatePassword({
    required String password,
  });

  /// Sends a reauthentication OTP to the signed-in user.
  Future<void> reauthenticate();

  /// Changes the password for an authenticated user
  /// after successful reauthentication.
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String nonce,
  });

  /// Resends the email verification message.
  Future<void> resendEmailVerification();

  /// Reloads the latest authenticated user from Supabase.
  Future<UserModel?> refreshCurrentUser();

  Future<void> logout();
}