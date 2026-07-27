import '../repositories/identity_repository.dart';

/// Use Case สำหรับต่ออายุเอกสาร
final class RenewDocumentUseCase {
  const RenewDocumentUseCase(this._repository);

  final IdentityRepository _repository;

  Future<void> call({
    required String documentId,
  }) {
    return _repository.renewDocument(
      documentId: documentId,
    );
  }
}