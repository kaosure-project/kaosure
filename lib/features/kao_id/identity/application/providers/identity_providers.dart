import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers.dart';

import '../../data/datasources/remote/identity_remote_datasource.dart';
import '../../data/datasources/remote/identity_remote_datasource_impl.dart';
import '../../data/repositories/identity_repository_impl.dart';

import '../../domain/repositories/identity_repository.dart';

import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/get_documents.dart';
import '../../domain/usecases/upload_document.dart';

/// ---------------------------------------------------------------------------
/// Remote Data Source
/// ---------------------------------------------------------------------------

final identityRemoteDataSourceProvider =
    Provider<IdentityRemoteDataSource>(
  (ref) {
    return IdentityRemoteDataSourceImpl(
      ref.read(supabaseClientProvider),
    );
  },
);

/// ---------------------------------------------------------------------------
/// Repository
/// ---------------------------------------------------------------------------

final identityRepositoryProvider =
    Provider<IdentityRepository>(
  (ref) {
    return IdentityRepositoryImpl(
      ref.read(identityRemoteDataSourceProvider),
    );
  },
);

/// ---------------------------------------------------------------------------
/// Use Cases
/// ---------------------------------------------------------------------------

final getDocumentsProvider =
    Provider<GetDocuments>(
  (ref) {
    return GetDocuments(
      ref.read(identityRepositoryProvider),
    );
  },
);

final uploadDocumentProvider =
    Provider<UploadDocument>(
  (ref) {
    return UploadDocument(
      ref.read(identityRepositoryProvider),
    );
  },
);

final deleteDocumentProvider =
    Provider<DeleteDocument>(
  (ref) {
    return DeleteDocument(
      ref.read(identityRepositoryProvider),
    );
  },
);

final submitVerificationProvider =
    Provider<SubmitVerification>(
  (ref) {
    return SubmitVerification(
      ref.read(identityRepositoryProvider),
    );
  },
);