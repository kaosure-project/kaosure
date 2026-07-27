import '../../domain/entities/document_file.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/entities/verification.dart';
import '../../domain/enums/document_status.dart';
import '../../domain/value_objects/document_number.dart';
import '../../domain/value_objects/expiry_date.dart';
import '../../domain/value_objects/issued_date.dart';

/// Data Model สำหรับรับส่งข้อมูลกับ Data Source
final class IdentityDocumentModel {
  const IdentityDocumentModel({
    required this.id,
    required this.ownerId,
    required this.documentType,
    required this.documentNumber,
    required this.status,
    required this.files,
    required this.verification,
    required this.createdAt,
    required this.updatedAt,
    this.issuedDate,
    this.expiryDate,
  });

  final String id;
  final String ownerId;
  final DocumentType documentType;
  final DocumentNumber documentNumber;
  final DocumentStatus status;
  final List<DocumentFile> files;
  final Verification verification;
  final IssuedDate? issuedDate;
  final ExpiryDate? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory IdentityDocumentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    throw UnimplementedError();
  }

  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}