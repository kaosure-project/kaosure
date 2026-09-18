import '../../domain/entities/identity_document.dart';
import '../../domain/enums/document_status.dart';
import '../../domain/enums/document_type_enum.dart';
import '../../domain/value_objects/document_number.dart';
import '../../domain/value_objects/expiry_date.dart';
import '../../domain/value_objects/issued_date.dart';

import 'document_file_model.dart';
import 'verification_model.dart';

final class IdentityDocumentModel {
  const IdentityDocumentModel({
    required this.id,
    required this.ownerId,
    required this.documentType,
    required this.documentNumber,
    required this.status,
    required this.files,
    required this.verification,
    required this.createdAt,
    required this.updatedAt,
    this.issuedDate,
    this.expiryDate,
  });

  final String id;
  final String ownerId;

  /// Database เก็บเป็น text
  final DocumentTypeEnum documentType;

  final String documentNumber;

  final DateTime? issuedDate;
  final DateTime? expiryDate;

  final DocumentStatus status;

  final List<DocumentFileModel> files;

  final VerificationModel verification;

  final DateTime createdAt;
  final DateTime updatedAt;

  factory IdentityDocumentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return IdentityDocumentModel(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,

      documentType:
          DocumentTypeEnumExtension.fromValue(
        map['document_type'] as String,
      ),

      documentNumber:
          map['document_number'] as String,

      issuedDate: map['issued_date'] == null
          ? null
          : DateTime.parse(
              map['issued_date'] as String,
            ),

      expiryDate: map['expiry_date'] == null
          ? null
          : DateTime.parse(
              map['expiry_date'] as String,
            ),

      status:
          DocumentStatusExtension.fromValue(
        map['status'] as String,
      ),

      files: ((map['files'] ?? []) as List)
          .map(
            (e) => DocumentFileModel.fromMap(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),

      verification: VerificationModel.fromMap(
        (map['verification']
                as Map<String, dynamic>?) ??
            <String, dynamic>{},
      ),

      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),

      updatedAt: DateTime.parse(
        map['updated_at'] as String,
      ),
    );
  }

  factory IdentityDocumentModel.fromEntity(
    IdentityDocument entity,
  ) {
    return IdentityDocumentModel(
      id: entity.id,
      ownerId: entity.ownerId,
      documentType: entity.documentType,
      documentNumber:
          entity.documentNumber.value,
      issuedDate:
          entity.issuedDate?.value,
      expiryDate:
          entity.expiryDate?.value,
      status: entity.status,
      files: entity.files
          .map(DocumentFileModel.fromEntity)
          .toList(),
      verification:
          VerificationModel.fromEntity(
        entity.verification,
      ),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  IdentityDocument toEntity() {
    return IdentityDocument(
      id: id,
      ownerId: ownerId,
      documentType: documentType,
      documentNumber:
          DocumentNumber(documentNumber),
      issuedDate: issuedDate == null
          ? null
          : IssuedDate(issuedDate!),
      expiryDate: expiryDate == null
          ? null
          : ExpiryDate(expiryDate!),
      status: status,
      files: files
          .map((e) => e.toEntity())
          .toList(),
      verification:
          verification.toEntity(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Converts the model to a payload for
  /// the `identity_documents` table.
  ///
  /// `files` belongs to `document_files`
  /// and `verification` belongs to
  /// `verification_requests`.
  ///
  /// They must not be sent to `identity_documents`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'document_type': documentType.value,
      'document_number': documentNumber,
      'issued_date':
          issuedDate?.toIso8601String(),
      'expiry_date':
          expiryDate?.toIso8601String(),
      'status': status.value,
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt.toIso8601String(),
    };
  }
}