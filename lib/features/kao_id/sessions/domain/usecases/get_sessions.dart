import '../entities/session.dart';
import '../repositories/session_repository.dart';

final class GetSessionsUseCase {
  const GetSessionsUseCase(this._repository);

  final SessionRepository _repository;

  Future<List<Session>> call({
    required String ownerId,
  }) {
    return _repository.getSessions(
      ownerId: ownerId,
    );
  }
}