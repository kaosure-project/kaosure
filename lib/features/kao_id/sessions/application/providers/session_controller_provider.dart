import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/session_controller.dart';
import '../states/session_state.dart';
import 'session_usecase_provider.dart';

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController(
    getSessions: ref.watch(getSessionsProvider),
    getSession: ref.watch(getSessionProvider),
    createSession: ref.watch(createSessionProvider),
    updateSession: ref.watch(updateSessionProvider),
    revokeSession: ref.watch(revokeSessionProvider),
    revokeAllSessions: ref.watch(revokeAllSessionsProvider),
    existsSession: ref.watch(existsSessionProvider),
  );
});