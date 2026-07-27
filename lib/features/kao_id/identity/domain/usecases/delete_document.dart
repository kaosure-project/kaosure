import '../repositories/identity_repository.dart';

/// Use Case สำหรับลบเอกสาร
final class DeleteDocumentUseCase {
  const DeleteDocumentUseCase(this._repository);

  final IdentityRepository _repository;

  Future<void> call({
    required String documentId,
  }) {
    return _repository.deleteDocument(
      documentId: documentId,
    );
  }
}