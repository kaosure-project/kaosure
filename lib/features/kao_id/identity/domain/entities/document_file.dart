import 'package:equatable/equatable.dart';

/// Entity สำหรับไฟล์เอกสาร
///
/// ใช้แทนไฟล์ที่ผู้ใช้อัปโหลด เช่น
/// - รูปด้านหน้า
/// - รูปด้านหลัง
/// - PDF
/// - Selfie
///
/// ไม่มีหน้าที่ Upload หรือ Download ไฟล์
final class DocumentFile extends Equatable {
  const DocumentFile({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
    required this.uploadedAt,
  });

  /// รหัสไฟล์
  final String id;

  /// ชื่อไฟล์
  final String fileName;

  /// Path หรือ Storage Key
  final String filePath;

  /// ประเภทไฟล์ เช่น image/jpeg
  final String mimeType;

  /// ขนาดไฟล์ (Bytes)
  final int fileSize;

  /// วันที่อัปโหลด
  final DateTime uploadedAt;

  /// เป็นไฟล์รูปภาพหรือไม่
  bool get isImage => mimeType.startsWith('image/');

  /// เป็นไฟล์ PDF หรือไม่
  bool get isPdf => mimeType == 'application/pdf';

  @override
  List<Object?> get props => [
        id,
        fileName,
        filePath,
        mimeType,
        fileSize,
        uploadedAt,
      ];

  DocumentFile copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? mimeType,
    int? fileSize,
    DateTime? uploadedAt,
  }) {
    return DocumentFile(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}