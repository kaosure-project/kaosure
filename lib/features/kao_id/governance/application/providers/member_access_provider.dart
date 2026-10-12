import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/features/kao_id/governance/data/repositories/supabase_member_repository.dart';
import '../../../auth/application/providers/auth_provider.dart';

final memberAccessProvider = FutureProvider.autoDispose<bool>((ref) {
  final owner = ref.watch(authProvider.select((a) => a.asData?.value?.id));
  if (owner == null) { return false; }
  return ref.watch(memberRepositoryProvider).canRead();
});
