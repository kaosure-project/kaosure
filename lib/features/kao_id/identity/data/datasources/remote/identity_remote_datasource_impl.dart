import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/identity_document_model.dart';
import '../../models/verification_model.dart';
import 'identity_remote_datasource.dart';

final class IdentityRemoteDataSourceImpl
    implements IdentityRemoteDataSource {
  IdentityRemoteDataSourceImpl(
    this._supabase,
  );

  final SupabaseClient _supabase;

  static const _documentsTable = 'identity_documents';
  static const _documentFilesTable = 'document_files';
  static const _verificationTable = 'verification_requests';

  @override
  Future<List<IdentityDocumentModel>> getDocuments() async {
    final response = await _supabase
        .from(_documentsTable)
        .select()
        .order('created_at');

    final documents = <IdentityDocumentModel>[];

    for (final json in response) {
      documents.add(
        await _buildDocumentModel(
          Map<String, dynamic>.from(json),
        ),
      );
    }

    return documents;
  }

  @override
  Future<IdentityDocumentModel?> getDocumentById(
    String documentId,
  ) async {
    final response = await _supabase
        .from(_documentsTable)
        .select()
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
    final response = await _supabase
        .from(_documentsTable)
        .upsert(document.toMap())
        .select()
        .single();

    await _syncDocumentFiles(
      documentId: document.id,
      files: document.files,
    );

    return _buildDocumentModel(
      Map<String, dynamic>.from(response),
    );
  }

  @override
  Future<IdentityDocumentModel> updateDocument({
    required IdentityDocumentModel document,
  }) async {
    final response = await _supabase
        .from(_documentsTable)
        .update(document.toMap())
        .eq('id', document.id)
        .select()
        .single();

    await _syncDocumentFiles(
      documentId: document.id,
      files: document.files,
    );

    return _buildDocumentModel(
      Map<String, dynamic>.from(response),
    );
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
  Future<VerificationModel> submitVerification() async {
    final response = await _supabase
        .from(_verificationTable)
        .insert({
          'status': 'submitted',
        })
        .select()
        .single();

    return VerificationModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  @override
  Future<VerificationModel?> getVerification() async {
    final response = await _supabase
        .from(_verificationTable)
        .select()
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return VerificationModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  @override
  Future<VerificationModel?> refreshVerification() {
    return getVerification();
  }

  @override
  Future<void> cancelVerification() async {
    final verification = await getVerification();

    if (verification == null) {
      return;
    }

    await _supabase
        .from(_verificationTable)
        .update({
          'status': 'cancelled',
        })
        .eq('id', verification.id);
  }

  @override
  Future<bool> hasCompletedRequiredDocuments() async {
    final response = await _supabase
        .from(_documentsTable)
        .select('id');

    return response.isNotEmpty;
  }

  Future<IdentityDocumentModel> _buildDocumentModel(
    Map<String, dynamic> documentMap,
  ) async {
    final documentId = documentMap['id'] as String;

    final files = await _getDocumentFiles(
      documentId,
    );

    final verification = await _getDocumentVerification(
      documentId,
    );

    documentMap['files'] = files;
    documentMap['verification'] = verification;

    return IdentityDocumentModel.fromMap(
      documentMap,
    );
  }

  Future<List<Map<String, dynamic>>> _getDocumentFiles(
    String documentId,
  ) async {
    final response = await _supabase
        .from(_documentFilesTable)
        .select()
        .eq('document_id', documentId)
        .order('uploaded_at');

    return response
        .map(
          (json) => Map<String, dynamic>.from(json),
        )
        .toList();
  }

  Future<Map<String, dynamic>?> _getDocumentVerification(
    String documentId,
  ) async {
    final response = await _supabase
        .from(_verificationTable)
        .select()
        .eq('document_id', documentId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
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