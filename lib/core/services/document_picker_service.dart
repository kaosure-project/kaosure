import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

final class PickedDocument {
  const PickedDocument({
    required this.name,
    required this.bytes,
    required this.extension,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String extension;
  final String? mimeType;
}

final class DocumentPickerService {
  const DocumentPickerService();

  Future<PickedDocument?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
      ],
      withData: true,
    );

    if (result == null) {
      return null;
    }

    final file = result.files.first;

    if (file.bytes == null) {
      return null;
    }

    return PickedDocument(
  name: file.name,
  bytes: file.bytes!,
  extension: file.extension ?? '',
  mimeType: null,
);
  }
}