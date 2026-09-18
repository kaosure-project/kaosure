import 'package:equatable/equatable.dart';

final class GovernanceAssignment extends Equatable {
  const GovernanceAssignment({
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

  @override
  List<Object?> get props => [
        id,
        kaoId,
        displayName,
        roleCode,
        roleName,
        startsAt,
        expiresAt,
        isActive,
      ];
}
