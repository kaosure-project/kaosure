import '../repositories/auth_repository.dart';

class UpdatePasswordUseCase {
  const UpdatePasswordUseCase(
    this.repository,
  );

  final AuthRepository repository;

  Future<void> call({
    required String password,
  }) {
    return repository.updatePassword(
      password: password,
    );
  }
}