import '../repositories/session_repository.dart';

final class RevokeSessionUseCase {
  const RevokeSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<void> call({
    required String sessionId,
  }) {
    return _repository.revokeSession(
      sessionId: sessionId,
    );
  }
}