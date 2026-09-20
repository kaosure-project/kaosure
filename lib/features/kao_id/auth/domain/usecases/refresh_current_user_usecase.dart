import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

final class RefreshCurrentUserUseCase {
  const RefreshCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity?> call() {
    return _repository.refreshCurrentUser();
  }
}