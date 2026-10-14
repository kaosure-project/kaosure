import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/staff_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) =>
  SupabaseStaffRepository(ref.watch(supabaseClientProvider)));

class SupabaseStaffRepository implements StaffRepository {
  SupabaseStaffRepository(this.client);
  final SupabaseClient client;
  static const _sessionBound = {
    'staff_assign_r13a', 'staff_revoke_r13a', 'staff_role_create_r47', 'staff_role_update_r47',
    'staff_role_permission_r47', 'staff_grant_cancel_r47', 'staff_grant_decide_r47',
  };
  Future<dynamic> _call(String name, [Map<String, dynamic>? params]) async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) { throw StateError('session'); }
    final arguments = {...?params};
    if (_sessionBound.contains(name)) {
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
  @override
  Future<void> createRole(String code, String name, String? description) async {
    await _call('staff_role_create_r47', {'p_code': code, 'p_name': name, 'p_description': description});
  }
  @override
  Future<void> updateRole(String code, String name, String? description, bool active) async {
    await _call('staff_role_update_r47',
      {'p_role': code, 'p_name': name, 'p_description': description, 'p_active': active});
  }
  @override
  Future<void> setPermission(String role, String permission, bool enabled) async {
    await _call('staff_role_permission_r47', {'p_role': role, 'p_permission': permission, 'p_enabled': enabled});
  }
  @override
  Future<void> cancelGrant(String id) async {
    await _call('staff_grant_cancel_r47', {'p_grant': id});
  }
  @override
  Future<void> decideGrant(String id, bool approve, String? reason) async {
    await _call('staff_grant_decide_r47', {'p_grant': id, 'p_approve': approve, 'p_reason': reason});
  }
  @override
  Future<List<Map<String, dynamic>>> grantQueue() async => [
    for (final row in await _call('staff_grant_queue_r47') as List? ?? const []) Map<String, dynamic>.from(row as Map),
  ];
}
