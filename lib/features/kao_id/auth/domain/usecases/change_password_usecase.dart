import '../repositories/auth_repository.dart';

class ChangePasswordUseCase {
  const ChangePasswordUseCase(
    this.repository,
  );

  final AuthRepository repository;

  Future<void> call({
    required String password,
    required String nonce,
  }) {
    return repository.changePassword(
      password: password,
      nonce: nonce,
    );
  }
}