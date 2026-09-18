import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/governance_access_model.dart';
import '../models/governance_assignment_model.dart';
import '../models/governance_role_model.dart';
import 'governance_remote_datasource.dart';

final class SupabaseGovernanceRemoteDataSource
    implements GovernanceRemoteDataSource {
  const SupabaseGovernanceRemoteDataSource(
    this._client,
  );

  final SupabaseClient _client;

  @override
  Future<GovernanceAccessModel> getAccess() async {
    final response =
        await _client.rpc('get_governance_access');

    return GovernanceAccessModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  @override
  Future<List<GovernanceRoleModel>>
      getRoles() async {
    final response = await _client
        .from('admin_roles')
        .select(
          'id, code, name, description, is_system',
        )
        .eq('is_active', true)
        .order('name');

    return response
        .map(
          (row) => GovernanceRoleModel.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  @override
  Future<List<GovernanceAssignmentModel>>
      getAssignments() async {
    final response = await _client.rpc(
      'get_governance_admin_assignments',
    );

    return (response as List)
        .map(
          (row) =>
              GovernanceAssignmentModel.fromJson(
            Map<String, dynamic>.from(
              row as Map,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<void> assignRole({
    required String kaoId,
    required String roleCode,
  }) async {
    await _client.rpc(
      'assign_admin_role',
      params: {
        'p_target_kao_id': kaoId.trim(),
        'p_role_code': roleCode,
        'p_expires_at': null,
      },
    );
  }

  @override
  Future<void> revokeAssignment(
    String assignmentId,
  ) async {
    await _client.rpc(
      'revoke_admin_assignment',
      params: {
        'p_assignment_id': assignmentId,
      },
    );
  }
}
