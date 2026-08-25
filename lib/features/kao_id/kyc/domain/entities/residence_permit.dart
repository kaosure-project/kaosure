import 'package:equatable/equatable.dart';

final class ResidencePermit extends Equatable {
  const ResidencePermit({
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

  /// pending
  /// approved
  /// rejected
  /// expired
  final String status;

  final DateTime? issuedDate;

  final DateTime? expiryDate;

  /// manual
  /// ocr
  /// ai
  /// ndid
  /// third_party
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

  @override
  List<Object?> get props => [
        id,
        ownerId,
        documentType,
        permitNumber,
        fullName,
        countryCode,
        status,
        issuedDate,
        expiryDate,
        verificationMethod,
        verifiedAt,
        verifiedBy,
        rejectedReason,
        deletedAt,
        filePath,
        fileUrl,
        fileName,
        fileSize,
        mimeType,
        uploadedAt,
        createdAt,
        updatedAt,
      ];

  ResidencePermit copyWith({
    String? id,
    String? ownerId,
    String? documentType,
    String? permitNumber,
    String? fullName,
    String? countryCode,
    String? status,
    DateTime? issuedDate,
    DateTime? expiryDate,
    String? verificationMethod,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? rejectedReason,
    DateTime? deletedAt,
    String? filePath,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    DateTime? uploadedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ResidencePermit(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      documentType: documentType ?? this.documentType,
      permitNumber: permitNumber ?? this.permitNumber,
      fullName: fullName ?? this.fullName,
      countryCode: countryCode ?? this.countryCode,
      status: status ?? this.status,
      issuedDate: issuedDate ?? this.issuedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      verificationMethod:
          verificationMethod ?? this.verificationMethod,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      rejectedReason:
          rejectedReason ?? this.rejectedReason,
      deletedAt: deletedAt ?? this.deletedAt,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}