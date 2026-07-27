import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/remote/identity_remote_datasource.dart';
import '../../data/datasources/remote/identity_remote_datasource_impl.dart';
import '../../data/repositories/identity_repository_impl.dart';
import '../../domain/repositories/identity_repository.dart';
import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/get_documents.dart';
import '../../domain/usecases/renew_document.dart';
import '../../domain/usecases/submit_verification.dart';
import '../../domain/usecases/upload_document.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final identityRemoteDataSourceProvider =
    Provider<IdentityRemoteDataSource>(
  (ref) {
    return IdentityRemoteDataSourceImpl(
      supabase: ref.watch(supabaseClientProvider),
    );
  },
);

final identityRepositoryProvider = Provider<IdentityRepository>(
  (ref) {
    return IdentityRepositoryImpl(
      remoteDataSource:
          ref.watch(identityRemoteDataSourceProvider),
    );
  },
);

final uploadDocumentUseCaseProvider =
    Provider<UploadDocumentUseCase>(
  (ref) {
    return UploadDocumentUseCase(
      ref.watch(identityRepositoryProvider),
    );
  },
);

final getDocumentsUseCaseProvider =
    Provider<GetDocumentsUseCase>(
  (ref) {
    return GetDocumentsUseCase(
      ref.watch(identityRepositoryProvider),
    );
  },
);

final submitVerificationUseCaseProvider =
    Provider<SubmitVerificationUseCase>(
  (ref) {
    return SubmitVerificationUseCase(
      ref.watch(identityRepositoryProvider),
    );
  },
);

final renewDocumentUseCaseProvider =
    Provider<RenewDocumentUseCase>(
  (ref) {
    return RenewDocumentUseCase(
      ref.watch(identityRepositoryProvider),
    );
  },
);

final deleteDocumentUseCaseProvider =
    Provider<DeleteDocumentUseCase>(
  (ref) {
    return DeleteDocumentUseCase(
      ref.watch(identityRepositoryProvider),
    );
  },
);