import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'image_processor_service.dart';

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

enum ImageType {
  avatar,
  logo,
}

final class ImagePickerService {
  const ImagePickerService();

  Future<PickedImage?> pickImage({
    ImageType type = ImageType.avatar,
  }) async {
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

    final processor = const ImageProcessorService();

    late final Uint8List processedBytes;

    switch (type) {
      case ImageType.avatar:
        processedBytes =
            await processor.processAvatar(file.bytes!);
        break;

      case ImageType.logo:
        processedBytes =
            await processor.processLogo(file.bytes!);
        break;
    }

    return PickedImage(
      bytes: processedBytes,
      fileName: file.name,
      fileSize: processedBytes.length,
      extension: 'jpg',
    );
  }
}