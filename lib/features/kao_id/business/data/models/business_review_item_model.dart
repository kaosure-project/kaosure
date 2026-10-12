import '../../domain/entities/business_review_item.dart';

final class BusinessReviewItemModel extends BusinessReviewItem {
  const BusinessReviewItemModel({
    required super.id,
    required super.businessType,
    required super.businessName,
    required super.registrationNumber,
    required super.businessCategory,
    super.businessDescription,
    super.submittedAt,
    super.documentName,
    super.documentMime,
    super.documentPaths,
    super.ownerKaoId,
    super.ownerName,
    super.bankName,
    super.bankAccountLast4,
    super.bankAccountName,
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

    return BusinessReviewItemModel(
      id: json['id'].toString(),
      businessType: text('business_type') ?? '',
      businessName: text('business_name') ?? '',
      registrationNumber: text('registration_number') ?? '',
      businessCategory: text('business_category') ?? '',
      businessDescription: text('business_description'),
      submittedAt: DateTime.tryParse(text('submitted_at') ?? '')?.toLocal(),
      documentName: text('document_name'),
      documentMime: text('document_mime'),
      documentPaths: [
        for (final path in json['paths'] as List? ?? const [])
          if (path is String && path.isNotEmpty) path,
      ],
      ownerKaoId: text('owner_kao_id'),
      ownerName: text('owner_name'),
      bankName: text('bank_name'),
      bankAccountLast4: text('bank_account_last4'),
      bankAccountName: text('bank_account_name'),
      dualReview: json['dual_review'] == true,
      firstReviewerId: text('first_reviewer'),
      firstDecisionApprove: json['first_decision'] is bool ? json['first_decision'] as bool : null,
      firstReason: text('first_reason'),
    );
  }
}
