import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/core/services/document_picker_service.dart';

class NationalIdFailure implements Exception {
  const NationalIdFailure(this.code);
  final String code;
}

class IdImage {
  const IdImage(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

final nationalIdImagePickerProvider = Provider<Future<IdImage?> Function()>((ref) {
  return () async {
    final document = await const DocumentPickerService().pickImage();
    if (document == null) { return null; }
    return IdImage(document.name, await compute(prepareIdImage, document.bytes));
  };
});

/// Decode only JPEG/PNG, cap input, normalize orientation and re-encode JPEG.
/// Processing runs off the UI isolate on native platforms via compute().
Uint8List prepareIdImage(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
    throw const NationalIdFailure('file');
  }
  final jpeg = bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255;
  final png = bytes.length > 8 && listEquals(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  if (!jpeg && !png) { throw const NationalIdFailure('file'); }
  final img.Decoder decoder = jpeg ? img.JpegDecoder() : img.PngDecoder();
  final info = decoder.startDecode(bytes);
  if (info == null || info.width < 100 || info.height < 100 ||
      info.width * info.height > 24000000 || info.numFrames > 1) {
    throw const NationalIdFailure('file');
  }
  final decoded = img.decodeImage(bytes);
  if (decoded == null || decoded.width < 100 || decoded.height < 100 ||
      decoded.width * decoded.height > 24000000) {
    throw const NationalIdFailure('file');
  }
  final oriented = img.bakeOrientation(decoded);
  final output = Uint8List.fromList(img.encodeJpg(oriented, quality: 90));
  if (output.length > 10 * 1024 * 1024) { throw const NationalIdFailure('file'); }
  return output;
}

class NationalIdRecord {
  const NationalIdRecord({required this.id, required this.owner, required this.status,
    required this.paths, this.rejection, this.expiry});
  final String id;
  final String owner;
  final String status;
  final List<String> paths;
  final String? rejection;
  final DateTime? expiry;
  bool get canResubmit => status == 'rejected' || status == 'expired' || status == 'revoked' ||
      (status == 'approved' && expiry != null && !expiry!.isAfter(DateTime.now().add(const Duration(days: 30))));
  factory NationalIdRecord.fromJson(Map<String, dynamic> json) {
    final files = (json['document_files'] as List? ?? []).cast<Map<String, dynamic>>();
    final paths = files.map((f) => f['file_path'] as String).toList()..sort();
    return NationalIdRecord(id: json['id'] as String, owner: json['owner_id'] as String,
      status: json['status'] as String, paths: paths, rejection: json['rejected_reason'] as String?, expiry: DateTime.tryParse(json['expiry_date']?.toString() ?? ''));
  }
}

class NationalIdDraft {
  const NationalIdDraft({required this.id, required this.owner, required this.number,
    required this.fullName, required this.issued, required this.expiry,
    required this.front, required this.back});
  final String id, owner, number, fullName;
  final DateTime issued;
  final DateTime? expiry;
  final IdImage front, back;
}

abstract interface class NationalIdRepository {
  Future<String> owner();
  Future<NationalIdRecord?> latest(String owner);
  Future<NationalIdRecord> submit(NationalIdDraft draft);
  Future<Uint8List> preview(String owner, String path);
}

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
