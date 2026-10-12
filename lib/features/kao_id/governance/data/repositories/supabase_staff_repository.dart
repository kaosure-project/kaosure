import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/staff_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) =>
  SupabaseStaffRepository(ref.watch(supabaseClientProvider)));

class SupabaseStaffRepository implements StaffRepository {
  SupabaseStaffRepository(this.client);
  final SupabaseClient client;
  Future<dynamic> _call(String name, [Map<String, dynamic>? params]) async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) { throw StateError('session'); }
    final arguments = {...?params};
    if (name == 'staff_assign_r13a' || name == 'staff_revoke_r13a') {
      arguments['p_expected_user'] = owner;
    }
    final result = await client.rpc(name, params: arguments);
    if (client.auth.currentUser?.id != owner) { throw StateError('session'); }
    return result;
  }
  @override
  Future<Map<String, dynamic>> load() async =>
      Map<String, dynamic>.from(await _call('staff_snapshot_r9b') as Map);
  @override
  Future<void> assign(String target, String role) async {
    await _call('staff_assign_r13a', {'p_target': target, 'p_role': role});
  }
  @override
  Future<void> revoke(String id) async {
    await _call('staff_revoke_r13a', {'p_assignment': id});
  }
}
