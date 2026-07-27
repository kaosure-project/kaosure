import 'package:equatable/equatable.dart';

import '../enums/document_status.dart';
import '../value_objects/document_number.dart';
import '../value_objects/issued_date.dart';
import '../value_objects/expiry_date.dart';

import 'document_file.dart';
import 'document_type.dart';
import 'verification.dart';

/// Aggregate Root ของ Identity Document
///
/// เป็น Entity หลักของโดเมน Identity
/// ใช้รวมข้อมูลเอกสารทั้งหมดไว้ในที่เดียว
final class IdentityDocument extends Equatable {
  const IdentityDocument({
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

  /// รหัสเอกสาร
  final String id;

  /// เจ้าของเอกสาร (User ID)
  final String ownerId;

  /// ประเภทเอกสาร
  final DocumentType documentType;

  /// หมายเลขเอกสาร
  final DocumentNumber documentNumber;

  /// วันที่ออกเอกสาร
  final IssuedDate? issuedDate;

  /// วันหมดอายุ
  final ExpiryDate? expiryDate;

  /// สถานะเอกสาร
  final DocumentStatus status;

  /// ไฟล์เอกสาร
  final List<DocumentFile> files;

  /// ข้อมูลการตรวจสอบ
  final Verification verification;

  /// วันที่สร้าง
  final DateTime createdAt;

  /// วันที่แก้ไขล่าสุด
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
        verification,
        createdAt,
        updatedAt,
      ];

  IdentityDocument copyWith({
    String? id,
    String? ownerId,
    DocumentType? documentType,
    DocumentNumber? documentNumber,
    IssuedDate? issuedDate,
    ExpiryDate? expiryDate,
    DocumentStatus? status,
    List<DocumentFile>? files,
    Verification? verification,
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
      verification: verification ?? this.verification,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}