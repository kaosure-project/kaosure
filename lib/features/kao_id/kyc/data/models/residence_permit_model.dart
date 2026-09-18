import '../../domain/entities/residence_permit.dart';

final class ResidencePermitModel {
  const ResidencePermitModel({
    required this.id,
    required this.ownerId,
    required this.documentType,
    required this.permitNumber,
    required this.fullName,
    required this.countryCode,
    required this.status,
    this.issuedDate,
    this.expiryDate,
    this.verificationMethod,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectedReason,
    this.deletedAt,
    this.filePath,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.uploadedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String ownerId;

  final String documentType;

  final String permitNumber;

  final String fullName;

  final String countryCode;

  final String status;

  final DateTime? issuedDate;

  final DateTime? expiryDate;

  final String? verificationMethod;

  final DateTime? verifiedAt;

  final String? verifiedBy;

  final String? rejectedReason;

  final DateTime? deletedAt;

  final String? filePath;

  final String? fileUrl;

  final String? fileName;

  final int? fileSize;

  final String? mimeType;

  final DateTime? uploadedAt;

  final DateTime createdAt;

  final DateTime updatedAt;

  factory ResidencePermitModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ResidencePermitModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      documentType:
          json['document_type'] as String,
      permitNumber:
          json['document_number'] as String,
      fullName:
          json['full_name'] as String,
      countryCode:
          json['country_code'] as String,
      status:
          json['status'] as String,
      issuedDate: json['issued_date'] == null
          ? null
          : DateTime.parse(
              json['issued_date'] as String,
            ),
      expiryDate: json['expiry_date'] == null
          ? null
          : DateTime.parse(
              json['expiry_date'] as String,
            ),
      verificationMethod:
          json['verification_method']
              as String?,
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(
              json['verified_at'] as String,
            ),
      verifiedBy:
          json['verified_by'] as String?,
      rejectedReason:
          json['rejected_reason'] as String?,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(
              json['deleted_at'] as String,
            ),
      filePath:
          json['file_path'] as String?,
      fileUrl:
          json['file_url'] as String?,
      fileName:
          json['file_name'] as String?,
      fileSize:
          json['file_size'] as int?,
      mimeType:
          json['mime_type'] as String?,
      uploadedAt: json['uploaded_at'] == null
          ? null
          : DateTime.parse(
              json['uploaded_at'] as String,
            ),
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'document_type': documentType,
      'document_number': permitNumber,
      'full_name': fullName,
      'country_code': countryCode,
      'status': status,
      'issued_date':
          issuedDate?.toIso8601String(),
      'expiry_date':
          expiryDate?.toIso8601String(),
      'verification_method':
          verificationMethod,
      'verified_at':
          verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'rejected_reason': rejectedReason,
      'deleted_at':
          deletedAt?.toIso8601String(),
      'file_path': filePath,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'uploaded_at':
          uploadedAt?.toIso8601String(),
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt.toIso8601String(),
    };
  }

  ResidencePermit toEntity() {
    return ResidencePermit(
      id: id,
      ownerId: ownerId,
      documentType: documentType,
      permitNumber: permitNumber,
      fullName: fullName,
      countryCode: countryCode,
      status: status,
      issuedDate: issuedDate,
      expiryDate: expiryDate,
      verificationMethod:
          verificationMethod,
      verifiedAt: verifiedAt,
      verifiedBy: verifiedBy,
      rejectedReason: rejectedReason,
      deletedAt: deletedAt,
      filePath: filePath,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      uploadedAt: uploadedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ResidencePermitModel.fromEntity(
    ResidencePermit entity,
  ) {
    return ResidencePermitModel(
      id: entity.id,
      ownerId: entity.ownerId,
      documentType: entity.documentType,
      permitNumber: entity.permitNumber,
      fullName: entity.fullName,
      countryCode: entity.countryCode,
      status: entity.status,
      issuedDate: entity.issuedDate,
      expiryDate: entity.expiryDate,
      verificationMethod:
          entity.verificationMethod,
      verifiedAt: entity.verifiedAt,
      verifiedBy: entity.verifiedBy,
      rejectedReason:
          entity.rejectedReason,
      deletedAt: entity.deletedAt,
      filePath: entity.filePath,
      fileUrl: entity.fileUrl,
      fileName: entity.fileName,
      fileSize: entity.fileSize,
      mimeType: entity.mimeType,
      uploadedAt: entity.uploadedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}