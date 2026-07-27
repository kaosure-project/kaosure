import '../repositories/identity_repository.dart';

/// Use Case สำหรับส่งเอกสารเข้าสู่กระบวนการตรวจสอบ
final class SubmitVerificationUseCase {
  const SubmitVerificationUseCase(this._repository);

  final IdentityRepository _repository;

  /// ส่งเอกสารเข้าสู่การตรวจสอบ
  Future<void> call({
    required String documentId,
  }) {
    return _repository.submitVerification(
      documentId: documentId,
    );
  }
}