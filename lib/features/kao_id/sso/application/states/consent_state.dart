import '../../domain/failures/sso_failure.dart';

enum ConsentPhase { idle, approving, denying, switching, redirecting }

final class ConsentState {
  const ConsentState({this.phase = ConsentPhase.idle, this.failure});

  final ConsentPhase phase;
  final SsoFailureCode? failure;

  bool get busy => phase != ConsentPhase.idle;
}
