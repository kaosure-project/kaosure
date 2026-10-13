import 'dart:typed_data';

import 'package:kaosure/features/kao_id/business/domain/entities/business_review_item.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_review_outcome.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_review_failure.dart';
import 'package:kaosure/features/kao_id/business/domain/repositories/business_review_repository.dart';

/// Matches TestAuthNotifier.user.id used by widget tests.
const reviewerId = 'test-user';

BusinessReviewItem reviewItem({
  String id = 'reg-1',
  String name = 'ร้านเก้าเทรดดิ้ง',
  String mime = 'image/png',
  List<String> paths = const ['owner/business-registration/reg-1/doc.png'],
  List<String> vatPaths = const [],
  bool certificateFresh = true,
  bool numberValid = true,
  bool numberTaken = false,
  bool dualReview = false,
  String? firstReviewerId,
  bool? firstDecisionApprove,
}) => BusinessReviewItem(
  id: id,
  businessType: 'registered_business',
  businessName: name,
  legalNameEn: 'KAO TRADING CO., LTD.',
  registrationNumber: '0105561234560',
  registrationNumberValid: numberValid,
  registrationNumberTaken: numberTaken,
  businessCategory: 'retail',
  businessDescription: 'Secondhand electronics',
  certificateIssuedOn: DateTime(2026, 9, 1),
  certificateFresh: certificateFresh,
  submittedAt: DateTime(2026, 10, 12),
  documentName: 'certificate.png',
  documentMime: mime,
  documentPaths: paths,
  vatDocumentName: vatPaths.isEmpty ? null : 'vat.png',
  vatDocumentMime: vatPaths.isEmpty ? null : 'image/png',
  vatPaths: vatPaths,
  ownerKaoId: 'KAB12CD34EF',
  ownerName: 'สมชาย ใจดี',
  directorDeclared: true,
  dualReview: dualReview,
  firstReviewerId: firstReviewerId,
  firstDecisionApprove: firstDecisionApprove,
);

final class FakeBusinessReviewRepository implements BusinessReviewRepository {
  List<BusinessReviewItem> items = [reviewItem()];
  BusinessReviewOutcome outcome = BusinessReviewOutcome.approved;
  BusinessReviewFailureCode? failNext;
  final decisions = <({String registrationId, bool approve, bool directorConfirmed, String? reason})>[];
  final downloads = <String>[];

  @override
  String? currentReviewerId() => reviewerId;

  @override
  Future<List<BusinessReviewItem>> queue(String reviewerId) async {
    _maybeFail();
    return items;
  }

  @override
  Future<Uint8List> downloadDocument(String reviewerId, String path) async {
    _maybeFail();
    downloads.add(path);
    // 1x1 transparent PNG.
    return Uint8List.fromList(const [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0D,
      0x0A,
      0x2D,
      0xB4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]);
  }

  @override
  Future<Uri> documentLink(String reviewerId, String path) async {
    _maybeFail();
    return Uri.parse('https://storage.example/signed/$path');
  }

  @override
  Future<BusinessReviewOutcome> decide({
    required String reviewerId,
    required String registrationId,
    required bool approve,
    bool directorConfirmed = false,
    String? reason,
  }) async {
    _maybeFail();
    decisions.add((
      registrationId: registrationId,
      approve: approve,
      directorConfirmed: directorConfirmed,
      reason: reason,
    ));
    return outcome;
  }

  void _maybeFail() {
    final code = failNext;
    if (code == null) return;
    failNext = null;
    throw BusinessReviewFailure(code);
  }
}
