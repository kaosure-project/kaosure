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
  static const _verificationTable = 'verification_requests';

  @override
  Future<List<IdentityDocumentModel>> getDocuments() async {
    final response = await _supabase
        .from(_documentsTable)
        .select()
        .order('created_at');

    return response
        .map<IdentityDocumentModel>(
          (json) => IdentityDocumentModel.fromMap(json),
        )
        .toList();
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

    return IdentityDocumentModel.fromMap(response);
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

    return IdentityDocumentModel.fromMap(response);
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

    return IdentityDocumentModel.fromMap(response);
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

    return VerificationModel.fromMap(response);
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

    return VerificationModel.fromMap(response);
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
}