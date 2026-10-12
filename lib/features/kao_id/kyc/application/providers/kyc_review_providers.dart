import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_kyc_review_repository.dart';
import '../../../auth/application/providers/auth_provider.dart';

final kycReviewerAccessProvider = FutureProvider.autoDispose<bool>((ref) {
  ref.watch(authProvider.select((s) => s.asData?.value?.id));
  return ref.watch(kycReviewRepositoryProvider).canReview();
});

final myKaoIdR7cProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) {
  ref.watch(authProvider.select((s) => s.asData?.value?.id));
  return ref.watch(kycReviewRepositoryProvider).myIdentity();
});
