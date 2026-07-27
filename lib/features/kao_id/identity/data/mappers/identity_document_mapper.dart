import '../../domain/entities/identity_document.dart';
import '../models/identity_document_model.dart';

/// Mapper สำหรับแปลงระหว่าง Domain Entity และ Data Model
final class IdentityDocumentMapper {
  const IdentityDocumentMapper._();

  /// Model -> Entity
  static IdentityDocument toEntity(
    IdentityDocumentModel model,
  ) {
    return IdentityDocument(
      id: model.id,
      ownerId: model.ownerId,
      documentType: model.documentType,
      documentNumber: model.documentNumber,
      issuedDate: model.issuedDate,
      expiryDate: model.expiryDate,
      status: model.status,
      files: model.files,
      verification: model.verification,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  /// Entity -> Model
  static IdentityDocumentModel toModel(
    IdentityDocument entity,
  ) {
    return IdentityDocumentModel(
      id: entity.id,
      ownerId: entity.ownerId,
      documentType: entity.documentType,
      documentNumber: entity.documentNumber,
      issuedDate: entity.issuedDate,
      expiryDate: entity.expiryDate,
      status: entity.status,
      files: entity.files,
      verification: entity.verification,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}