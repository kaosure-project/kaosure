import 'package:equatable/equatable.dart';

import '../enums/document_status.dart';
import '../enums/document_type_enum.dart';
import '../value_objects/document_number.dart';
import '../value_objects/issued_date.dart';
import '../value_objects/expiry_date.dart';

import 'document_file.dart';

final class IdentityDocument extends Equatable {
  const IdentityDocument({
    required this.id,
    required this.ownerId,
    required this.documentType,
    required this.documentNumber,
    required this.status,
    required this.files,
    required this.createdAt,
    required this.updatedAt,
    this.issuedDate,
    this.expiryDate,
  });

  final String id;
  final String ownerId;

  /// เปลี่ยนจาก DocumentType เป็น DocumentTypeEnum
  final DocumentTypeEnum documentType;

  final DocumentNumber documentNumber;
  final IssuedDate? issuedDate;
  final ExpiryDate? expiryDate;
  final DocumentStatus status;
  final List<DocumentFile> files;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        ownerId,
        documentType,
        documentNumber,
        issuedDate,
        expiryDate,
        status,
        files,
        createdAt,
        updatedAt,
      ];

  IdentityDocument copyWith({
    String? id,
    String? ownerId,
    DocumentTypeEnum? documentType,
    DocumentNumber? documentNumber,
    IssuedDate? issuedDate,
    ExpiryDate? expiryDate,
    DocumentStatus? status,
    List<DocumentFile>? files,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IdentityDocument(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      issuedDate: issuedDate ?? this.issuedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      files: files ?? this.files,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}