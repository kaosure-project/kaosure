import '../../domain/entities/business_review_item.dart';

final class BusinessReviewItemModel extends BusinessReviewItem {
  const BusinessReviewItemModel({
    required super.id,
    required super.businessType,
    required super.businessName,
    required super.registrationNumber,
    required super.businessCategory,
    super.businessDescription,
    super.legalNameEn,
    super.registrationNumberValid,
    super.registrationNumberTaken,
    super.certificateIssuedOn,
    super.certificateFresh,
    super.submittedAt,
    super.documentName,
    super.documentMime,
    super.documentPaths,
    super.vatDocumentName,
    super.vatDocumentMime,
    super.vatPaths,
    super.ownerKaoId,
    super.ownerName,
    super.directorDeclared,
    super.dualReview,
    super.firstReviewerId,
    super.firstDecisionApprove,
    super.firstReason,
  });

  /// Row shape of `kaoid_private.business_review_rows_r15b`.
  factory BusinessReviewItemModel.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    List<String> paths(String key) => [
      for (final path in json[key] as List? ?? const [])
        if (path is String && path.isNotEmpty) path,
    ];

    return BusinessReviewItemModel(
      id: json['id'].toString(),
      businessType: text('business_type') ?? '',
      businessName: text('business_name') ?? '',
      registrationNumber: text('registration_number') ?? '',
      businessCategory: text('business_category') ?? '',
      businessDescription: text('business_description'),
      legalNameEn: text('legal_name_en'),
      registrationNumberValid: json['registration_number_valid'] == true,
      registrationNumberTaken: json['registration_number_taken'] == true,
      certificateIssuedOn: DateTime.tryParse(text('certificate_issued_on') ?? ''),
      certificateFresh: json['certificate_fresh'] == true,
      submittedAt: DateTime.tryParse(text('submitted_at') ?? '')?.toLocal(),
      documentName: text('document_name'),
      documentMime: text('document_mime'),
      documentPaths: paths('paths'),
      vatDocumentName: text('vat_document_name'),
      vatDocumentMime: text('vat_document_mime'),
      vatPaths: paths('vat_paths'),
      ownerKaoId: text('owner_kao_id'),
      ownerName: text('owner_name'),
      directorDeclared: json['director_declared'] == true,
      dualReview: json['dual_review'] == true,
      firstReviewerId: text('first_reviewer'),
      firstDecisionApprove: json['first_decision'] is bool ? json['first_decision'] as bool : null,
      firstReason: text('first_reason'),
    );
  }
}
