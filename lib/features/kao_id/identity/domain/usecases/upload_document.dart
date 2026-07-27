import '../entities/identity_document.dart';
import '../repositories/identity_repository.dart';

/// Use Case สำหรับสร้างเอกสารยืนยันตัวตนใหม่
final class UploadDocumentUseCase {
  const UploadDocumentUseCase(this._repository);

  final IdentityRepository _repository;

  /// ดำเนินการสร้างเอกสาร
  Future<void> call(IdentityDocument document) {
    return _repository.createDocument(document);
  }
}