import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/wallet/domain/repositories/linked_wallet_repository.dart';

final linkedWalletRepositoryProvider=Provider<LinkedWalletRepository>((ref)=>SupabaseLinkedWalletRepository(ref));

class SupabaseLinkedWalletRepository implements LinkedWalletRepository {
  SupabaseLinkedWalletRepository(this.ref);final Ref ref;
  @override
  Future<List<Map<String,dynamic>>> load(String user,String? profile) async =>
    (await ref.read(supabaseClientProvider).rpc('linked_wallets_r12c',params:{'p_user':user,'p_profile':profile}) as List).map((r)=>Map<String,dynamic>.from(r as Map)).toList();
}
