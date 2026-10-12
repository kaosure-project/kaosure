import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();

  Future<UserEntity> login({
    required String email,
    required String password,
  });

  Future<UserEntity> register({
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
    required String password,
    required String nonce,
  });

  /// Resends the email verification message.
  Future<void> resendEmailVerification();

  /// Reloads the latest user and verification state
  /// from the authentication provider.
  Future<UserEntity?> refreshCurrentUser();

  Future<void> logout();
}