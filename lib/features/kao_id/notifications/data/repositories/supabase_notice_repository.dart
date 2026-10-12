import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/notifications/domain/repositories/notice_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) => SupabaseNoticeRepository(ref.watch(supabaseClientProvider)));

class SupabaseNoticeRepository implements NoticeRepository {
  SupabaseNoticeRepository(this.client);
  final SupabaseClient client;
  Future<dynamic> call(String name, [Map<String, dynamic>? params]) async {
    final id = client.auth.currentUser?.id;
    if (id == null) { throw StateError('session'); }
    final result = await client.rpc(name, params: params);
    if (id != client.auth.currentUser?.id) { throw StateError('session'); }
    return result;
  }
  @override
  Future<Map<String, dynamic>> inbox() async => Map<String, dynamic>.from(await call('kaoid_inbox_r10a') as Map);
  @override
  Future<void> read(String id) async { await call('kaoid_read_notice_r10a', {'p_id': id}); }
}
