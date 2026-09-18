import '../entities/identity_document.dart';

abstract interface class IdentityRepository {
  /// Returns all identity documents of the current user.
  Future<List<IdentityDocument>> getDocuments();

  /// Returns a single identity document.
  Future<IdentityDocument?> getDocumentById(
    String documentId,
  );

  /// Uploads or replaces an identity document.
  Future<IdentityDocument> uploadDocument({
    required IdentityDocument document,
  });

  /// Updates document information.
  Future<IdentityDocument> updateDocument({
    required IdentityDocument document,
  });

  /// Deletes an identity document.
  Future<void> deleteDocument(
    String documentId,
  );


  /// Returns true when every required document
  /// has been uploaded.
  Future<bool> hasCompletedRequiredDocuments();
}