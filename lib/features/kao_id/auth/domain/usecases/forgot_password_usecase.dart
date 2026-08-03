import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  const ForgotPasswordUseCase(this.repository);

  Future<void> call({
    required String email,
  }) {
    return repository.forgotPassword(email: email);
  }
}