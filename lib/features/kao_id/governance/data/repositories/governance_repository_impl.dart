import '../../domain/entities/governance_access.dart';
import '../../domain/entities/governance_assignment.dart';
import '../../domain/entities/governance_role.dart';
import '../../domain/repositories/governance_repository.dart';
import '../datasources/governance_remote_datasource.dart';

final class GovernanceRepositoryImpl
    implements GovernanceRepository {
  const GovernanceRepositoryImpl(
    this._remoteDataSource,
  );

  final GovernanceRemoteDataSource _remoteDataSource;

  @override
  Future<GovernanceAccess> getAccess() async {
    return (await _remoteDataSource.getAccess())
        .toEntity();
  }

  @override
  Future<List<GovernanceRole>> getRoles() async {
    final models =
        await _remoteDataSource.getRoles();

    return models
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<GovernanceAssignment>>
      getAssignments() async {
    final models =
        await _remoteDataSource.getAssignments();

    return models
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> assignRole({
    required String kaoId,
    required String roleCode,
  }) {
    return _remoteDataSource.assignRole(
      kaoId: kaoId,
      roleCode: roleCode,
    );
  }

  @override
  Future<void> revokeAssignment(
    String assignmentId,
  ) {
    return _remoteDataSource.revokeAssignment(
      assignmentId,
    );
  }
}
