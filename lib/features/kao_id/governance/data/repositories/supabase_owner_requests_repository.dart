import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/owner_requests_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final ownerRequestsRepositoryProvider = Provider<OwnerRequestsRepository>((ref) =>
  SupabaseOwnerRequestsRepository(ref.read(supabaseClientProvider)));

class SupabaseOwnerRequestsRepository implements OwnerRequestsRepository {
  SupabaseOwnerRequestsRepository(this.client);
  final SupabaseClient client;
  @override
  Future<List<Map<String, dynamic>>> list(String status, Map<String, dynamic>? cursor) async {
    final result = await client.rpc('lifecycle_queue_r10c', params: {'p_status': status,
      'p_before': cursor?['created_at'], 'p_before_id': cursor?['id']});
    return (result as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }
  @override
  Future<Map<String, dynamic>> checks(String id) async => Map<String, dynamic>.from(
    await client.rpc('lifecycle_checks_r10c', params: {'p_id': id}) as Map);
  @override
  Future<void> reject(String id, String reason) async {
    await client.rpc('lifecycle_reject_r10c', params: {'p_id': id, 'p_reason': reason});
  }
}
