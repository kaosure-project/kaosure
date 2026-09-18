import '../../domain/entities/identity_document.dart';
import '../../domain/repositories/identity_repository.dart';
import '../datasources/remote/identity_remote_datasource.dart';
import '../mappers/identity_document_mapper.dart';

final class IdentityRepositoryImpl
    implements IdentityRepository {
  const IdentityRepositoryImpl(
    this._remoteDataSource,
  );

  final IdentityRemoteDataSource _remoteDataSource;

  @override
  Future<List<IdentityDocument>> getDocuments() async {
    final documents =
        await _remoteDataSource.getDocuments();

    return documents
        .map((e) => e.toDomain())
        .toList();
  }

  @override
  Future<IdentityDocument?> getDocumentById(
    String documentId,
  ) async {
    final document =
        await _remoteDataSource.getDocumentById(
      documentId,
    );

    return document?.toDomain();
  }

  @override
  Future<IdentityDocument> uploadDocument({
    required IdentityDocument document,
  }) async {
    final result =
        await _remoteDataSource.uploadDocument(
      document: document.toModel(),
    );

    return result.toDomain();
  }

  @override
  Future<IdentityDocument> updateDocument({
    required IdentityDocument document,
  }) async {
    final result =
        await _remoteDataSource.updateDocument(
      document: document.toModel(),
    );

    return result.toDomain();
  }

  @override
  Future<void> deleteDocument(
    String documentId,
  ) {
    return _remoteDataSource.deleteDocument(
      documentId,
    );
  }

  @override
  Future<bool> hasCompletedRequiredDocuments() {
    return _remoteDataSource
        .hasCompletedRequiredDocuments();
  }
}