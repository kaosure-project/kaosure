import 'package:equatable/equatable.dart';

final class GovernanceAccess extends Equatable {
  const GovernanceAccess({
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

  @override
  List<Object?> get props => [
        isOwner,
        isAdmin,
        canAccessAdmin,
        canViewAssignments,
        canAssignAdmin,
        canRevokeAdmin,
        roles,
      ];
}
