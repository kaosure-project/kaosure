import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../domain/failures/topup_failure.dart';

/// JPEG or PNG in, a JPEG of at most 2000 px on the long side out, so it stays
/// under the 5 MB `wallet-slips` limit. Runs through compute() on native platforms.
Uint8List prepareSlipImage(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 15 * 1024 * 1024) {
    throw const TopupFailure('slip_file');
  }
  final jpeg = bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255;
  final png = bytes.length > 8 && listEquals(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  if (!jpeg && !png) throw const TopupFailure('slip_file');
  final img.Decoder decoder = jpeg ? img.JpegDecoder() : img.PngDecoder();
  final info = decoder.startDecode(bytes);
  if (info == null || info.width < 200 || info.height < 200 || info.width * info.height > 40000000) {
    throw const TopupFailure('slip_file');
  }
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const TopupFailure('slip_file');
  var image = img.bakeOrientation(decoded);
  if (image.width > 2000 || image.height > 2000) {
    image = image.width >= image.height ? img.copyResize(image, width: 2000) : img.copyResize(image, height: 2000);
  }
  for (final quality in [88, 75, 60]) {
    final output = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    if (output.length <= 5 * 1024 * 1024) return output;
  }
  throw const TopupFailure('slip_file');
}
