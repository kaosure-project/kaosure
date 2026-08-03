import '../../models/identity_document_model.dart';
import '../../models/verification_model.dart';

abstract interface class IdentityRemoteDataSource {
  Future<List<IdentityDocumentModel>> getDocuments();

  Future<IdentityDocumentModel?> getDocumentById(
    String documentId,
  );

  Future<IdentityDocumentModel> uploadDocument({
    required IdentityDocumentModel document,
  });

  Future<IdentityDocumentModel> updateDocument({
    required IdentityDocumentModel document,
  });

  Future<void> deleteDocument(
    String documentId,
  );

  Future<VerificationModel> submitVerification();

  Future<VerificationModel?> getVerification();

  Future<VerificationModel?> refreshVerification();

  Future<void> cancelVerification();

  Future<bool> hasCompletedRequiredDocuments();
}