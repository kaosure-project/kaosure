import 'package:equatable/equatable.dart';

import '../enums/verification_status.dart';

final class Verification extends Equatable {
  const Verification({
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

  /// registered
  /// verified
  /// business
  /// organization
  final String accountLevel;

  /// VerificationStatus.value
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

  /// 0-100
  final int identityScore;

  final DateTime? lastVerifiedAt;

  final String? lastReviewedBy;

  final String? rejectedReason;

  final DateTime createdAt;

  final DateTime updatedAt;

  VerificationStatus get verificationStatus =>
      VerificationStatus.fromValue(status);

  VerificationStatus get identityCardVerificationStatus =>
      VerificationStatus.fromValue(
        identityCardStatus,
      );

  VerificationStatus get passportVerificationStatus =>
      VerificationStatus.fromValue(
        passportStatus,
      );

  VerificationStatus get residencePermitVerificationStatus =>
      VerificationStatus.fromValue(
        residencePermitStatus,
      );

  VerificationStatus get bankVerificationStatus =>
      VerificationStatus.fromValue(
        bankStatus,
      );

  bool get isApproved =>
      verificationStatus ==
      VerificationStatus.approved;

  bool get isPending =>
      verificationStatus ==
      VerificationStatus.pending;

  bool get isRejected =>
      verificationStatus ==
      VerificationStatus.rejected;

  bool get isNotStarted =>
      verificationStatus ==
      VerificationStatus.notStarted;

  bool get isExpired =>
      verificationStatus ==
      VerificationStatus.expired;

  @override
  List<Object?> get props => [
        id,
        profileId,
        accountLevel,
        status,
        emailVerified,
        phoneVerified,
        identityCardStatus,
        passportStatus,
        residencePermitStatus,
        bankStatus,
        identityExpiry,
        passportExpiry,
        residencePermitExpiry,
        identityScore,
        lastVerifiedAt,
        lastReviewedBy,
        rejectedReason,
        createdAt,
        updatedAt,
      ];

  Verification copyWith({
    String? id,
    String? profileId,
    String? accountLevel,
    String? status,
    bool? emailVerified,
    bool? phoneVerified,
    String? identityCardStatus,
    String? passportStatus,
    String? residencePermitStatus,
    String? bankStatus,
    DateTime? identityExpiry,
    DateTime? passportExpiry,
    DateTime? residencePermitExpiry,
    int? identityScore,
    DateTime? lastVerifiedAt,
    String? lastReviewedBy,
    String? rejectedReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Verification(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      accountLevel:
          accountLevel ?? this.accountLevel,
      status: status ?? this.status,
      emailVerified:
          emailVerified ?? this.emailVerified,
      phoneVerified:
          phoneVerified ?? this.phoneVerified,
      identityCardStatus:
          identityCardStatus ??
              this.identityCardStatus,
      passportStatus:
          passportStatus ??
              this.passportStatus,
      residencePermitStatus:
          residencePermitStatus ??
              this.residencePermitStatus,
      bankStatus:
          bankStatus ?? this.bankStatus,
      identityExpiry:
          identityExpiry ??
              this.identityExpiry,
      passportExpiry:
          passportExpiry ??
              this.passportExpiry,
      residencePermitExpiry:
          residencePermitExpiry ??
              this.residencePermitExpiry,
      identityScore:
          identityScore ??
              this.identityScore,
      lastVerifiedAt:
          lastVerifiedAt ??
              this.lastVerifiedAt,
      lastReviewedBy:
          lastReviewedBy ??
              this.lastReviewedBy,
      rejectedReason:
          rejectedReason ??
              this.rejectedReason,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}