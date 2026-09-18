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
    this.verifiedAt,
    this.verifiedBy,
    required this.isPrimary,
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
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BankVerificationModel.fromJson(Map<String, dynamic> json) {
    final isVerified = json['is_verified'] as bool? ?? false;

    return BankVerificationModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      bankCode: (json['bank_code'] as String?) ?? '',
      bankName: json['bank_name'] as String,
      accountName: json['account_name'] as String,
      accountNumber: json['account_number'] as String,
      status: isVerified ? 'approved' : 'pending',
      verifiedAt: _parseDate(json['verified_at']),
      verifiedBy: json['verified_by'] as String?,
      isPrimary: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
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
      nameMatchStatus: null,
      nameMatchReason: null,
      verificationMethod: null,
      verifiedAt: verifiedAt,
      verifiedBy: verifiedBy,
      rejectedReason: null,
      isPrimary: isPrimary,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }
}
