import '../entities/session.dart';
import '../repositories/session_repository.dart';

final class GetSessionUseCase {
  const GetSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<Session?> call({
    required String sessionId,
  }) {
    return _repository.getSession(
      sessionId: sessionId,
    );
  }
}