import '../entities/identity_document.dart';
import '../repositories/identity_repository.dart';

final class UploadDocument {
  const UploadDocument(this._repository);

  final IdentityRepository _repository;

  Future<IdentityDocument> call({
    required IdentityDocument document,
  }) {
    return _repository.uploadDocument(
      document: document,
    );
  }
}