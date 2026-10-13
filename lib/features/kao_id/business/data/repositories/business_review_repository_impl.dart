import 'dart:typed_data';

import '../../domain/entities/business_review_item.dart';
import '../../domain/entities/business_review_outcome.dart';
import '../../domain/failures/business_review_failure.dart';
import '../../domain/repositories/business_review_repository.dart';
import '../datasources/remote/business_review_remote_data_source.dart';
import '../mappers/business_review_failure_mapper.dart';
import '../models/business_review_item_model.dart';

final class BusinessReviewRepositoryImpl implements BusinessReviewRepository {
  BusinessReviewRepositoryImpl({required this._remoteDataSource});

  final BusinessReviewRemoteDataSource _remoteDataSource;

  @override
  String? currentReviewerId() => _remoteDataSource.currentUserId();

  @override
  Future<List<BusinessReviewItem>> queue(String reviewerId) => _pinned(reviewerId, () async {
    final rows = await _remoteDataSource.queue();
    return [for (final row in rows) BusinessReviewItemModel.fromJson(row)];
  });

  @override
  Future<Uint8List> downloadDocument(String reviewerId, String path) =>
      _pinned(reviewerId, () => _remoteDataSource.download(path));

  @override
  Future<Uri> documentLink(String reviewerId, String path) => _pinned(reviewerId, () async {
    final link = Uri.tryParse(await _remoteDataSource.signedUrl(path));
    if (link == null || !link.hasScheme) {
      throw const BusinessReviewFailure(BusinessReviewFailureCode.documentUnavailable);
    }
    return link;
  });

  @override
  Future<BusinessReviewOutcome> decide({
    required String reviewerId,
    required String registrationId,
    required bool approve,
    bool directorConfirmed = false,
    String? reason,
  }) => _pinned(reviewerId, () async {
    final trimmed = reason?.trim() ?? '';
    if (!approve && trimmed.length < 3) {
      throw const BusinessReviewFailure(BusinessReviewFailureCode.reasonRequired);
    }
    if (approve && !directorConfirmed) {
      throw const BusinessReviewFailure(BusinessReviewFailureCode.directorRequired);
    }
    // The server re-checks the expected reviewer inside the decision transaction.
    final status = await _remoteDataSource.decide(
      expectedUserId: reviewerId,
      registrationId: registrationId,
      approve: approve,
      directorConfirmed: approve && directorConfirmed,
      reason: trimmed.isEmpty ? null : trimmed,
    );
    return switch (status) {
      'approved' => BusinessReviewOutcome.approved,
      'rejected' => BusinessReviewOutcome.rejected,
      'awaiting_second' => BusinessReviewOutcome.awaitingSecond,
      _ => throw const BusinessReviewFailure(BusinessReviewFailureCode.unknown),
    };
  });

  Future<T> _pinned<T>(String reviewerId, Future<T> Function() run) async {
    try {
      _ensureReviewer(reviewerId);
      final result = await run();
      _ensureReviewer(reviewerId);
      return result;
    } catch (error) {
      throw businessReviewFailureFrom(error);
    }
  }

  void _ensureReviewer(String reviewerId) {
    if (_remoteDataSource.currentUserId() != reviewerId) {
      throw const BusinessReviewFailure(BusinessReviewFailureCode.session);
    }
  }
}
