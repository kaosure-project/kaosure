import '../repositories/session_repository.dart';

final class RevokeAllSessionsUseCase {
  const RevokeAllSessionsUseCase(this._repository);

  final SessionRepository _repository;

  Future<void> call({
    required String ownerId,
  }) {
    return _repository.revokeAllSessions(
      ownerId: ownerId,
    );
  }
}