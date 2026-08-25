import 'package:equatable/equatable.dart';

final class BankVerification extends Equatable {
  const BankVerification({
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

  /// ชื่อเจ้าของบัญชีธนาคาร
  ///
  /// ต้องนำไปตรวจสอบกับชื่อที่ผ่าน KYC
  final String accountName;

  final String accountNumber;

  /// สถานะการยืนยันบัญชีธนาคาร
  ///
  /// not_started
  /// pending
  /// approved
  /// rejected
  /// manual_review
  /// expired
  final String status;

  /// ผลการเปรียบเทียบชื่อบัญชีธนาคาร
  /// กับชื่อที่ผ่าน KYC
  ///
  /// pending
  /// matched
  /// mismatched
  /// manual_review
  final String? nameMatchStatus;

  /// เหตุผลหรือรายละเอียดของผลการตรวจชื่อ
  final String? nameMatchReason;

  /// วิธีที่ใช้ตรวจสอบบัญชีธนาคาร
  ///
  /// manual
  /// api
  /// ocr
  /// third_party
  final String? verificationMethod;

  /// วันที่และเวลาที่บัญชีได้รับการยืนยัน
  final DateTime? verifiedAt;

  /// ผู้ตรวจสอบหรือระบบที่ยืนยัน
  final String? verifiedBy;

  /// เหตุผลกรณีไม่ผ่านการตรวจสอบ
  final String? rejectedReason;

  /// บัญชีหลักของ Kao ID หรือไม่
  final bool? isPrimary;

  final DateTime createdAt;

  final DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // Bank verification status
  // ---------------------------------------------------------------------------

  bool get isNotStarted =>
      status == 'not_started';

  bool get isPending =>
      status == 'pending';

  bool get isApproved =>
      status == 'approved';

  bool get isRejected =>
      status == 'rejected';

  bool get isManualReview =>
      status == 'manual_review';

  bool get isExpired =>
      status == 'expired';

  // ---------------------------------------------------------------------------
  // KYC name matching
  // ---------------------------------------------------------------------------

  bool get isNameMatchPending =>
      nameMatchStatus == 'pending';

  bool get isNameMatched =>
      nameMatchStatus == 'matched';

  bool get isNameMismatched =>
      nameMatchStatus == 'mismatched';

  bool get requiresManualNameReview =>
      nameMatchStatus == 'manual_review';

  /// บัญชีธนาคารได้รับการยืนยัน
  /// และชื่อบัญชีตรงกับชื่อที่ผ่าน KYC
  bool get isTrusted =>
      isApproved && isNameMatched;

  @override
  List<Object?> get props => [
        id,
        profileId,
        bankCode,
        bankName,
        accountName,
        accountNumber,
        status,
        nameMatchStatus,
        nameMatchReason,
        verificationMethod,
        verifiedAt,
        verifiedBy,
        rejectedReason,
        isPrimary,
        createdAt,
        updatedAt,
      ];

  BankVerification copyWith({
    String? id,
    String? profileId,
    String? bankCode,
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? status,
    String? nameMatchStatus,
    String? nameMatchReason,
    String? verificationMethod,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? rejectedReason,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BankVerification(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      bankCode: bankCode ?? this.bankCode,
      bankName: bankName ?? this.bankName,
      accountName:
          accountName ?? this.accountName,
      accountNumber:
          accountNumber ?? this.accountNumber,
      status:
          status ?? this.status,
      nameMatchStatus:
          nameMatchStatus ??
              this.nameMatchStatus,
      nameMatchReason:
          nameMatchReason ??
              this.nameMatchReason,
      verificationMethod:
          verificationMethod ??
              this.verificationMethod,
      verifiedAt:
          verifiedAt ?? this.verifiedAt,
      verifiedBy:
          verifiedBy ?? this.verifiedBy,
      rejectedReason:
          rejectedReason ??
              this.rejectedReason,
      isPrimary:
          isPrimary ?? this.isPrimary,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}