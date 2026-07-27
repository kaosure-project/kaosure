import '../models/session_model.dart';

abstract interface class SessionRemoteDataSource {
  Future<List<SessionModel>> getSessions({
    required String ownerId,
  });

  Future<SessionModel?> getSession({
    required String sessionId,
  });

  Future<void> createSession({
    required SessionModel session,
  });

  Future<void> updateSession({
    required SessionModel session,
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