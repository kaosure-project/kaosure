import '../../domain/entities/identity_document.dart';
import '../models/identity_document_model.dart';

extension IdentityDocumentModelMapper on IdentityDocumentModel {
  IdentityDocument toDomain() {
    return toEntity();
  }
}

extension IdentityDocumentEntityMapper on IdentityDocument {
  IdentityDocumentModel toModel() {
    return IdentityDocumentModel.fromEntity(this);
  }
}