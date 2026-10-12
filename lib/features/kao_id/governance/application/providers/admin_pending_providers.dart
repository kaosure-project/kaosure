import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../business/application/providers/business_review_providers.dart';
import '../../../kyc/data/repositories/supabase_kyc_review_repository.dart';

/// Number of waiting items read from a review queue.
class PendingCount {
  const PendingCount(this.value);

  /// Review queues return at most this many of the oldest requests.
  static const queueLimit = 50;

  final int value;

  bool get capped => value >= queueLimit;

  String get label => capped ? '$queueLimit+' : '$value';
}

final kycPendingCountProvider = FutureProvider.autoDispose<PendingCount>((ref) async {
  final rows = await ref.watch(kycReviewRepositoryProvider).queue();
  return PendingCount(rows.length);
});

final businessPendingCountProvider = FutureProvider.autoDispose<PendingCount>((ref) async {
  final items = await ref.watch(businessReviewQueueProvider.future);
  return PendingCount(items.length);
});

/// Business requests that already have one vote and need a second reviewer.
final businessSecondVoteCountProvider = FutureProvider.autoDispose<PendingCount>((ref) async {
  final items = await ref.watch(businessReviewQueueProvider.future);
  return PendingCount(items.where((item) => item.hasFirstVote).length);
});
