import 'package:equatable/equatable.dart';

import '../enums/document_type_enum.dart';

/// Entity สำหรับประเภทเอกสาร
///
/// ใช้เก็บข้อมูลประเภทเอกสารที่ระบบรองรับ
/// เช่น บัตรประชาชน, Passport, Residence Card
final class DocumentType extends Equatable {
  const DocumentType({
    required this.id,
    required this.type,
    required this.code,
    required this.name,
    required this.description,
    required this.isRequired,
    required this.isActive,
  });

  /// รหัสประเภทเอกสาร
  final String id;

  /// ประเภทมาตรฐานของระบบ
  final DocumentTypeEnum type;

  /// Code สำหรับอ้างอิงในระบบ
  final String code;

  /// ชื่อประเภทเอกสาร
  final String name;

  /// รายละเอียด
  final String description;

  /// บังคับใช้หรือไม่
  final bool isRequired;

  /// เปิดใช้งานหรือไม่
  final bool isActive;

  @override
  List<Object?> get props => [
        id,
        type,
        code,
        name,
        description,
        isRequired,
        isActive,
      ];

  DocumentType copyWith({
    String? id,
    DocumentTypeEnum? type,
    String? code,
    String? name,
    String? description,
    bool? isRequired,
    bool? isActive,
  }) {
    return DocumentType(
      id: id ?? this.id,
      type: type ?? this.type,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      isActive: isActive ?? this.isActive,
    );
  }
}