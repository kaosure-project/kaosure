import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/account_state_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountStateRepositoryProvider = Provider<AccountStateRepository>((ref) =>
  SupabaseAccountStateRepository(ref.watch(supabaseClientProvider)));

class SupabaseAccountStateRepository implements AccountStateRepository {
  SupabaseAccountStateRepository(this.client);
  final SupabaseClient client;
  Future<dynamic> call(String name, Map<String, dynamic> params) async {
    final id = client.auth.currentUser?.id;
    if (id == null) { throw StateError('session'); }
    final result = await client.rpc(name, params: params);
    if (client.auth.currentUser?.id != id) { throw StateError('session'); }
    return result;
  }
  @override
  Future<List<Map<String, dynamic>>> history(String target) async =>
    (await call('account_history_r9f', {'p_target': target}) as List)
      .map((e) => Map<String, dynamic>.from(e as Map)).toList();
  @override
  Future<void> change(String target, String expected, String next, String reason) async {
    await call('set_account_state_r9f', {'p_target': target, 'p_expected': expected,
      'p_next': next, 'p_reason': reason});
  }
}
