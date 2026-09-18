class OrganizationMemberModel {
  const OrganizationMemberModel({
    this.id,
    required this.organizationId,
    required this.profileId,
    required this.role,
    required this.status,
    required this.startsAt,
    this.endsAt,
    this.roleId,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String organizationId;
  final String profileId;

  final String role;
  final String status;

  final DateTime startsAt;
  final DateTime? endsAt;
  final String? roleId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OrganizationMemberModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationMemberModel(
      id: json['id']?.toString(),
      organizationId:
          json['organization_id']?.toString() ?? '',
      profileId:
          json['profile_id']?.toString() ?? '',
      role:
          json['role']?.toString() ?? 'member',
      status:
          json['status']?.toString() ?? 'active',
      startsAt:
          _dateTime(json['starts_at']) ??
              DateTime.now(),
      endsAt:
          _dateTime(json['ends_at']),
      roleId:
          json['role_id']?.toString(),
      createdAt:
          _dateTime(json['created_at']),
      updatedAt:
          _dateTime(json['updated_at']),
    );
  }

  OrganizationMemberModel copyWith({
    String? id,
    String? organizationId,
    String? profileId,
    String? role,
    String? status,
    DateTime? startsAt,
    DateTime? endsAt,
    String? roleId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizationMemberModel(
      id: id ?? this.id,
      organizationId:
          organizationId ?? this.organizationId,
      profileId:
          profileId ?? this.profileId,
      role: role ?? this.role,
      status: status ?? this.status,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'organization_id': organizationId,
      'profile_id': profileId,
      'role': role,
      'status': status,
      'starts_at': startsAt.toIso8601String(),
      if (endsAt != null)
        'ends_at': endsAt!.toIso8601String(),
      if (roleId != null)
        'role_id': roleId,
      if (createdAt != null)
        'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null)
        'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'organization_id': organizationId,
      'profile_id': profileId,
      'role': role,
      'status': status,
      'starts_at': startsAt.toIso8601String(),
      if (endsAt != null)
        'ends_at': endsAt!.toIso8601String(),
      if (roleId != null)
        'role_id': roleId,
    };
  }

  static DateTime? _dateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}