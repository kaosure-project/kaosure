import '../../domain/entities/document_file.dart';

final class DocumentFileModel {
  const DocumentFileModel({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
    required this.uploadedAt,
  });

  final String id;
  final String fileName;
  final String filePath;
  final String mimeType;
  final int fileSize;
  final DateTime uploadedAt;

  factory DocumentFileModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return DocumentFileModel(
      id: map['id'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      mimeType: map['mime_type'] as String,
      fileSize: map['file_size'] as int,
      uploadedAt: DateTime.parse(
        map['uploaded_at'] as String,
      ),
    );
  }

  factory DocumentFileModel.fromEntity(
    DocumentFile entity,
  ) {
    return DocumentFileModel(
      id: entity.id,
      fileName: entity.fileName,
      filePath: entity.filePath,
      mimeType: entity.mimeType,
      fileSize: entity.fileSize,
      uploadedAt: entity.uploadedAt,
    );
  }

  DocumentFile toEntity() {
    return DocumentFile(
      id: id,
      fileName: fileName,
      filePath: filePath,
      mimeType: mimeType,
      fileSize: fileSize,
      uploadedAt: uploadedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': mimeType,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}