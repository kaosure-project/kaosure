import '../../domain/entities/identity_document.dart';
import '../../domain/repositories/identity_repository.dart';
import '../datasources/remote/identity_remote_datasource.dart';
import '../mappers/identity_document_mapper.dart';
import '../models/identity_document_model.dart';

/// Implementation ของ IdentityRepository
final class IdentityRepositoryImpl implements IdentityRepository {
  const IdentityRepositoryImpl({
    required IdentityRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final IdentityRemoteDataSource _remoteDataSource;

  @override
  Future<List<IdentityDocument>> getDocuments({
    required String userId,
  }) async {
    final models = await _remoteDataSource.getDocuments(
      userId: userId,
    );

    return models
        .map(IdentityDocumentMapper.toEntity)
        .toList();
  }

  @override
  Future<IdentityDocument?> getDocumentById({
    required String documentId,
  }) async {
    final model = await _remoteDataSource.getDocumentById(
      documentId: documentId,
    );

    if (model == null) {
      return null;
    }

    return IdentityDocumentMapper.toEntity(model);
  }

  @override
  Future<void> createDocument(
    IdentityDocument document,
  ) async {
    final IdentityDocumentModel model =
        IdentityDocumentMapper.toModel(document);

    await _remoteDataSource.createDocument(model);
  }

  @override
  Future<void> updateDocument(
    IdentityDocument document,
  ) async {
    final IdentityDocumentModel model =
        IdentityDocumentMapper.toModel(document);

    await _remoteDataSource.updateDocument(model);
  }

  @override
  Future<void> deleteDocument({
    required String documentId,
  }) {
    return _remoteDataSource.deleteDocument(
      documentId: documentId,
    );
  }

  @override
  Future<void> submitVerification({
    required String documentId,
  }) {
    return _remoteDataSource.submitVerification(
      documentId: documentId,
    );
  }

  @override
  Future<void> renewDocument({
    required String documentId,
  }) {
    return _remoteDataSource.renewDocument(
      documentId: documentId,
    );
  }
}