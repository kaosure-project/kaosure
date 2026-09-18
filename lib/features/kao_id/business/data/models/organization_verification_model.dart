class OrganizationVerificationModel {
  const OrganizationVerificationModel({
    this.id,
    required this.organizationId,
    required this.status,
    required this.legalNameVerified,
    required this.registrationVerified,
    required this.authorizedPersonVerified,
    required this.bankVerified,
    required this.identityScore,
    this.lastVerifiedAt,
    this.lastReviewedBy,
    this.rejectedReason,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String organizationId;

  final String status;

  final bool legalNameVerified;
  final bool registrationVerified;
  final bool authorizedPersonVerified;
  final bool bankVerified;

  final int identityScore;

  final DateTime? lastVerifiedAt;
  final String? lastReviewedBy;
  final String? rejectedReason;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OrganizationVerificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationVerificationModel(
      id: json['id']?.toString(),
      organizationId:
          json['organization_id']?.toString() ?? '',
      status:
          json['status']?.toString() ??
              'not_started',
      legalNameVerified:
          json['legal_name_verified'] == true,
      registrationVerified:
          json['registration_verified'] == true,
      authorizedPersonVerified:
          json['authorized_person_verified'] == true,
      bankVerified:
          json['bank_verified'] == true,
      identityScore:
          _intValue(json['identity_score']),
      lastVerifiedAt:
          _dateTime(json['last_verified_at']),
      lastReviewedBy:
          json['last_reviewed_by']?.toString(),
      rejectedReason:
          json['rejected_reason']?.toString(),
      createdAt:
          _dateTime(json['created_at']),
      updatedAt:
          _dateTime(json['updated_at']),
    );
  }

  OrganizationVerificationModel copyWith({
    String? id,
    String? organizationId,
    String? status,
    bool? legalNameVerified,
    bool? registrationVerified,
    bool? authorizedPersonVerified,
    bool? bankVerified,
    int? identityScore,
    DateTime? lastVerifiedAt,
    String? lastReviewedBy,
    String? rejectedReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizationVerificationModel(
      id: id ?? this.id,
      organizationId:
          organizationId ?? this.organizationId,
      status: status ?? this.status,
      legalNameVerified:
          legalNameVerified ??
              this.legalNameVerified,
      registrationVerified:
          registrationVerified ??
              this.registrationVerified,
      authorizedPersonVerified:
          authorizedPersonVerified ??
              this.authorizedPersonVerified,
      bankVerified:
          bankVerified ?? this.bankVerified,
      identityScore:
          identityScore ?? this.identityScore,
      lastVerifiedAt:
          lastVerifiedAt ?? this.lastVerifiedAt,
      lastReviewedBy:
          lastReviewedBy ?? this.lastReviewedBy,
      rejectedReason:
          rejectedReason ?? this.rejectedReason,
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
      'status': status,
      'legal_name_verified':
          legalNameVerified,
      'registration_verified':
          registrationVerified,
      'authorized_person_verified':
          authorizedPersonVerified,
      'bank_verified':
          bankVerified,
      'identity_score':
          identityScore,
      if (lastVerifiedAt != null)
        'last_verified_at':
            lastVerifiedAt!.toIso8601String(),
      if (lastReviewedBy != null)
        'last_reviewed_by':
            lastReviewedBy,
      if (rejectedReason != null)
        'rejected_reason':
            rejectedReason,
      if (createdAt != null)
        'created_at':
            createdAt!.toIso8601String(),
      if (updatedAt != null)
        'updated_at':
            updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'organization_id': organizationId,
      'status': status,
      'legal_name_verified':
          legalNameVerified,
      'registration_verified':
          registrationVerified,
      'authorized_person_verified':
          authorizedPersonVerified,
      'bank_verified':
          bankVerified,
      'identity_score':
          identityScore,
      if (rejectedReason != null)
        'rejected_reason':
            rejectedReason,
    };
  }

  static int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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