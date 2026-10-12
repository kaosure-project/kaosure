import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/account/domain/repositories/lifecycle_repository.dart';

final lifecycleRepositoryProvider = Provider<LifecycleRepository>((ref) =>
    SupabaseLifecycleRepository(ref));

class SupabaseLifecycleRepository implements LifecycleRepository {
  SupabaseLifecycleRepository(this.ref);
  final Ref ref;
  @override
  Future<Map<String, dynamic>> snapshot() async => Map<String, dynamic>.from(
    await ref.read(supabaseClientProvider).rpc('lifecycle_snapshot_r10b') as Map);
  @override
  Future<void> submit(String kind, String reason) async {
    await ref.read(supabaseClientProvider).rpc('lifecycle_submit_r10b',
      params: {'p_kind': kind, 'p_reason': reason});
  }
  @override
  Future<void> cancel(String id) async {
    await ref.read(supabaseClientProvider).rpc('lifecycle_cancel_r10b', params: {'p_id': id});
  }
}
