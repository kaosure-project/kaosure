import 'organization_legal_profile_model.dart';
import 'organization_member_model.dart';
import 'organization_verification_model.dart';

class OrganizationModel {
  const OrganizationModel({
    this.id,
    required this.name,
    this.code,
    this.description,
    required this.status,
    required this.organizationType,
    this.createdAt,
    this.updatedAt,
    this.legalProfile,
    this.member,
    this.verification,
  });

  final String? id;
  final String name;
  final String? code;
  final String? description;
  final String status;
  final String organizationType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final OrganizationLegalProfileModel? legalProfile;
  final OrganizationMemberModel? member;
  final OrganizationVerificationModel? verification;

  factory OrganizationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationModel(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'active',
      organizationType:
          json['organization_type']?.toString() ?? 'company',
      createdAt: _dateTime(json['created_at']),
      updatedAt: _dateTime(json['updated_at']),
      legalProfile: _parseLegalProfile(
        json['legal_profile'],
      ),
      member: _parseMember(
        json['member'],
      ),
      verification: _parseVerification(
        json['verification'],
      ),
    );
  }

  OrganizationModel copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? status,
    String? organizationType,
    DateTime? createdAt,
    DateTime? updatedAt,
    OrganizationLegalProfileModel? legalProfile,
    OrganizationMemberModel? member,
    OrganizationVerificationModel? verification,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      status: status ?? this.status,
      organizationType:
          organizationType ?? this.organizationType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      legalProfile:
          legalProfile ?? this.legalProfile,
      member: member ?? this.member,
      verification:
          verification ?? this.verification,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (code != null) 'code': code,
      if (description != null)
        'description': description,
      'status': status,
      'organization_type': organizationType,
      if (createdAt != null)
        'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null)
        'updated_at': updatedAt!.toIso8601String(),
      if (legalProfile != null)
        'legal_profile': legalProfile!.toJson(),
      if (member != null)
        'member': member!.toJson(),
      if (verification != null)
        'verification': verification!.toJson(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (code != null) 'code': code,
      if (description != null)
        'description': description,
      'status': status,
      'organization_type': organizationType,
    };
  }

  static OrganizationLegalProfileModel?
      _parseLegalProfile(dynamic value) {
    if (value is Map<String, dynamic>) {
      return OrganizationLegalProfileModel.fromJson(
        value,
      );
    }

    return null;
  }

  static OrganizationMemberModel? _parseMember(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return OrganizationMemberModel.fromJson(
        value,
      );
    }

    return null;
  }

  static OrganizationVerificationModel?
      _parseVerification(dynamic value) {
    if (value is Map<String, dynamic>) {
      return OrganizationVerificationModel.fromJson(
        value,
      );
    }

    return null;
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