import '../repositories/session_repository.dart';

final class ExistsSessionUseCase {
  const ExistsSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<bool> call({
    required String sessionId,
  }) {
    return _repository.exists(
      sessionId: sessionId,
    );
  }
}