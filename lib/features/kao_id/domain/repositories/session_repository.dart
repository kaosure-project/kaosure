import '../entities/session_entity.dart';

abstract class SessionRepository {
  Future<SessionEntity> getCurrentSession();

  Future<void> clearSession();
}