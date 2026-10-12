import '../../domain/entities/business_review_outcome.dart';
import '../../domain/failures/business_review_failure.dart';

final class BusinessReviewDecisionState {
  const BusinessReviewDecisionState({
    this.viewedPaths = const {},
    this.checked = false,
    this.busy = false,
    this.failure,
    this.outcome,
  });

  /// Documents the reviewer has opened; approval requires all of them.
  final Set<String> viewedPaths;
  final bool checked;
  final bool busy;
  final BusinessReviewFailureCode? failure;
  final BusinessReviewOutcome? outcome;

  BusinessReviewDecisionState copyWith({
    Set<String>? viewedPaths,
    bool? checked,
    bool? busy,
    BusinessReviewFailureCode? failure,
    bool clearFailure = false,
    BusinessReviewOutcome? outcome,
  }) {
    return BusinessReviewDecisionState(
      viewedPaths: viewedPaths ?? this.viewedPaths,
      checked: checked ?? this.checked,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : failure ?? this.failure,
      outcome: outcome ?? this.outcome,
    );
  }
}
