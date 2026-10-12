/// A submitted business registration as seen by a reviewer.
class BusinessReviewItem {
  const BusinessReviewItem({
    required this.id,
    required this.businessType,
    required this.businessName,
    required this.registrationNumber,
    required this.businessCategory,
    this.businessDescription,
    this.submittedAt,
    this.documentName,
    this.documentMime,
    this.documentPaths = const [],
    this.ownerKaoId,
    this.ownerName,
    this.bankName,
    this.bankAccountLast4,
    this.bankAccountName,
    this.dualReview = false,
    this.firstReviewerId,
    this.firstDecisionApprove,
    this.firstReason,
  });

  final String id;
  final String businessType;
  final String businessName;
  final String registrationNumber;
  final String businessCategory;
  final String? businessDescription;
  final DateTime? submittedAt;
  final String? documentName;
  final String? documentMime;
  final List<String> documentPaths;

  /// The applicant's active personal Kao ID.
  final String? ownerKaoId;

  /// Name on the applicant's approved identity document.
  final String? ownerName;

  final String? bankName;
  final String? bankAccountLast4;
  final String? bankAccountName;

  /// Two independent reviewers must agree before the result is applied.
  final bool dualReview;
  final String? firstReviewerId;
  final bool? firstDecisionApprove;
  final String? firstReason;

  bool get hasFirstVote => firstReviewerId != null;

  bool get isPdf => documentMime == 'application/pdf';

  bool isOwnVote(String reviewerId) => dualReview && firstReviewerId == reviewerId;
}
