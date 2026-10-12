import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/account/domain/repositories/recovery_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../kyc/identity_card/national_id_repository.dart';

final recoveryRepositoryProvider = Provider<RecoveryRepository>((ref) =>
  SupabaseRecoveryRepository(ref.read(supabaseClientProvider)));

class SupabaseRecoveryRepository implements RecoveryRepository {
  SupabaseRecoveryRepository(this.client);
  final SupabaseClient client;
  @override
  Future<List<Map<String, dynamic>>> snapshot() async =>
    (await client.rpc('recovery_snapshot_r10e') as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
  @override
  Future<Map<String, dynamic>> prepare(String request, String type) async =>
    Map<String, dynamic>.from(await client.rpc('prepare_recovery_r10e', params: {
      'p_lifecycle': request, 'p_type': type}) as Map);
  @override
  Future<void> submit(Map<String, dynamic> draft, Map<String, dynamic> data, List<IdImage> files) async {
    final user = client.auth.currentUser?.id;
    if (user == null) { throw StateError('session'); }
    final paths = (draft['paths'] as List).cast<String>();
    if (files.length != paths.length || paths.any((p) => !p.startsWith('$user/'))) { throw StateError('files'); }
    for (var i = 0; i < paths.length; i++) {
      if (client.auth.currentUser?.id != user) { throw StateError('session'); }
      try {
        await client.storage.from('identity-documents').uploadBinary(paths[i], files[i].bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false));
      } catch (_) {
        if (client.auth.currentUser?.id != user) { rethrow; }
        final saved = await client.storage.from('identity-documents').download(paths[i]);
        if (!listEquals(saved, files[i].bytes)) { throw StateError('file_conflict'); }
      }
    }
    if (client.auth.currentUser?.id != user) { throw StateError('session'); }
    await client.rpc('submit_recovery_r10e', params: {'p_id': draft['id'], 'p_data': data});
  }
  @override
  Future<Uint8List> preview(String path) => client.storage.from('identity-documents').download(path);
}
