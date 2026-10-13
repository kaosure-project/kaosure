enum BusinessRegistrationStatus { draft, submitted, underReview, requiresAction, approved, rejected }

enum BusinessDocumentStatus { pending, uploaded, verified, rejected }

class BusinessRegistration {
  const BusinessRegistration({
    this.id,
    this.organizationId,
    required this.userId,
    required this.businessType,
    required this.businessName,
    required this.registrationNumber,
    required this.businessCategory,
    this.businessDescription,
    this.legalNameEn,
    this.certificateIssuedOn,
    this.documentId,
    this.vatDocumentId,
    this.documentStatus = BusinessDocumentStatus.pending,
    this.status = BusinessRegistrationStatus.draft,
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.directorDeclaredAt,
    this.reviewReason,
  });

  final String? id;

  /// ID ของ Organization ที่สร้างจาก Business Registration
  final String? organizationId;

  final String userId;

  /// ประเภทการประกอบธุรกิจ
  /// เช่น registered_business / business_document
  final String businessType;

  /// ชื่อกิจการ
  final String businessName;

  /// เลขทะเบียนหรือเลขอ้างอิงกิจการ
  final String registrationNumber;

  /// หมวดหมู่ธุรกิจ
  final String businessCategory;

  /// รายละเอียดกิจการ
  final String? businessDescription;

  /// ชื่อนิติบุคคลภาษาอังกฤษตามหนังสือรับรอง
  final String? legalNameEn;

  /// วันที่ออกหนังสือรับรอง; ต้องไม่เกิน 6 เดือนเมื่อส่งตรวจ
  final DateTime? certificateIssuedOn;

  /// ID ของหนังสือรับรองนิติบุคคลที่บันทึกในระบบ
  final String? documentId;

  /// ID ของ ภ.พ.20 (ไม่บังคับ)
  final String? vatDocumentId;

  /// สถานะเอกสาร
  final BusinessDocumentStatus documentStatus;

  /// สถานะคำขอ Business Registration
  final BusinessRegistrationStatus status;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;

  /// When the applicant declared they are a director named in the certificate.
  final DateTime? directorDeclaredAt;

  /// Reviewer's note shown to the owner, required when the registration is rejected.
  final String? reviewReason;

  BusinessRegistration copyWith({
    String? id,
    String? organizationId,
    String? userId,
    String? businessType,
    String? businessName,
    String? registrationNumber,
    String? businessCategory,
    String? businessDescription,
    String? legalNameEn,
    DateTime? certificateIssuedOn,
    String? documentId,
    String? vatDocumentId,
    BusinessDocumentStatus? documentStatus,
    BusinessRegistrationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? directorDeclaredAt,
    String? reviewReason,
  }) {
    return BusinessRegistration(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      businessType: businessType ?? this.businessType,
      businessName: businessName ?? this.businessName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      businessCategory: businessCategory ?? this.businessCategory,
      businessDescription: businessDescription ?? this.businessDescription,
      legalNameEn: legalNameEn ?? this.legalNameEn,
      certificateIssuedOn: certificateIssuedOn ?? this.certificateIssuedOn,
      documentId: documentId ?? this.documentId,
      vatDocumentId: vatDocumentId ?? this.vatDocumentId,
      documentStatus: documentStatus ?? this.documentStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      directorDeclaredAt: directorDeclaredAt ?? this.directorDeclaredAt,
      reviewReason: reviewReason ?? this.reviewReason,
    );
  }

  bool get isDraft => status == BusinessRegistrationStatus.draft;

  bool get isSubmitted => status == BusinessRegistrationStatus.submitted;

  bool get isUnderReview => status == BusinessRegistrationStatus.underReview;

  bool get requiresAction => status == BusinessRegistrationStatus.requiresAction;

  bool get isApproved => status == BusinessRegistrationStatus.approved;

  bool get isRejected => status == BusinessRegistrationStatus.rejected;

  bool get hasDocument => documentId != null && documentId!.isNotEmpty;

  bool get hasVatDocument => vatDocumentId != null && vatDocumentId!.isNotEmpty;

  bool get isDocumentVerified => documentStatus == BusinessDocumentStatus.verified;

  bool get canSubmit =>
      businessName.trim().isNotEmpty &&
      registrationNumber.trim().isNotEmpty &&
      businessCategory.trim().isNotEmpty &&
      certificateIssuedOn != null &&
      hasDocument &&
      status == BusinessRegistrationStatus.draft;

  @override
  String toString() {
    return 'BusinessRegistration('
        'id: $id, '
        'organizationId: $organizationId, '
        'userId: $userId, '
        'businessType: $businessType, '
        'businessName: $businessName, '
        'registrationNumber: $registrationNumber, '
        'businessCategory: $businessCategory, '
        'status: $status'
        ')';
  }
}
