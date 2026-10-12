import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import '../../../auth/application/providers/auth_provider.dart';

final securityOperationsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authProvider).asData?.value?.id;
  if (user == null) { throw StateError('session'); }
  final client = ref.watch(supabaseClientProvider);
  if (client.auth.currentUser?.id != user) { throw StateError('session'); }
  final data = await client.rpc('security_operations_r14a');
  if (client.auth.currentUser?.id != user) { throw StateError('session'); }
  return Map<String, dynamic>.from(data as Map);
});
