import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:kaosure/features/kao_id/kyc/domain/failures/national_id_failure.dart';

/// Decode only JPEG/PNG, cap input, normalize orientation and re-encode JPEG.
/// Processing runs off the UI isolate on native platforms via compute().
Uint8List prepareIdImage(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
    throw const NationalIdFailure('file');
  }
  final jpeg = bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255;
  final png = bytes.length > 8 && listEquals(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  if (!jpeg && !png) { throw const NationalIdFailure('file'); }
  final img.Decoder decoder = jpeg ? img.JpegDecoder() : img.PngDecoder();
  final info = decoder.startDecode(bytes);
  if (info == null || info.width < 100 || info.height < 100 ||
      info.width * info.height > 24000000 || info.numFrames > 1) {
    throw const NationalIdFailure('file');
  }
  final decoded = img.decodeImage(bytes);
  if (decoded == null || decoded.width < 100 || decoded.height < 100 ||
      decoded.width * decoded.height > 24000000) {
    throw const NationalIdFailure('file');
  }
  final oriented = img.bakeOrientation(decoded);
  final output = Uint8List.fromList(img.encodeJpg(oriented, quality: 90));
  if (output.length > 10 * 1024 * 1024) { throw const NationalIdFailure('file'); }
  return output;
}
