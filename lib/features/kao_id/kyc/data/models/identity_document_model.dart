final class IdentityDocumentModel {
  const IdentityDocumentModel({
    required this.id,
    required this.ownerId,
    required this.documentType,
    required this.documentNumber,
    required this.fullName,
    required this.countryCode,
    required this.issuedDate,
    required this.expiryDate,
    required this.status,
    required this.verificationMethod,
    required this.verifiedAt,
    required this.verifiedBy,
    required this.rejectedReason,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;
  final String ownerId;

  final String documentType;
  final String documentNumber;

  final String? fullName;
  final String? countryCode;

  final DateTime? issuedDate;
  final DateTime? expiryDate;

  final String status;

  final String? verificationMethod;

  final DateTime? verifiedAt;

  final String? verifiedBy;

  final String? rejectedReason;

  final DateTime createdAt;

  final DateTime updatedAt;

  final DateTime? deletedAt;

  factory IdentityDocumentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return IdentityDocumentModel(
      id: json['id'],
      ownerId: json['owner_id'],
      documentType: json['document_type'],
      documentNumber: json['document_number'],
      fullName: json['full_name'],
      countryCode: json['country_code'],
      issuedDate: json['issued_date'] == null
          ? null
          : DateTime.parse(json['issued_date']),
      expiryDate: json['expiry_date'] == null
          ? null
          : DateTime.parse(json['expiry_date']),
      status: json['status'],
      verificationMethod: json['verification_method'],
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(json['verified_at']),
      verifiedBy: json['verified_by'],
      rejectedReason: json['rejected_reason'],
      createdAt: DateTime.parse(
        json['created_at'],
      ),
      updatedAt: DateTime.parse(
        json['updated_at'],
      ),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'document_type': documentType,
      'document_number': documentNumber,
      'full_name': fullName,
      'country_code': countryCode,
      'issued_date': issuedDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'status': status,
      'verification_method': verificationMethod,
      'verified_at': verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'rejected_reason': rejectedReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}