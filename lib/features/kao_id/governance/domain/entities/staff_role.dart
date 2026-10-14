/// A permission the Owner can switch on for a role, from `staff_snapshot_r9b().catalogue`.
class StaffPermission {
  const StaffPermission({
    required this.code,
    required this.category,
    required this.name,
    this.description,
    this.dangerous = false,
    this.ownerOnly = false,
  });

  factory StaffPermission.fromJson(Map<dynamic, dynamic> json) => StaffPermission(
    code: json['code'] as String,
    category: json['category'] as String? ?? '',
    name: json['name'] as String? ?? json['code'] as String,
    description: json['description'] as String?,
    dangerous: json['dangerous'] == true,
    ownerOnly: json['owner_only'] == true,
  );

  final String code;
  final String category;
  final String name;
  final String? description;

  /// Staff can use it only from a two-factor session, and it can't be added to a role somebody holds.
  final bool dangerous;

  /// Never granted to a role.
  final bool ownerOnly;
}

/// An admin role and the permission codes it carries, from `staff_snapshot_r9b().roles`.
class StaffRole {
  const StaffRole({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.isSystem = false,
    this.isActive = true,
    this.legacy = false,
    this.holders = 0,
    this.permissions = const {},
  });

  factory StaffRole.fromJson(Map<dynamic, dynamic> json) => StaffRole(
    id: json['id'] as String? ?? json['code'] as String,
    code: json['code'] as String,
    name: json['name'] as String? ?? json['code'] as String,
    description: json['description'] as String?,
    isSystem: json['is_system'] == true,
    isActive: json['is_active'] != false,
    legacy: json['legacy'] == true,
    holders: (json['holders'] as num?)?.toInt() ?? 0,
    permissions: {for (final code in json['permissions'] as List? ?? const []) code as String},
  );

  final String id;
  final String code;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isActive;

  /// A retired system role kept only for the audit trail.
  final bool legacy;
  final int holders;
  final Set<String> permissions;

  bool get editable => !legacy;

  bool get custom => !isSystem;
}

List<StaffRole> staffRolesFrom(Map<String, dynamic>? snapshot) => [
  for (final role in snapshot?['roles'] as List? ?? const []) StaffRole.fromJson(role as Map),
];

List<StaffPermission> staffCatalogueFrom(Map<String, dynamic>? snapshot) => [
  for (final item in snapshot?['catalogue'] as List? ?? const []) StaffPermission.fromJson(item as Map),
];
