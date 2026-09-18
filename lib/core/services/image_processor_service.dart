import 'dart:typed_data';

import 'package:image/image.dart' as img;

final class ImageProcessorService {
  const ImageProcessorService();

  /// ===========================
  /// Avatar (รูปคน)
  /// Crop ตรงกลาง
  /// ===========================
  Future<Uint8List> processAvatar(
    Uint8List bytes,
  ) async {
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Cannot decode image.');
    }

    final avatar = img.copyResizeCropSquare(
      image,
      size: 512,
    );

    final jpg = img.encodeJpg(
      avatar,
      quality: 85,
    );

    return Uint8List.fromList(jpg);
  }

  /// ===========================
  /// Logo (ไม่ครอป)
  /// ย่อให้อยู่ในกรอบ
  /// ===========================
  Future<Uint8List> processLogo(
    Uint8List bytes,
  ) async {
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Cannot decode image.');
    }

    const canvasSize = 512;

    final resized = img.copyResize(
      image,
      width: image.width > image.height ? canvasSize : null,
      height: image.height > image.width ? canvasSize : null,
      interpolation: img.Interpolation.average,
    );

    final canvas = img.Image(
      width: canvasSize,
      height: canvasSize,
    );

    img.fill(
      canvas,
      color: img.ColorRgb8(255, 255, 255),
    );

    final dx = (canvas.width - resized.width) ~/ 2;
    final dy = (canvas.height - resized.height) ~/ 2;

    img.compositeImage(
      canvas,
      resized,
      dstX: dx,
      dstY: dy,
    );

    final jpg = img.encodeJpg(
      canvas,
      quality: 85,
    );

    return Uint8List.fromList(jpg);
  }
}