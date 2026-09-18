import '../../domain/entities/governance_access.dart';

final class GovernanceAccessModel {
  const GovernanceAccessModel({
    required this.isOwner,
    required this.isAdmin,
    required this.canAccessAdmin,
    required this.canViewAssignments,
    required this.canAssignAdmin,
    required this.canRevokeAdmin,
    required this.roles,
  });

  final bool isOwner;
  final bool isAdmin;
  final bool canAccessAdmin;
  final bool canViewAssignments;
  final bool canAssignAdmin;
  final bool canRevokeAdmin;
  final List<String> roles;

  factory GovernanceAccessModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawRoles =
        json['roles'] as List? ?? const [];

    return GovernanceAccessModel(
      isOwner:
          json['is_owner'] as bool? ?? false,
      isAdmin:
          json['is_admin'] as bool? ?? false,
      canAccessAdmin:
          json['can_access_admin'] as bool? ??
              false,
      canViewAssignments:
          json['can_view_assignments'] as bool? ??
              false,
      canAssignAdmin:
          json['can_assign_admin'] as bool? ??
              false,
      canRevokeAdmin:
          json['can_revoke_admin'] as bool? ??
              false,
      roles: rawRoles
          .map(
            (role) =>
                Map<String, dynamic>.from(
              role as Map,
            )['name'] as String,
          )
          .toList(),
    );
  }

  GovernanceAccess toEntity() {
    return GovernanceAccess(
      isOwner: isOwner,
      isAdmin: isAdmin,
      canAccessAdmin: canAccessAdmin,
      canViewAssignments:
          canViewAssignments,
      canAssignAdmin: canAssignAdmin,
      canRevokeAdmin: canRevokeAdmin,
      roles: roles,
    );
  }
}
