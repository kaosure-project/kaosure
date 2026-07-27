import '../entities/session.dart';
import '../repositories/session_repository.dart';

final class CreateSessionUseCase {
  const CreateSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<void> call({
    required Session session,
  }) {
    return _repository.createSession(
      session: session,
    );
  }
}