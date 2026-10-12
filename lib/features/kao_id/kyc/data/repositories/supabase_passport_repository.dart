import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/passport.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/passport_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/failures/national_id_failure.dart';

final passportRepositoryProvider = Provider<PassportRepository>((ref) =>
    SupabasePassportRepository(ref.watch(supabaseClientProvider)));

class SupabasePassportRepository implements PassportRepository {
  SupabasePassportRepository(this.client);
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
  Future<PassportRecord?> latest(String owner) async {
    await _check(owner);
    final rows = await client.from('identity_documents').select('*,document_files(*)')
        .eq('owner_id', owner).eq('document_type', 'passport')
        .isFilter('deleted_at', null).order('created_at', ascending: false).limit(1);
    await _check(owner);
    return rows.isEmpty ? null : PassportRecord(rows.first);
  }
  @override
  Future<bool> hasPendingRequest(String owner) async {
    await _check(owner);
    final rows = await client.from('verification_requests').select('id')
        .eq('requested_by', owner).inFilter('status', ['pending', 'under_review']).limit(1);
    await _check(owner);
    return rows.isNotEmpty;
  }
  @override
  Future<PassportRecord> submit(PassportDraft draft) async {
    await _check(draft.owner);
    final path = '${draft.owner}/passport/${draft.id}/data.jpg';
    final existing = await client.from('identity_documents').select('id')
        .eq('owner_id', draft.owner).eq('id', draft.id).maybeSingle();
    if (existing == null) {
      try {
        await client.storage.from(bucket).uploadBinary(path, draft.image.bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false));
      } catch (_) {
        await _check(draft.owner);
        final saved = await client.storage.from(bucket).download(path);
        if (!listEquals(saved, draft.image.bytes)) { throw const NationalIdFailure('save'); }
      }
    }
    await _check(draft.owner);
    String date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      await client.rpc('submit_passport_r8a', params: {
        'p_id': draft.id, 'p_number': draft.number, 'p_given': draft.given,
        'p_family': draft.family, 'p_single': draft.singleName, 'p_family_first': draft.familyFirst,
        'p_country': draft.country, 'p_birth': date(draft.birth), 'p_issued': date(draft.issued),
        'p_expiry': date(draft.expiry), 'p_path': path,
      });
    } on PostgrestException catch (e) {
      if (e.message == 'review_already_active') { throw const NationalIdFailure('pending'); }
      rethrow;
    }
    await _check(draft.owner);
    final row = await client.from('identity_documents').select('*,document_files(*)')
        .eq('owner_id', draft.owner).eq('id', draft.id).single();
    await _check(draft.owner);
    return PassportRecord(row);
  }
  @override
  Future<Uint8List> preview(String owner, String path) async {
    await _check(owner);
    if (!path.startsWith('$owner/passport/')) { throw const NationalIdFailure('file'); }
    final bytes = await client.storage.from(bucket).download(path);
    await _check(owner);
    return bytes;
  }
}
