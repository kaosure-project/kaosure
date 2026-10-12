import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/wallet/domain/repositories/partner_repository.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) => SupabasePartnerRepository(ref));

final shippingPartnerRepositoryProvider = Provider<PartnerRepository>((ref) => SupabasePartnerRepository(ref, kind: 'shipping'));

class SupabasePartnerRepository implements PartnerRepository {
  SupabasePartnerRepository(this.ref, {this.kind = 'finance'});
  final String kind;
  final Ref ref;
  @override
  Future<List<Map<String, dynamic>>> list(String user) async =>
    (await ref.read(supabaseClientProvider).rpc('partner_list_r12b',params:{'p_user':user}) as List)
      .map((r)=>Map<String,dynamic>.from(r as Map)).toList();
  @override
  Future<void> create(String user,String code,String name,String environment,List<String> capabilities) async {
    await ref.read(supabaseClientProvider).rpc('partner_create_r12c',params:{'p_kind':kind,'p_user':user,'p_code':code,'p_name':name,'p_environment':environment,'p_capabilities':capabilities});
  }
  @override
  Future<void> decide(String user,String id,int revision,String action,String reason) async {
    await ref.read(supabaseClientProvider).rpc('partner_decide_r12b',params:{'p_user':user,'p_id':id,'p_revision':revision,'p_action':action,'p_reason':reason});
  }
}
