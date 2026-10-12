import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import '../identity_card/national_id_repository.dart';

class BankDraft {
  const BankDraft({required this.id, required this.owner, required this.bank,
    required this.name, required this.number, required this.branch,
    required this.type, required this.evidence});
  final String id, owner, bank, name, number, branch, type;
  final IdImage evidence;
}
class BankRecord {
  BankRecord(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get status => data['status'] as String? ?? 'unknown';
  bool get pending => status == 'pending' || status == 'manual_review';
  String? get evidence => data['evidence_path'] as String?;
  // Mask again as defense in depth, including old fixture/API responses.
  String get maskedNumber {
    final number = data['account_number'] as String? ?? '';
    return number.length >= 4 ? '•••• ${number.substring(number.length - 4)}' : '••••';
  }
}
abstract interface class BankRepository {
  Future<String> owner();
  Future<List<BankRecord>> list(String owner);
  Future<BankRecord> submit(BankDraft draft);
  Future<Uint8List> preview(String owner, String path);
}
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
    } catch (_) {
      await _check(draft.owner);
      final saved = await client.storage.from(bucket).download(path);
      if (!listEquals(saved, draft.evidence.bytes)) { throw const NationalIdFailure('save'); }
    }
    await _check(draft.owner);
    try {
      await client.rpc('submit_bank_r8c', params: {
        'p_id': draft.id, 'p_bank': draft.bank, 'p_name': draft.name,
        'p_number': draft.number, 'p_branch': draft.branch,
        'p_type': draft.type, 'p_evidence': path,
      });
    } on PostgrestException catch (e) {
      if (e.message == 'bank_review_active') { throw const NationalIdFailure('pending'); }
      if (e.message == 'bank_duplicate') { throw const NationalIdFailure('duplicate'); }
      rethrow;
    }
    final rows = await list(draft.owner);
    return rows.firstWhere((row) => row.id == draft.id);
  }
  @override
  Future<Uint8List> preview(String owner, String path) async {
    await _check(owner);
    if (!path.startsWith('$owner/bank-account/')) { throw const NationalIdFailure('file'); }
    final bytes = await client.storage.from(bucket).download(path);
    await _check(owner);
    return bytes;
  }
}
