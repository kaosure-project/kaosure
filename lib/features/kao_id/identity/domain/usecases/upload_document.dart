import '../entities/identity_document.dart';
import '../repositories/identity_repository.dart';

/// Use case สำหรับสร้างหรือบันทึก Identity Document
///
/// การจัดการ Storage และ document_files
/// เป็นความรับผิดชอบของ Data/Infrastructure layer
/// ไม่ควรให้ Domain layer รู้จัก DocumentUploadService
final class UploadDocument {
  const UploadDocument(
    this._repository,
  );

  final IdentityRepository _repository;

  Future<IdentityDocument> call({
    required IdentityDocument document,
  }) {
    return _repository.uploadDocument(
      document: document,
    );
  }
}