import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/account/domain/repositories/account_access_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountAccessRepositoryProvider = Provider<AccountAccessRepository>((ref) =>
    SupabaseAccountAccessRepository(ref.read(supabaseClientProvider)));

class SupabaseAccountAccessRepository implements AccountAccessRepository {
  SupabaseAccountAccessRepository(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  Stream<void> get changes => client.auth.onAuthStateChange.map((_) {});
  @override
  Future<String> check() async =>
      (await client.rpc('account_access_r10d') as Map)['state'] as String;
  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
}
