import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/session.dart';
import '../../domain/usecases/create_session.dart';
import '../../domain/usecases/exists_session.dart';
import '../../domain/usecases/get_session.dart';
import '../../domain/usecases/get_sessions.dart';
import '../../domain/usecases/revoke_all_sessions.dart';
import '../../domain/usecases/revoke_session.dart';
import '../../domain/usecases/update_session.dart';
import '../states/session_state.dart';

final class SessionController extends StateNotifier<SessionState> {
  SessionController({
    required this._getSessions,
    required this._getSession,
    required this._createSession,
    required this._updateSession,
    required this._revokeSession,
    required this._revokeAllSessions,
    required this._existsSession,
  }) : super(const SessionState());

  final GetSessionsUseCase _getSessions;
  final GetSessionUseCase _getSession;
  final CreateSessionUseCase _createSession;
  final UpdateSessionUseCase _updateSession;
  final RevokeSessionUseCase _revokeSession;
  final RevokeAllSessionsUseCase _revokeAllSessions;
  final ExistsSessionUseCase _existsSession;

  Future<void> loadSessions({
    required String ownerId,
  }) async {
    state = state.copyWith(isLoading: true);

    final sessions = await _getSessions(
      ownerId: ownerId,
    );

    state = state.copyWith(
      isLoading: false,
      sessions: sessions,
    );
  }

  Future<Session?> loadSession({
    required String sessionId,
  }) {
    return _getSession(
      sessionId: sessionId,
    );
  }

  Future<void> create({
    required Session session,
  }) {
    return _createSession(
      session: session,
    );
  }

  Future<void> update({
    required Session session,
  }) {
    return _updateSession(
      session: session,
    );
  }

  Future<void> revoke({
    required String sessionId,
  }) {
    return _revokeSession(
      sessionId: sessionId,
    );
  }

  Future<void> revokeAll({
    required String ownerId,
  }) {
    return _revokeAllSessions(
      ownerId: ownerId,
    );
  }

  Future<bool> exists({
    required String sessionId,
  }) {
    return _existsSession(
      sessionId: sessionId,
    );
  }
}