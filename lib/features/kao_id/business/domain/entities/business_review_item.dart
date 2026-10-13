/// A submitted business registration as seen by a reviewer.
class BusinessReviewItem {
  const BusinessReviewItem({
    required this.id,
    required this.businessType,
    required this.businessName,
    required this.registrationNumber,
    required this.businessCategory,
    this.businessDescription,
    this.legalNameEn,
    this.registrationNumberValid = false,
    this.registrationNumberTaken = false,
    this.certificateIssuedOn,
    this.certificateFresh = false,
    this.submittedAt,
    this.documentName,
    this.documentMime,
    this.documentPaths = const [],
    this.vatDocumentName,
    this.vatDocumentMime,
    this.vatPaths = const [],
    this.ownerKaoId,
    this.ownerName,
    this.directorDeclared = false,
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
  final String? legalNameEn;

  /// The 13-digit juristic number passes the Thai check digit.
  final bool registrationNumberValid;

  /// Another active company already holds this number.
  final bool registrationNumberTaken;

  /// Issue date of the company certificate (หนังสือรับรอง); approval needs it within 6 months.
  final DateTime? certificateIssuedOn;
  final bool certificateFresh;

  final DateTime? submittedAt;
  final String? documentName;
  final String? documentMime;
  final List<String> documentPaths;

  /// Optional VAT certificate (ภ.พ.20).
  final String? vatDocumentName;
  final String? vatDocumentMime;
  final List<String> vatPaths;

  /// The applicant's active personal Kao ID.
  final String? ownerKaoId;

  /// Name on the applicant's approved identity document.
  final String? ownerName;

  /// The applicant declared they are a director named in the certificate.
  final bool directorDeclared;

  /// Two independent reviewers must agree before the result is applied.
  final bool dualReview;
  final String? firstReviewerId;
  final bool? firstDecisionApprove;
  final String? firstReason;

  bool get hasFirstVote => firstReviewerId != null;

  bool get isPdf => documentMime == 'application/pdf';

  bool get isVatPdf => vatDocumentMime == 'application/pdf';

  List<String> get allPaths => [...documentPaths, ...vatPaths];

  bool isOwnVote(String reviewerId) => dualReview && firstReviewerId == reviewerId;
}
