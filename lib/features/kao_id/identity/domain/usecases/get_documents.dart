import '../entities/identity_document.dart';
import '../repositories/identity_repository.dart';

/// Use Case สำหรับดึงรายการเอกสารของผู้ใช้
final class GetDocumentsUseCase {
  const GetDocumentsUseCase(this._repository);

  final IdentityRepository _repository;

  /// ดึงเอกสารทั้งหมดของผู้ใช้
  Future<List<IdentityDocument>> call({
    required String userId,
  }) {
    return _repository.getDocuments(
      userId: userId,
    );
  }
}