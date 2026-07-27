import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../notifiers/auth_notifier.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>(
  (ref) => AuthNotifier(ref),
);