import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service สำหรับอัปโหลดเอกสาร KYC
/// และเอกสาร Identity ไปยัง Supabase Storage.
///
/// Bucket:
/// kyc-documents
///
/// คืนค่าเป็น Storage Path
/// ไม่ใช่ Public URL
final class DocumentUploadService {
  const DocumentUploadService(
    this._client,
  );

  final SupabaseClient _client;

  static const _uuid = Uuid();

  /// Storage bucket ที่ระบบใช้งานอยู่ในปัจจุบัน
  static const String bucket =
      'kyc-documents';

  Future<String> upload({
    required PlatformFile file,
    required String folder,
    String? mimeType,
  }) async {
    final bytes = file.bytes;

    if (bytes == null) {
      throw Exception(
        'File bytes not found.',
      );
    }

    return uploadBytes(
      bytes: Uint8List.fromList(bytes),
      fileName: file.name,
      folder: folder,
      mimeType: mimeType,
    );
  }

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    String? mimeType,
  }) async {
    final user =
        _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User is not authenticated.',
      );
    }

    if (bytes.isEmpty) {
      throw Exception(
        'File is empty.',
      );
    }

    final normalizedFileName =
        fileName.trim();

    if (normalizedFileName.isEmpty) {
      throw Exception(
        'File name is empty.',
      );
    }

    final normalizedFolder =
        folder.trim();

    if (normalizedFolder.isEmpty) {
      throw Exception(
        'Upload folder is empty.',
      );
    }

    final extension =
        path.extension(normalizedFileName);

    final generatedName =
        '${_uuid.v4()}'
        '${extension.toLowerCase()}';

    final storagePath =
        '${user.id}/'
        '$normalizedFolder/'
        '$generatedName';

    final contentType =
        mimeType ?? _resolveMimeType(
          extension,
        );

    await _client.storage
        .from(bucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType,
          ),
        );

    return storagePath;
  }

  Future<String> createSignedUrl({
    required String storagePath,
    int expiresIn = 300,
  }) {
    return _client.storage
        .from(bucket)
        .createSignedUrl(
          storagePath,
          expiresIn,
        );
  }

  Future<void> delete({
    required String storagePath,
  }) async {
    final normalizedPath =
        storagePath.trim();

    if (normalizedPath.isEmpty) {
      return;
    }

    await _client.storage
        .from(bucket)
        .remove([
          normalizedPath,
        ]);
  }

  static String? _resolveMimeType(
    String extension,
  ) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';

      case '.png':
        return 'image/png';

      case '.pdf':
        return 'application/pdf';

      default:
        return null;
    }
  }
}