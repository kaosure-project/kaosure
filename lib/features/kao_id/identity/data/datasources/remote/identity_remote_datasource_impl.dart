import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/identity_document_model.dart';
import 'identity_remote_datasource.dart';

/// Supabase Implementation ของ IdentityRemoteDataSource
final class IdentityRemoteDataSourceImpl
    implements IdentityRemoteDataSource {
  IdentityRemoteDataSourceImpl({
    required SupabaseClient supabase,
  }) : _supabase = supabase;

  final SupabaseClient _supabase;

  static const _table = 'identity_documents';

  @override
  Future<List<IdentityDocumentModel>> getDocuments({
    required String userId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<IdentityDocumentModel?> getDocumentById({
    required String documentId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> createDocument(
    IdentityDocumentModel document,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateDocument(
    IdentityDocumentModel document,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDocument({
    required String documentId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> submitVerification({
    required String documentId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> renewDocument({
    required String documentId,
  }) async {
    throw UnimplementedError();
  }
}