import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/marketplace_review.dart';
import '../../domain/repositories/review_moderation_repository.dart';

/// `review_*_r25`. Each call checks `marketplace.reviews.moderate` on the
/// server; hiding and showing also need a fresh authenticator code when MFA
/// is switched on.
class SupabaseReviewModerationRepository implements ReviewModerationRepository {
  SupabaseReviewModerationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MarketplaceReview>> queue(ReviewQueueFilter filter, {DateTime? before}) async {
    final rows = await _client.rpc<dynamic>(
      'review_queue_r25',
      params: {'p_filter': filter.name, 'p_before': before?.toUtc().toIso8601String()},
    );
    return [
      if (rows is List)
        for (final row in rows) MarketplaceReview.fromJson(_map(row)),
    ];
  }

  @override
  Future<MarketplaceReview> detail(String id) async =>
      MarketplaceReview.fromJson(_map(await _client.rpc<dynamic>('review_detail_r25', params: {'p_review_id': id})));

  @override
  Future<MarketplaceReview> moderate(String id, {required bool hide, String? note}) async => MarketplaceReview.fromJson(
    _map(
      await _client.rpc<dynamic>('review_moderate_r25', params: {'p_review_id': id, 'p_hide': hide, 'p_note': note}),
    ),
  );
}

Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};
