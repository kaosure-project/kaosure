import '../entities/governance_access.dart';
import '../entities/governance_assignment.dart';
import '../entities/governance_role.dart';

abstract interface class GovernanceRepository {
  Future<GovernanceAccess> getAccess();

  Future<List<GovernanceRole>> getRoles();

  Future<List<GovernanceAssignment>> getAssignments();

  Future<void> assignRole({
    required String kaoId,
    required String roleCode,
  });

  Future<void> revokeAssignment(
    String assignmentId,
  );
}
