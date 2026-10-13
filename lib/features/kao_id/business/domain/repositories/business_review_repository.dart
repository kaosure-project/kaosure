import 'dart:typed_data';

import '../entities/business_review_item.dart';
import '../entities/business_review_outcome.dart';

/// Every call is pinned to [reviewerId]; a different signed-in account fails with
/// `BusinessReviewFailureCode.session` instead of acting under the new session.
abstract interface class BusinessReviewRepository {
  String? currentReviewerId();

  Future<List<BusinessReviewItem>> queue(String reviewerId);

  Future<Uint8List> downloadDocument(String reviewerId, String path);

  /// Short-lived link for documents the app cannot render inline (PDF).
  Future<Uri> documentLink(String reviewerId, String path);

  /// [directorConfirmed]: the reviewer matched the applicant to a director named in the certificate.
  Future<BusinessReviewOutcome> decide({
    required String reviewerId,
    required String registrationId,
    required bool approve,
    bool directorConfirmed = false,
    String? reason,
  });
}
