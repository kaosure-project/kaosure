import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/identity_document_model.dart';
import 'identity_remote_datasource.dart';

final class IdentityRemoteDataSourceImpl
    implements IdentityRemoteDataSource {
  IdentityRemoteDataSourceImpl(
    this._supabase,
  );

  final SupabaseClient _supabase;

  static const _documentsTable = 'identity_documents';
  static const _documentFilesTable = 'document_files';

  @override
  Future<List<IdentityDocumentModel>> getDocuments() async {
    final response = await _supabase
        .from(_documentsTable)
        .select('*, document_files(*)')
        .order('created_at', ascending: false);

    return response
        .map(
          (json) => _buildDocumentModel(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }

  @override
  Future<IdentityDocumentModel?> getDocumentById(
    String documentId,
  ) async {
    final response = await _supabase
        .from(_documentsTable)
        .select('*, document_files(*)')
        .eq('id', documentId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _buildDocumentModel(
      Map<String, dynamic>.from(response),
    );
  }

  @override
  Future<IdentityDocumentModel> uploadDocument({
    required IdentityDocumentModel document,
  }) async {
    await _supabase
        .from(_documentsTable)
        .upsert(document.toMap());

    await _syncDocumentFiles(
      documentId: document.id,
      files: document.files,
    );

    final saved = await getDocumentById(document.id);
    if (saved == null) {
      throw StateError('Identity document was not persisted.');
    }
    return saved;
  }

  @override
  Future<IdentityDocumentModel> updateDocument({
    required IdentityDocumentModel document,
  }) async {
    await _supabase
        .from(_documentsTable)
        .update(document.toMap())
        .eq('id', document.id);

    await _syncDocumentFiles(
      documentId: document.id,
      files: document.files,
    );

    final saved = await getDocumentById(document.id);
    if (saved == null) {
      throw StateError('Identity document was not persisted.');
    }
    return saved;
  }

  @override
  Future<void> deleteDocument(
    String documentId,
  ) async {
    await _supabase
        .from(_documentsTable)
        .delete()
        .eq('id', documentId);
  }

  @override
  Future<bool> hasCompletedRequiredDocuments() async {
    final response = await _supabase
        .from(_documentsTable)
        .select('id');

    return response.isNotEmpty;
  }

  IdentityDocumentModel _buildDocumentModel(
    Map<String, dynamic> documentMap,
  ) {
    final nestedFiles = documentMap.remove('document_files');
    documentMap['files'] = nestedFiles is List ? nestedFiles : const [];
    return IdentityDocumentModel.fromMap(documentMap);
  }

  Future<void> _syncDocumentFiles({
    required String documentId,
    required List<dynamic> files,
  }) async {
    await _supabase
        .from(_documentFilesTable)
        .delete()
        .eq('document_id', documentId);

    if (files.isEmpty) {
      return;
    }

    final rows = files.map<Map<String, dynamic>>(
      (file) {
        final map = file.toMap();

        return {
          'id': map['id'],
          'document_id': documentId,
          'file_path': map['file_path'],
          'file_name': map['file_name'],
          'mime_type': map['mime_type'],
          'file_size': map['file_size'],
          'uploaded_at': map['uploaded_at'],
        };
      },
    ).toList();

    await _supabase
        .from(_documentFilesTable)
        .insert(rows);
  }
}