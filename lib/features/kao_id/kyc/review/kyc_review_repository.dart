import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import '../../auth/application/providers/auth_provider.dart';

abstract interface class KycReviewRepository {
  Future<bool> canReview();
  Future<List<Map<String, dynamic>>> queue();
  Future<Uint8List> preview(String path);
  Future<void> decide(String request, bool approve, String reason);
  Future<Map<String, dynamic>?> myIdentity();
  Future<String> issue();
}
final kycReviewRepositoryProvider = Provider<KycReviewRepository>((ref) =>
  SupabaseKycReviewRepository(ref.watch(supabaseClientProvider)));
final kycReviewerAccessProvider = FutureProvider.autoDispose<bool>((ref) {
  ref.watch(authProvider.select((s) => s.asData?.value?.id));
  return ref.watch(kycReviewRepositoryProvider).canReview();
});
final myKaoIdR7cProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) {
  ref.watch(authProvider.select((s) => s.asData?.value?.id));
  return ref.watch(kycReviewRepositoryProvider).myIdentity();
});
class SupabaseKycReviewRepository implements KycReviewRepository {
  SupabaseKycReviewRepository(this.client);
  final SupabaseClient client;
  Future<String> _owner() async {
    final user = (await client.auth.getUser()).user;
    if (user == null) { throw StateError('session'); }
    return user.id;
  }
  Future<void> _check(String id) async {
    if (await _owner() != id) { throw StateError('session'); }
  }
  @override
  Future<bool> canReview() async {
    final owner = await _owner();
    final result = await client.rpc('can_review_kyc_r7c');
    await _check(owner);
    return result == true;
  }
  @override
  Future<List<Map<String, dynamic>>> queue() async {
    final owner = await _owner();
    final result = await client.rpc('kyc_review_queue_r7c');
    await _check(owner);
    return (result as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }
  @override
  Future<Uint8List> preview(String path) async {
    final owner = await _owner();
    final result = await client.storage.from('identity-documents').download(path);
    await _check(owner);
    return result;
  }
  @override
  Future<void> decide(String request, bool approve, String reason) async {
    final owner = await _owner();
    await client.rpc('kyc_review_decision_r7c', params: {
      'p_request': request, 'p_approve': approve, 'p_reason': reason,
    });
    await _check(owner);
  }
  @override
  Future<Map<String, dynamic>?> myIdentity() async {
    final owner = await _owner();
    final result = await client.from('kao_id_identities').select('kao_id,status')
      .eq('profile_id', owner).maybeSingle();
    await _check(owner);
    return result;
  }
  @override
  Future<String> issue() async {
    final owner = await _owner();
    final result = await client.rpc('issue_kao_id', params: {'p_profile_id': owner});
    await _check(owner);
    if (result is! String || result.isEmpty) { throw StateError('issue'); }
    return result;
  }
}
