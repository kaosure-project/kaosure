import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';

final recoveryDecisionProvider = Provider<Future<void> Function(String, bool, String, bool)>((ref) =>
  (id, approve, reason, confirm) async {
    await ref.read(supabaseClientProvider).rpc('review_recovery_r10e', params: {
      'p_request': id, 'p_approve': approve, 'p_reason': reason, 'p_confirm': confirm});
  });
