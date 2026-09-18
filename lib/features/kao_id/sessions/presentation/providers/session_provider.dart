import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/session_controller_provider.dart';
import '../../application/states/session_state.dart';

final sessionProvider = Provider<SessionState>((ref) {
  return ref.watch(sessionControllerProvider);
});