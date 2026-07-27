import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_remote_datasource.dart';
import '../mappers/session_mapper.dart';

final class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl({
    required SessionRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final SessionRemoteDataSource _remoteDataSource;

  @override
  Future<List<Session>> getSessions({
    required String ownerId,
  }) async {
    final models = await _remoteDataSource.getSessions(
      ownerId: ownerId,
    );

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Session?> getSession({
    required String sessionId,
  }) async {
    final model = await _remoteDataSource.getSession(
      sessionId: sessionId,
    );

    return model?.toEntity();
  }

  @override
  Future<void> createSession({
    required Session session,
  }) {
    return _remoteDataSource.createSession(
      session: session.toModel(),
    );
  }

  @override
  Future<void> updateSession({
    required Session session,
  }) {
    return _remoteDataSource.updateSession(
      session: session.toModel(),
    );
  }

  @override
  Future<void> revokeSession({
    required String sessionId,
  }) {
    return _remoteDataSource.revokeSession(
      sessionId: sessionId,
    );
  }

  @override
  Future<void> revokeAllSessions({
    required String ownerId,
  }) {
    return _remoteDataSource.revokeAllSessions(
      ownerId: ownerId,
    );
  }

  @override
  Future<bool> exists({
    required String sessionId,
  }) {
    return _remoteDataSource.exists(
      sessionId: sessionId,
    );
  }
}
