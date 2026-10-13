import '../../domain/entities/business_registration.dart';

class BusinessRegistrationModel extends BusinessRegistration {
  const BusinessRegistrationModel({
    super.id,
    super.organizationId,
    required super.userId,
    required super.businessType,
    required super.businessName,
    required super.registrationNumber,
    required super.businessCategory,
    super.businessDescription,
    super.legalNameEn,
    super.certificateIssuedOn,
    super.documentId,
    super.vatDocumentId,
    super.documentStatus,
    super.status,
    super.createdAt,
    super.updatedAt,
    super.submittedAt,
    super.directorDeclaredAt,
    super.reviewReason,
  });

  factory BusinessRegistrationModel.fromJson(Map<String, dynamic> json) {
    return BusinessRegistrationModel(
      id: json['id']?.toString(),
      organizationId: json['organization_id']?.toString(),
      userId: json['user_id']?.toString() ?? json['profile_id']?.toString() ?? '',
      businessType: json['business_type']?.toString() ?? json['organization_type']?.toString() ?? '',
      businessName:
          json['business_name']?.toString() ?? json['name']?.toString() ?? json['legal_name']?.toString() ?? '',
      registrationNumber: json['registration_number']?.toString() ?? '',
      businessCategory: json['business_category']?.toString() ?? '',
      businessDescription: json['business_description']?.toString() ?? json['description']?.toString(),
      legalNameEn: json['legal_name_en']?.toString(),
      certificateIssuedOn: _dateTimeFromJson(json['certificate_issued_on']),
      documentId: json['document_id']?.toString(),
      vatDocumentId: json['vat_document_id']?.toString(),
      documentStatus: _documentStatusFromJson(json['document_status']),
      status: _registrationStatusFromJson(json['status'] ?? json['verification_status']),
      createdAt: _dateTimeFromJson(json['created_at']),
      updatedAt: _dateTimeFromJson(json['updated_at']),
      submittedAt: _dateTimeFromJson(json['submitted_at']),
      directorDeclaredAt: _dateTimeFromJson(json['director_declared_at']),
      reviewReason: json['review_reason']?.toString(),
    );
  }

  factory BusinessRegistrationModel.fromEntity(BusinessRegistration entity) {
    return BusinessRegistrationModel(
      id: entity.id,
      organizationId: entity.organizationId,
      userId: entity.userId,
      businessType: entity.businessType,
      businessName: entity.businessName,
      registrationNumber: entity.registrationNumber,
      businessCategory: entity.businessCategory,
      businessDescription: entity.businessDescription,
      legalNameEn: entity.legalNameEn,
      certificateIssuedOn: entity.certificateIssuedOn,
      documentId: entity.documentId,
      vatDocumentId: entity.vatDocumentId,
      documentStatus: entity.documentStatus,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      submittedAt: entity.submittedAt,
      directorDeclaredAt: entity.directorDeclaredAt,
      reviewReason: entity.reviewReason,
    );
  }

  /// `yyyy-MM-dd` for SQL `date` parameters.
  static String? dateParam(DateTime? value) => value == null
      ? null
      : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-'
            '${value.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      'user_id': userId,
      'business_type': businessType,
      'business_name': businessName,
      'registration_number': registrationNumber,
      'business_category': businessCategory,
      if (businessDescription != null) 'business_description': businessDescription,
      if (documentId != null) 'document_id': documentId,
      'document_status': _documentStatusToJson(documentStatus),
      'status': _registrationStatusToJson(status),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      if (organizationId != null) 'organization_id': organizationId,
      'user_id': userId,
      'business_type': businessType,
      'business_name': businessName,
      'registration_number': registrationNumber,
      'business_category': businessCategory,
      if (businessDescription != null) 'business_description': businessDescription,
      if (documentId != null) 'document_id': documentId,
      'document_status': _documentStatusToJson(documentStatus),
      'status': _registrationStatusToJson(status),
    };
  }

  static BusinessDocumentStatus _documentStatusFromJson(dynamic value) {
    switch (value?.toString()) {
      case 'uploaded':
        return BusinessDocumentStatus.uploaded;

      case 'verified':
        return BusinessDocumentStatus.verified;

      case 'rejected':
        return BusinessDocumentStatus.rejected;

      case 'pending':
      default:
        return BusinessDocumentStatus.pending;
    }
  }

  static String _documentStatusToJson(BusinessDocumentStatus value) {
    switch (value) {
      case BusinessDocumentStatus.pending:
        return 'pending';

      case BusinessDocumentStatus.uploaded:
        return 'uploaded';

      case BusinessDocumentStatus.verified:
        return 'verified';

      case BusinessDocumentStatus.rejected:
        return 'rejected';
    }
  }

  static BusinessRegistrationStatus _registrationStatusFromJson(dynamic value) {
    switch (value?.toString()) {
      case 'submitted':
        return BusinessRegistrationStatus.submitted;

      case 'under_review':
        return BusinessRegistrationStatus.underReview;

      case 'requires_action':
        return BusinessRegistrationStatus.requiresAction;

      case 'approved':
        return BusinessRegistrationStatus.approved;

      case 'rejected':
        return BusinessRegistrationStatus.rejected;

      case 'draft':
      default:
        return BusinessRegistrationStatus.draft;
    }
  }

  static String _registrationStatusToJson(BusinessRegistrationStatus value) {
    switch (value) {
      case BusinessRegistrationStatus.draft:
        return 'draft';

      case BusinessRegistrationStatus.submitted:
        return 'submitted';

      case BusinessRegistrationStatus.underReview:
        return 'under_review';

      case BusinessRegistrationStatus.requiresAction:
        return 'requires_action';

      case BusinessRegistrationStatus.approved:
        return 'approved';

      case BusinessRegistrationStatus.rejected:
        return 'rejected';
    }
  }

  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}
