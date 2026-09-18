import '../../domain/entities/bank_verification.dart';

final class BankVerificationModel {
  const BankVerificationModel({
    required this.id,
    required this.profileId,
    required this.bankCode,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.status,
    this.nameMatchStatus,
    this.nameMatchReason,
    this.verificationMethod,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectedReason,
    this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String profileId;

  final String bankCode;

  final String bankName;

  final String accountName;

  final String accountNumber;

  final String status;

  final String? nameMatchStatus;

  final String? nameMatchReason;

  final String? verificationMethod;

  final DateTime? verifiedAt;

  final String? verifiedBy;

  final String? rejectedReason;

  final bool? isPrimary;

  final DateTime createdAt;

  final DateTime updatedAt;

  factory BankVerificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return BankVerificationModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      bankCode: json['bank_code'] as String,
      bankName: json['bank_name'] as String,
      accountName: json['account_name'] as String,
      accountNumber:
          json['account_number'] as String,
      status: json['status'] as String,
      nameMatchStatus:
          json['name_match_status'] as String?,
      nameMatchReason:
          json['name_match_reason'] as String?,
      verificationMethod:
          json['verification_method'] as String?,
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(
              json['verified_at'] as String,
            ),
      verifiedBy:
          json['verified_by'] as String?,
      rejectedReason:
          json['rejected_reason'] as String?,
      isPrimary:
          json['is_primary'] as bool?,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'bank_code': bankCode,
      'bank_name': bankName,
      'account_name': accountName,
      'account_number': accountNumber,
      'status': status,
      'name_match_status':
          nameMatchStatus,
      'name_match_reason':
          nameMatchReason,
      'verification_method':
          verificationMethod,
      'verified_at':
          verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'rejected_reason':
          rejectedReason,
      'is_primary': isPrimary,
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt.toIso8601String(),
    };
  }

  BankVerification toEntity() {
    return BankVerification(
      id: id,
      profileId: profileId,
      bankCode: bankCode,
      bankName: bankName,
      accountName: accountName,
      accountNumber: accountNumber,
      status: status,
      nameMatchStatus:
          nameMatchStatus,
      nameMatchReason:
          nameMatchReason,
      verificationMethod:
          verificationMethod,
      verifiedAt: verifiedAt,
      verifiedBy: verifiedBy,
      rejectedReason:
          rejectedReason,
      isPrimary: isPrimary,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory BankVerificationModel.fromEntity(
    BankVerification entity,
  ) {
    return BankVerificationModel(
      id: entity.id,
      profileId: entity.profileId,
      bankCode: entity.bankCode,
      bankName: entity.bankName,
      accountName: entity.accountName,
      accountNumber: entity.accountNumber,
      status: entity.status,
      nameMatchStatus:
          entity.nameMatchStatus,
      nameMatchReason:
          entity.nameMatchReason,
      verificationMethod:
          entity.verificationMethod,
      verifiedAt: entity.verifiedAt,
      verifiedBy: entity.verifiedBy,
      rejectedReason:
          entity.rejectedReason,
      isPrimary: entity.isPrimary,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}