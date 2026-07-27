import '../entities/session.dart';

abstract interface class SessionRepository {
  Future<List<Session>> getSessions({
    required String ownerId,
  });

  Future<Session?> getSession({
  required String sessionId,
});

  Future<void> createSession({
    required Session session,
  });

  Future<void> updateSession({
    required Session session,
  });

  Future<void> revokeSession({
    required String sessionId,
  });

  Future<void> revokeAllSessions({
    required String ownerId,
  });

  Future<bool> exists({
    required String sessionId,
  });
}