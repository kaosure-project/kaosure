final class IdentityDocument {
  const IdentityDocument({
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
}