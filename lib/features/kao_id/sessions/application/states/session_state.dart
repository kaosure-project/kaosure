import '../../domain/entities/session.dart';

final class SessionState {
  const SessionState({
    this.isLoading = false,
    this.sessions = const <Session>[],
  });

  final bool isLoading;
  final List<Session> sessions;

  SessionState copyWith({
    bool? isLoading,
    List<Session>? sessions,
  }) {
    return SessionState(
      isLoading: isLoading ?? this.isLoading,
      sessions: sessions ?? this.sessions,
    );
  }
}