import '../entities/identity_document.dart';
import '../repositories/identity_repository.dart';

final class GetDocuments {
  const GetDocuments(this._repository);

  final IdentityRepository _repository;

  Future<List<IdentityDocument>> call() {
    return _repository.getDocuments();
  }
}