import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/kao_id/auth/application/providers/auth_provider.dart';

export '../features/kao_id/auth/application/providers/auth_dependencies.dart';
export '../features/kao_id/auth/application/providers/auth_provider.dart';

final appAuthProvider = Provider((ref) {
  return ref.watch(authProvider);
});