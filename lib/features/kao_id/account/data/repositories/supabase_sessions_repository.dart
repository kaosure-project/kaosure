import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/account/domain/repositories/sessions_repository.dart';

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) => SupabaseSessionsRepository(ref));

class SupabaseSessionsRepository implements SessionsRepository {
  SupabaseSessionsRepository(this.ref);
  final Ref ref;
  @override
  Future<List<Map<String, dynamic>>> list() async =>
    (await ref.read(supabaseClientProvider).rpc('sessions_r11a') as List)
      .map((e) => Map<String, dynamic>.from(e as Map)).toList();
  @override
  Future<void> revoke(String? id, {bool others = false, required String expectedUser}) async {
    await ref.read(supabaseClientProvider).rpc('revoke_session_r11a', params: {'p_session': id, 'p_others': others, 'p_expected_user': expectedUser});
  }
}
