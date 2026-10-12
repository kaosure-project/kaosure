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
  ownerBankRequired,
  applicantInactive,
  unknown,
}

final class BusinessReviewFailure implements Exception {
  const BusinessReviewFailure(this.code);

  final BusinessReviewFailureCode code;

  @override
  String toString() => 'BusinessReviewFailure(${code.name})';
}
