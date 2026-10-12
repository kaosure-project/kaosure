import '../entities/marketplace_review.dart';

abstract class ReviewModerationRepository {
  /// 30 per page; pass the last item's `sortAt` as [before].
  Future<List<MarketplaceReview>> queue(ReviewQueueFilter filter, {DateTime? before});

  /// With every report on it.
  Future<MarketplaceReview> detail(String id);

  /// Hiding needs a [note] for the reviewer; either way the waiting reports
  /// are settled and the reporters told.
  Future<MarketplaceReview> moderate(String id, {required bool hide, String? note});
}
