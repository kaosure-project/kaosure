import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/notifications/domain/repositories/notice_target_repository.dart';

final noticeTargetRepositoryProvider = Provider<NoticeTargetRepository>((ref) => SupabaseNoticeTargetRepository(ref));

class SupabaseNoticeTargetRepository implements NoticeTargetRepository {
  SupabaseNoticeTargetRepository(this.ref);
  final Ref ref;
  @override
  Future<Map<String, dynamic>> open(String id) async {
    final client = ref.read(supabaseClientProvider);
    final owner = client.auth.currentUser?.id;
    if (owner == null) { throw StateError('session'); }
    final data = await client.rpc('kaoid_notice_target_r14b', params: {'p_notice': id});
    if (client.auth.currentUser?.id != owner) { throw StateError('session'); }
    return Map<String, dynamic>.from(data as Map);
  }
}
