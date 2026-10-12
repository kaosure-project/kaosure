import '../repositories/auth_repository.dart';

class ReauthenticateUseCase {
  const ReauthenticateUseCase(
    this.repository,
  );

  final AuthRepository repository;

  Future<void> call() {
    return repository.reauthenticate();
  }
}