import '../../domain/entities/kyc_identity_document.dart';

final class KycIdentityDocumentModel {
  const KycIdentityDocumentModel({
    required this.id,
    required this.ownerId,
    required this.documentType,
    required this.documentNumber,
    required this.status,
    required this.issuedDate,
    required this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String documentType;
  final String documentNumber;
  final String status;
  final DateTime? issuedDate;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory KycIdentityDocumentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return KycIdentityDocumentModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      documentType:
          json['document_type'] as String,
      documentNumber:
          json['document_number'] as String,
      status: json['status'] as String,
      issuedDate: json['issued_date'] == null
          ? null
          : DateTime.parse(
              json['issued_date'] as String,
            ),
      expiryDate: json['expiry_date'] == null
          ? null
          : DateTime.parse(
              json['expiry_date'] as String,
            ),
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String,
      ),
    );
  }

  KycIdentityDocument toEntity() {
    return KycIdentityDocument(
      id: id,
      ownerId: ownerId,
      documentType: documentType,
      documentNumber: documentNumber,
      status: status,
      issuedDate: issuedDate,
      expiryDate: expiryDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
