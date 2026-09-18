class OrganizationLegalProfileModel {
  const OrganizationLegalProfileModel({
    this.id,
    required this.organizationId,
    required this.registrationNumber,
    required this.legalName,
    required this.organizationType,
    required this.registrationCountry,
    required this.registrationStatus,
    required this.verificationStatus,
    this.verifiedAt,
    this.verifiedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String organizationId;

  final String registrationNumber;
  final String legalName;
  final String organizationType;
  final String registrationCountry;
  final String registrationStatus;
  final String verificationStatus;

  final DateTime? verifiedAt;
  final String? verifiedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OrganizationLegalProfileModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationLegalProfileModel(
      id: json['id']?.toString(),
      organizationId:
          json['organization_id']?.toString() ?? '',
      registrationNumber:
          json['registration_number']?.toString() ?? '',
      legalName:
          json['legal_name']?.toString() ?? '',
      organizationType:
          json['organization_type']?.toString() ??
              'company',
      registrationCountry:
          json['registration_country']?.toString() ??
              'TH',
      registrationStatus:
          json['registration_status']?.toString() ??
              'active',
      verificationStatus:
          json['verification_status']?.toString() ??
              'pending',
      verifiedAt:
          _dateTime(json['verified_at']),
      verifiedBy:
          json['verified_by']?.toString(),
      createdAt:
          _dateTime(json['created_at']),
      updatedAt:
          _dateTime(json['updated_at']),
    );
  }

  OrganizationLegalProfileModel copyWith({
    String? id,
    String? organizationId,
    String? registrationNumber,
    String? legalName,
    String? organizationType,
    String? registrationCountry,
    String? registrationStatus,
    String? verificationStatus,
    DateTime? verifiedAt,
    String? verifiedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizationLegalProfileModel(
      id: id ?? this.id,
      organizationId:
          organizationId ?? this.organizationId,
      registrationNumber:
          registrationNumber ?? this.registrationNumber,
      legalName:
          legalName ?? this.legalName,
      organizationType:
          organizationType ?? this.organizationType,
      registrationCountry:
          registrationCountry ?? this.registrationCountry,
      registrationStatus:
          registrationStatus ?? this.registrationStatus,
      verificationStatus:
          verificationStatus ?? this.verificationStatus,
      verifiedAt:
          verifiedAt ?? this.verifiedAt,
      verifiedBy:
          verifiedBy ?? this.verifiedBy,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'organization_id': organizationId,
      'registration_number': registrationNumber,
      'legal_name': legalName,
      'organization_type': organizationType,
      'registration_country': registrationCountry,
      'registration_status': registrationStatus,
      'verification_status': verificationStatus,
      if (verifiedAt != null)
        'verified_at': verifiedAt!.toIso8601String(),
      if (verifiedBy != null)
        'verified_by': verifiedBy,
      if (createdAt != null)
        'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null)
        'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'organization_id': organizationId,
      'registration_number': registrationNumber,
      'legal_name': legalName,
      'organization_type': organizationType,
      'registration_country': registrationCountry,
      'registration_status': registrationStatus,
      'verification_status': verificationStatus,
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