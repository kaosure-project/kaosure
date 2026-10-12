import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/wallet/domain/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) => SupabaseWalletRepository(ref));

class SupabaseWalletRepository implements WalletRepository {
  SupabaseWalletRepository(this.ref);
  final Ref ref;
  @override
  Future<Map<String, dynamic>> load(String user, {String? time, String? id}) async =>
    Map<String, dynamic>.from(await ref.read(supabaseClientProvider).rpc('wallet_snapshot_r12a', params: {
      'p_expected_user': user, 'p_before_time': time, 'p_before_id': id,
    }) as Map);
}
