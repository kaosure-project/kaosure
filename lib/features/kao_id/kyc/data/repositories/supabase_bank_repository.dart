import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/bank_account.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/bank_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/failures/national_id_failure.dart';

final bankRepositoryProvider = Provider<BankRepository>((ref) =>
    SupabaseBankRepository(ref.watch(supabaseClientProvider)));

class SupabaseBankRepository implements BankRepository {
  SupabaseBankRepository(this.client);
  final SupabaseClient client;
  static const bucket = 'identity-documents';
  @override
  Future<String> owner() async {
    final user = (await client.auth.getUser()).user;
    if (user == null) { throw const NationalIdFailure('session'); }
    return user.id;
  }
  Future<void> _check(String expected) async {
    if (await owner() != expected) { throw const NationalIdFailure('session'); }
  }
  @override
  Future<List<BankRecord>> list(String owner) async {
    await _check(owner);
    final rows = await client.rpc('list_banks_r8c') as List;
    await _check(owner);
    return rows.map((row) => BankRecord(Map<String, dynamic>.from(row as Map))).toList();
  }
  @override
  Future<BankRecord> submit(BankDraft draft) async {
    await _check(draft.owner);
    final path = '${draft.owner}/bank-account/${draft.id}/evidence.jpg';
    try {
      await client.storage.from(bucket).uploadBinary(path, draft.evidence.bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false));
    } catch (uploadError) {
      // A retry after a lost response finds its own earlier upload already in place.
      await _check(draft.owner);
      Uint8List? saved;
      try { saved = await client.storage.from(bucket).download(path); } catch (_) {}
      if (saved == null || !listEquals(saved, draft.evidence.bytes)) {
        throw NationalIdFailure(uploadFailureCode(uploadError));
      }
    }
    await _check(draft.owner);
    try {
      await client.rpc('submit_bank_r8c', params: {
        'p_id': draft.id, 'p_bank': draft.bank, 'p_name': draft.name,
        'p_number': draft.number, 'p_branch': draft.branch,
        'p_type': draft.type, 'p_evidence': path,
      });
    } on PostgrestException catch (e) {
      throw NationalIdFailure(submitFailureCode(e.message));
    }
    final rows = await list(draft.owner);
    return rows.firstWhere((row) => row.id == draft.id);
  }

  /// Maps a failed evidence upload to the reason shown on the bank page.
  static String uploadFailureCode(Object error) {
    if (error is StorageException) {
      final status = error.statusCode ?? '';
      final message = error.message.toLowerCase();
      if (status == '413' || status == '415' || message.contains('size') || message.contains('mime')) {
        return 'file';
      }
      if (status == '401' || status == '403' || message.contains('row-level security') ||
          message.contains('unauthorized') || message.contains('jwt')) {
        return 'upload_denied';
      }
      if (status.startsWith('5')) { return 'upload_network'; }
      return 'upload_denied';
    }
    return 'upload_network';
  }

  /// Maps `submit_bank_r8c` exceptions; anything unrecognised stays a retryable `save`.
  static String submitFailureCode(String message) => switch (message) {
    'bank_review_active' => 'pending',
    'bank_duplicate' => 'duplicate',
    'invalid_bank' => 'invalid',
    'invalid_document_paths' || 'invalid_uploaded_file' => 'evidence_missing',
    'authentication_required' => 'sign_in',
    'inactive_account' => 'inactive',
    'bank_conflict' => 'conflict',
    'private_storage_required' => 'unavailable',
    _ => 'save',
  };
  @override
  Future<Uint8List> preview(String owner, String path) async {
    await _check(owner);
    if (!path.startsWith('$owner/bank-account/')) { throw const NationalIdFailure('file'); }
    final bytes = await client.storage.from(bucket).download(path);
    await _check(owner);
    return bytes;
  }
}
