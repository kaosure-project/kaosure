import '../entities/session.dart';
import '../repositories/session_repository.dart';

final class UpdateSessionUseCase {
  const UpdateSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<void> call({
    required Session session,
  }) {
    return _repository.updateSession(
      session: session,
    );
  }
}