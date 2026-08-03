import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

final class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.fileName,
    required this.fileSize,
    required this.extension,
  });

  final Uint8List bytes;
  final String fileName;
  final int fileSize;
  final String? extension;
}

final class ImagePickerService {
  const ImagePickerService();

  Future<PickedImage?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;

    if (file.bytes == null) {
      return null;
    }

    return PickedImage(
      bytes: file.bytes!,
      fileName: file.name,
      fileSize: file.size,
      extension: file.extension,
    );
  }
}