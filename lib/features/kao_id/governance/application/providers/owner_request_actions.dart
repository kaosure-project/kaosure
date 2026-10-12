import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';

final closeAccountActionProvider = Provider<Future<void> Function(String, String)>((ref) =>
  (id, reason) async { await ref.read(supabaseClientProvider).rpc('close_account_r10d',
    params: {'p_request': id, 'p_reason': reason}); });
