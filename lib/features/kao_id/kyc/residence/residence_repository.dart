import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import '../identity_card/national_id_repository.dart';

class ResidenceDraft {
  const ResidenceDraft({required this.id, required this.owner, required this.number,
    required this.given, required this.family, required this.singleName,
    required this.familyFirst, required this.country, required this.format, required this.noExpiry,
    required this.issued, required this.expiry, required this.front, this.back});
  final String id, owner, number, given, family, country, format;
  final bool singleName, familyFirst, noExpiry;
  final DateTime issued;
  final DateTime? expiry;
  final IdImage front;
  final IdImage? back;
}

class ResidenceRecord {
  ResidenceRecord(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get status => data['status'] as String;
  String? get rejection => data['rejected_reason'] as String?;
  DateTime? get expiry => DateTime.tryParse(data['expiry_date']?.toString() ?? '');
  List<String> get paths => (data['document_files'] as List? ?? [])
      .map((f) => (f as Map<String, dynamic>)['file_path'] as String).toList();
  bool get canResubmit => status == 'rejected' || status == 'expired' || status == 'revoked' ||
      (status == 'approved' && expiry != null && !expiry!.isAfter(DateTime.now().add(const Duration(days: 30))));
}

abstract interface class ResidenceRepository {
  Future<String> owner();
  Future<ResidenceRecord?> latest(String owner);
  Future<bool> hasPendingRequest(String owner);
  Future<ResidenceRecord> submit(ResidenceDraft draft);
  Future<Uint8List> preview(String owner, String path);
}
final residenceRepositoryProvider = Provider<ResidenceRepository>((ref) =>
    SupabaseResidenceRepository(ref.watch(supabaseClientProvider)));

class SupabaseResidenceRepository implements ResidenceRepository {
  SupabaseResidenceRepository(this.client);
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
  Future<ResidenceRecord?> latest(String owner) async {
    await _check(owner);
    final rows = await client.from('identity_documents').select('*,document_files(*)')
        .eq('owner_id', owner).eq('document_type', 'residence_card')
        .isFilter('deleted_at', null).order('created_at', ascending: false).limit(1);
    await _check(owner);
    return rows.isEmpty ? null : ResidenceRecord(rows.first);
  }
  @override
  Future<bool> hasPendingRequest(String owner) async {
    await _check(owner);
    final rows = await client.from('verification_requests').select('id')
        .eq('requested_by', owner).inFilter('status', ['pending', 'under_review']).limit(1);
    await _check(owner);
    return rows.isNotEmpty;
  }
  Future<void> _upload(String owner, String path, Uint8List bytes) async {
    await _check(owner);
    try {
      await client.storage.from(bucket).uploadBinary(path, bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false));
    } catch (_) {
      await _check(owner);
      final saved = await client.storage.from(bucket).download(path);
      if (!listEquals(saved, bytes)) { throw const NationalIdFailure('save'); }
    }
    await _check(owner);
  }
  @override
  Future<ResidenceRecord> submit(ResidenceDraft draft) async {
    await _check(draft.owner);
    final front = '${draft.owner}/residence/${draft.id}/front.jpg';
    final back = draft.format == 'card' ? '${draft.owner}/residence/${draft.id}/back.jpg' : null;
    if (back != null && draft.back == null) { throw const NationalIdFailure('form'); }
    final existing = await client.from('identity_documents').select('id')
        .eq('owner_id', draft.owner).eq('id', draft.id).maybeSingle();
    if (existing == null) {
      await _upload(draft.owner, front, draft.front.bytes);
      if (back != null) { await _upload(draft.owner, back, draft.back!.bytes); }
    }
    await _check(draft.owner);
    String date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      await client.rpc('submit_residence_r8b', params: {
        'p_id': draft.id, 'p_number': draft.number, 'p_given': draft.given,
        'p_family': draft.family, 'p_single': draft.singleName, 'p_family_first': draft.familyFirst,
        'p_country': draft.country, 'p_format': draft.format, 'p_no_expiry': draft.noExpiry,
        'p_issued': date(draft.issued), 'p_expiry': draft.expiry == null ? null : date(draft.expiry!),
        'p_front': front, 'p_back': back,
      });
    } on PostgrestException catch (e) {
      if (e.message == 'review_already_active') { throw const NationalIdFailure('pending'); }
      rethrow;
    }
    await _check(draft.owner);
    final row = await client.from('identity_documents').select('*,document_files(*)')
        .eq('owner_id', draft.owner).eq('id', draft.id).single();
    await _check(draft.owner);
    return ResidenceRecord(row);
  }
  @override
  Future<Uint8List> preview(String owner, String path) async {
    await _check(owner);
    if (!path.startsWith('$owner/residence/')) { throw const NationalIdFailure('file'); }
    final bytes = await client.storage.from(bucket).download(path);
    await _check(owner);
    return bytes;
  }
}
