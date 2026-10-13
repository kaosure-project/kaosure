import 'dart:typed_data';

import 'package:kaosure/features/wallet/domain/entities/topup_request.dart';

import '../entities/topup_review.dart';

abstract class TopupReviewRepository {
  /// Newest first, 30 per page.
  Future<List<TopupReviewItem>> queue(TopupStatus status, {DateTime? before});

  Future<TopupReviewDetail> detail(String id);

  Future<Uint8List> slip(String path);

  /// Credits the wallet, or records the first vote when two reviewers are needed.
  Future<TopupReviewItem> approve(String id, {required bool payerConfirmed, required String reference});

  Future<TopupReviewItem> reject(String id, String reason);

  Future<TopupSettings> settings();

  Future<TopupSettings> saveSettings(TopupSettings settings);
}
