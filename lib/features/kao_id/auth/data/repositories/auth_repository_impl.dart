import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
    this.remoteDataSource,
  );

  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<UserEntity?> getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) {
    return remoteDataSource.login(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
  }) {
    return remoteDataSource.register(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> forgotPassword({
    required String email,
  }) {
    return remoteDataSource.forgotPassword(
      email: email,
    );
  }

  @override
  Future<void> updatePassword({
    required String password,
  }) {
    return remoteDataSource.updatePassword(
      password: password,
    );
  }

  @override
  Future<void> reauthenticate() {
    return remoteDataSource.reauthenticate();
  }

  @override
  Future<void> changePassword({
    required String password,
    required String nonce,
  }) {
    return remoteDataSource.changePassword(
      password: password,
      nonce: nonce,
    );
  }

  @override
  Future<void> resendEmailVerification() {
    return remoteDataSource.resendEmailVerification();
  }

  @override
  Future<UserEntity?> refreshCurrentUser() {
    return remoteDataSource.refreshCurrentUser();
  }

  @override
  Future<void> logout() {
    return remoteDataSource.logout();
  }
}