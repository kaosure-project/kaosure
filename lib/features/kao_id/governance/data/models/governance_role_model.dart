import '../../domain/entities/governance_role.dart';

final class GovernanceRoleModel {
  const GovernanceRoleModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.isSystem,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final bool isSystem;

  factory GovernanceRoleModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return GovernanceRoleModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description:
          json['description'] as String?,
      isSystem:
          json['is_system'] as bool? ?? false,
    );
  }

  GovernanceRole toEntity() {
    return GovernanceRole(
      id: id,
      code: code,
      name: name,
      description: description,
      isSystem: isSystem,
    );
  }
}
