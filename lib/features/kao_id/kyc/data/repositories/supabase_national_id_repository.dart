import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/national_id.dart';
import 'package:kaosure/features/kao_id/kyc/domain/failures/national_id_failure.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/national_id_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final nationalIdRepositoryProvider = Provider<NationalIdRepository>((ref) =>
  SupabaseNationalIdRepository(ref.watch(supabaseClientProvider)));

class SupabaseNationalIdRepository implements NationalIdRepository {
  SupabaseNationalIdRepository(this.client);
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
  Future<NationalIdRecord?> latest(String owner) async {
    await _check(owner);
    final rows = await client.from('identity_documents').select('*,document_files(*)')
      .eq('owner_id', owner).eq('document_type', 'thai_national_id')
      .isFilter('deleted_at', null).order('created_at', ascending: false).limit(1);
    await _check(owner);
    return rows.isEmpty ? null : NationalIdRecord.fromJson(rows.first);
  }
  Future<void> _upload(String path, Uint8List bytes) async {
    try {
      await client.storage.from(bucket).uploadBinary(path, bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false));
    } catch (_) {
      // Retry is safe only if the existing immutable object contains identical bytes.
      final saved = await client.storage.from(bucket).download(path);
      if (!listEquals(saved, bytes)) { throw const NationalIdFailure('save'); }
    }
  }
  @override
  Future<NationalIdRecord> submit(NationalIdDraft draft) async {
    await _check(draft.owner);
    final prefix = '${draft.owner}/national-id/${draft.id}';
    final front = '$prefix/front.jpg', back = '$prefix/back.jpg';
    final existing = await client.from('identity_documents').select('id')
      .eq('owner_id', draft.owner).eq('id', draft.id).maybeSingle();
    if (existing == null) {
      await _upload(front, draft.front.bytes);
      await _check(draft.owner);
      await _upload(back, draft.back.bytes);
    }
    await _check(draft.owner);
    String date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await client.rpc('submit_national_id_r7a', params: {
      'p_id': draft.id, 'p_number': draft.number, 'p_full_name': draft.fullName,
      'p_issued': date(draft.issued), 'p_expiry': draft.expiry == null ? null : date(draft.expiry!),
      'p_front': front, 'p_back': back,
    });
    await _check(draft.owner);
    final row = await client.from('identity_documents').select('*,document_files(*)')
      .eq('owner_id', draft.owner).eq('id', draft.id).single();
    return NationalIdRecord.fromJson(row);
  }
  @override
  Future<Uint8List> preview(String owner, String path) async {
    await _check(owner);
    if (!path.startsWith('$owner/national-id/')) { throw const NationalIdFailure('file'); }
    final bytes = await client.storage.from(bucket).download(path);
    await _check(owner);
    return bytes;
  }
}
