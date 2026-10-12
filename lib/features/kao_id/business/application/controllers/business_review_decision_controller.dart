import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/business_review_item.dart';
import '../../domain/entities/business_review_outcome.dart';
import '../../domain/failures/business_review_failure.dart';
import '../../domain/repositories/business_review_repository.dart';
import '../states/business_review_decision_state.dart';

typedef ExternalLinkOpener = Future<bool> Function(Uri link);

final class BusinessReviewDecisionController extends StateNotifier<BusinessReviewDecisionState> {
  BusinessReviewDecisionController({
    required this._repository,
    required this._openLink,
    required this.item,
    required this.reviewerId,
  }) : super(const BusinessReviewDecisionState());

  final BusinessReviewRepository _repository;
  final ExternalLinkOpener _openLink;
  final BusinessReviewItem item;
  final String reviewerId;

  bool get isOwnVote => item.isOwnVote(reviewerId);

  bool get allDocumentsViewed =>
      item.documentPaths.isNotEmpty && item.documentPaths.every(state.viewedPaths.contains);

  bool get canApprove => !state.busy && !isOwnVote && state.checked && allDocumentsViewed;

  bool get canReject => !state.busy && !isOwnVote;

  void setChecked(bool value) => state = state.copyWith(checked: value);

  void dismissFailure() => state = state.copyWith(clearFailure: true);

  /// Image bytes for inline preview; the document counts as viewed once loaded.
  Future<Uint8List?> loadImage(String path) => _run(() async {
        final bytes = await _repository.downloadDocument(reviewerId, path);
        _markViewed(path);
        return bytes;
      });

  /// Opens a short-lived link in the browser for formats shown outside the app (PDF).
  Future<void> openExternally(String path) async {
    await _run(() async {
      final link = await _repository.documentLink(reviewerId, path);
      if (!await _openLink(link)) {
        throw const BusinessReviewFailure(BusinessReviewFailureCode.documentUnavailable);
      }
      _markViewed(path);
      return null;
    });
  }

  Future<BusinessReviewOutcome?> decide({required bool approve, String? reason}) async {
    if (approve ? !canApprove : !canReject) return null;
    if (!approve && (reason?.trim().length ?? 0) < 3) {
      state = state.copyWith(failure: BusinessReviewFailureCode.reasonRequired);
      return null;
    }
    final outcome = await _run(() => _repository.decide(
          reviewerId: reviewerId,
          registrationId: item.id,
          approve: approve,
          reason: reason,
        ));
    if (outcome != null && mounted) state = state.copyWith(outcome: outcome);
    return outcome;
  }

  void _markViewed(String path) {
    if (mounted) state = state.copyWith(viewedPaths: {...state.viewedPaths, path});
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    if (state.busy) return null;
    state = state.copyWith(busy: true, clearFailure: true);
    try {
      return await action();
    } on BusinessReviewFailure catch (failure) {
      if (mounted) state = state.copyWith(failure: failure.code);
      return null;
    } catch (_) {
      if (mounted) state = state.copyWith(failure: BusinessReviewFailureCode.unknown);
      return null;
    } finally {
      if (mounted) state = state.copyWith(busy: false);
    }
  }
}
