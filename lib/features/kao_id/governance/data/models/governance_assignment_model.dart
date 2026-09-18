import '../../domain/entities/governance_assignment.dart';

final class GovernanceAssignmentModel {
  const GovernanceAssignmentModel({
    required this.id,
    required this.kaoId,
    required this.displayName,
    required this.roleCode,
    required this.roleName,
    required this.startsAt,
    required this.expiresAt,
    required this.isActive,
  });

  final String id;
  final String kaoId;
  final String displayName;
  final String roleCode;
  final String roleName;
  final DateTime startsAt;
  final DateTime? expiresAt;
  final bool isActive;

  factory GovernanceAssignmentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return GovernanceAssignmentModel(
      id: json['assignment_id'] as String,
      kaoId: json['kao_id'] as String,
      displayName:
          json['display_name'] as String,
      roleCode: json['role_code'] as String,
      roleName: json['role_name'] as String,
      startsAt: DateTime.parse(
        json['starts_at'] as String,
      ),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(
              json['expires_at'] as String,
            ),
      isActive:
          json['is_active'] as bool? ?? false,
    );
  }

  GovernanceAssignment toEntity() {
    return GovernanceAssignment(
      id: id,
      kaoId: kaoId,
      displayName: displayName,
      roleCode: roleCode,
      roleName: roleName,
      startsAt: startsAt,
      expiresAt: expiresAt,
      isActive: isActive,
    );
  }
}
