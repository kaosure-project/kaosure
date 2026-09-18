import '../models/governance_access_model.dart';
import '../models/governance_assignment_model.dart';
import '../models/governance_role_model.dart';

abstract interface class GovernanceRemoteDataSource {
  Future<GovernanceAccessModel> getAccess();

  Future<List<GovernanceRoleModel>> getRoles();

  Future<List<GovernanceAssignmentModel>>
      getAssignments();

  Future<void> assignRole({
    required String kaoId,
    required String roleCode,
  });

  Future<void> revokeAssignment(
    String assignmentId,
  );
}
