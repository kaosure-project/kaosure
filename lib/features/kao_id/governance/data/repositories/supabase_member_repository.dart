import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/member_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) =>
  SupabaseMemberRepository(ref.watch(supabaseClientProvider)));

class SupabaseMemberRepository implements MemberRepository {
  SupabaseMemberRepository(this.client);
  final SupabaseClient client;
  Future<dynamic> _call(String name, [Map<String, dynamic>? params]) async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) { throw StateError('session'); }
    final result = await client.rpc(name, params: params);
    if (client.auth.currentUser?.id != owner) { throw StateError('session'); }
    return result;
  }
  @override
  Future<bool> canRead() async => await _call('can_read_members_r9a') == true;
  @override
  Future<Map<String, dynamic>?> find(String query) async {
    final result = await _call('find_member_r9a', {'p_query': query.trim()});
    return result == null ? null : Map<String, dynamic>.from(result as Map);
  }
}
