import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/features/kao_id/notifications/data/repositories/supabase_notice_repository.dart';
import '../../../auth/application/providers/auth_provider.dart';

final noticeInboxProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final id = ref.watch(authProvider.select((s) => s.asData?.value?.id));
  if (id == null) { return {'unread': 0, 'items': []}; }
  return ref.watch(noticeRepositoryProvider).inbox();
});
