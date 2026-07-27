import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/session_repository_provider.dart';

import '../../domain/usecases/create_session.dart';
import '../../domain/usecases/exists_session.dart';
import '../../domain/usecases/get_session.dart';
import '../../domain/usecases/get_sessions.dart';
import '../../domain/usecases/revoke_all_sessions.dart';
import '../../domain/usecases/revoke_session.dart';
import '../../domain/usecases/update_session.dart';

final getSessionsProvider = Provider<GetSessionsUseCase>((ref) {
  return GetSessionsUseCase(
    ref.watch(sessionRepositoryProvider),
  );
});

final getSessionProvider = Provider<GetSessionUseCase>((ref) {
  return GetSessionUseCase(
    ref.watch(sessionRepositoryProvider),
  );
});

final createSessionProvider = Provider<CreateSessionUseCase>((ref) {
  return CreateSessionUseCase(
    ref.watch(sessionRepositoryProvider),
  );
});

final updateSessionProvider = Provider<UpdateSessionUseCase>((ref) {
  return UpdateSessionUseCase(
    ref.watch(sessionRepositoryProvider),
  );
});

final revokeSessionProvider = Provider<RevokeSessionUseCase>((ref) {
  return RevokeSessionUseCase(
    ref.watch(sessionRepositoryProvider),
  );
});

final revokeAllSessionsProvider =
    Provider<RevokeAllSessionsUseCase>((ref) {
  return RevokeAllSessionsUseCase(
    ref.watch(sessionRepositoryProvider),
  );
});

final existsSessionProvider = Provider<ExistsSessionUseCase>((ref) {
  return ExistsSessionUseCase(
    ref.watch(sessionRepositoryProvider),
  );
});