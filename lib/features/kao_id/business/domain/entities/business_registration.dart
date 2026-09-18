enum BusinessRegistrationStatus {
  draft,
  submitted,
  underReview,
  requiresAction,
  approved,
  rejected,
}

enum BusinessDocumentStatus {
  pending,
  uploaded,
  verified,
  rejected,
}

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
    this.documentId,
    this.documentStatus = BusinessDocumentStatus.pending,
    this.status = BusinessRegistrationStatus.draft,
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
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

  /// ID ของเอกสารที่บันทึกในระบบ
  final String? documentId;

  /// สถานะเอกสาร
  final BusinessDocumentStatus documentStatus;

  /// สถานะคำขอ Business Registration
  final BusinessRegistrationStatus status;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;

  BusinessRegistration copyWith({
    String? id,
    String? organizationId,
    String? userId,
    String? businessType,
    String? businessName,
    String? registrationNumber,
    String? businessCategory,
    String? businessDescription,
    String? documentId,
    BusinessDocumentStatus? documentStatus,
    BusinessRegistrationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
  }) {
    return BusinessRegistration(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      businessType: businessType ?? this.businessType,
      businessName: businessName ?? this.businessName,
      registrationNumber:
          registrationNumber ?? this.registrationNumber,
      businessCategory:
          businessCategory ?? this.businessCategory,
      businessDescription:
          businessDescription ?? this.businessDescription,
      documentId: documentId ?? this.documentId,
      documentStatus:
          documentStatus ?? this.documentStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  bool get isDraft =>
      status == BusinessRegistrationStatus.draft;

  bool get isSubmitted =>
      status == BusinessRegistrationStatus.submitted;

  bool get isUnderReview =>
      status == BusinessRegistrationStatus.underReview;

  bool get requiresAction =>
      status == BusinessRegistrationStatus.requiresAction;

  bool get isApproved =>
      status == BusinessRegistrationStatus.approved;

  bool get isRejected =>
      status == BusinessRegistrationStatus.rejected;

  bool get hasDocument =>
      documentId != null && documentId!.isNotEmpty;

  bool get isDocumentVerified =>
      documentStatus == BusinessDocumentStatus.verified;

  bool get canSubmit =>
      businessName.trim().isNotEmpty &&
      registrationNumber.trim().isNotEmpty &&
      businessCategory.trim().isNotEmpty &&
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