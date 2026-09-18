import '../repositories/identity_repository.dart';

final class DeleteDocument {
  const DeleteDocument(this._repository);

  final IdentityRepository _repository;

  Future<void> call(
    String documentId,
  ) {
    return _repository.deleteDocument(
      documentId,
    );
  }
}