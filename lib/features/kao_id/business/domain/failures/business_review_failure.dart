enum BusinessReviewFailureCode {
  session,
  noPermission,
  mfaRequired,
  alreadyReviewed,
  unavailable,
  reasonRequired,
  documentMissing,
  documentUnavailable,
  ownerKaoIdRequired,
  directorRequired,
  certificateTooOld,
  invalidNumber,
  applicantInactive,
  unknown,
}

final class BusinessReviewFailure implements Exception {
  const BusinessReviewFailure(this.code);

  final BusinessReviewFailureCode code;

  @override
  String toString() => 'BusinessReviewFailure(${code.name})';
}
