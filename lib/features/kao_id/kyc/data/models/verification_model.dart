import '../../domain/entities/verification.dart';

final class VerificationModel {
  const VerificationModel({
    required this.id,
    required this.profileId,
    required this.accountLevel,
    required this.status,
    required this.emailVerified,
    required this.phoneVerified,
    required this.identityCardStatus,
    required this.passportStatus,
    required this.residencePermitStatus,
    required this.bankStatus,
    required this.identityExpiry,
    required this.passportExpiry,
    required this.residencePermitExpiry,
    required this.identityScore,
    required this.lastVerifiedAt,
    required this.lastReviewedBy,
    required this.rejectedReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String profileId;

  final String accountLevel;

  final String status;

  final bool emailVerified;

  final bool phoneVerified;

  final String identityCardStatus;

  final String passportStatus;

  final String residencePermitStatus;

  final String bankStatus;

  final DateTime? identityExpiry;

  final DateTime? passportExpiry;

  final DateTime? residencePermitExpiry;

  final int identityScore;

  final DateTime? lastVerifiedAt;

  final String? lastReviewedBy;

  final String? rejectedReason;

  final DateTime createdAt;

  final DateTime updatedAt;

  factory VerificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerificationModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      accountLevel: json['account_level'] as String,
      status: json['status'] as String,
      emailVerified:
          json['email_verified'] as bool,
      phoneVerified:
          json['phone_verified'] as bool,
      identityCardStatus:
          json['identity_card_status'] as String,
      passportStatus:
          json['passport_status'] as String,
      residencePermitStatus:
          json['residence_permit_status']
              as String,
      bankStatus:
          json['bank_status'] as String,
      identityExpiry:
          json['identity_expiry'] != null
              ? DateTime.parse(
                  json['identity_expiry']
                      as String,
                )
              : null,
      passportExpiry:
          json['passport_expiry'] != null
              ? DateTime.parse(
                  json['passport_expiry']
                      as String,
                )
              : null,
      residencePermitExpiry:
          json['residence_permit_expiry'] !=
                  null
              ? DateTime.parse(
                  json[
                          'residence_permit_expiry']
                      as String,
                )
              : null,
      identityScore:
          json['identity_score'] as int,
      lastVerifiedAt:
          json['last_verified_at'] != null
              ? DateTime.parse(
                  json['last_verified_at']
                      as String,
                )
              : null,
      lastReviewedBy:
          json['last_reviewed_by'] as String?,
      rejectedReason:
          json['rejected_reason'] as String?,
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
      'account_level': accountLevel,
      'status': status,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'identity_card_status':
          identityCardStatus,
      'passport_status':
          passportStatus,
      'residence_permit_status':
          residencePermitStatus,
      'bank_status': bankStatus,
      'identity_expiry':
          identityExpiry?.toIso8601String(),
      'passport_expiry':
          passportExpiry?.toIso8601String(),
      'residence_permit_expiry':
          residencePermitExpiry
              ?.toIso8601String(),
      'identity_score': identityScore,
      'last_verified_at':
          lastVerifiedAt?.toIso8601String(),
      'last_reviewed_by':
          lastReviewedBy,
      'rejected_reason':
          rejectedReason,
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt.toIso8601String(),
    };
  }

  Verification toEntity() {
    return Verification(
      id: id,
      profileId: profileId,
      accountLevel: accountLevel,
      status: status,
      emailVerified: emailVerified,
      phoneVerified: phoneVerified,
      identityCardStatus:
          identityCardStatus,
      passportStatus: passportStatus,
      residencePermitStatus:
          residencePermitStatus,
      bankStatus: bankStatus,
      identityExpiry: identityExpiry,
      passportExpiry: passportExpiry,
      residencePermitExpiry:
          residencePermitExpiry,
      identityScore: identityScore,
      lastVerifiedAt:
          lastVerifiedAt,
      lastReviewedBy:
          lastReviewedBy,
      rejectedReason:
          rejectedReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory VerificationModel.fromEntity(
    Verification entity,
  ) {
    return VerificationModel(
      id: entity.id,
      profileId: entity.profileId,
      accountLevel:
          entity.accountLevel,
      status: entity.status,
      emailVerified:
          entity.emailVerified,
      phoneVerified:
          entity.phoneVerified,
      identityCardStatus:
          entity.identityCardStatus,
      passportStatus:
          entity.passportStatus,
      residencePermitStatus:
          entity.residencePermitStatus,
      bankStatus:
          entity.bankStatus,
      identityExpiry:
          entity.identityExpiry,
      passportExpiry:
          entity.passportExpiry,
      residencePermitExpiry:
          entity
              .residencePermitExpiry,
      identityScore:
          entity.identityScore,
      lastVerifiedAt:
          entity.lastVerifiedAt,
      lastReviewedBy:
          entity.lastReviewedBy,
      rejectedReason:
          entity.rejectedReason,
      createdAt:
          entity.createdAt,
      updatedAt:
          entity.updatedAt,
    );
  }
}