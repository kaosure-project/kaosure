import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/services/document_picker_service.dart';

import '../../data/services/slip_image_preparer.dart';

/// Picks the transfer slip and returns it as an upload-ready JPEG, or null when cancelled.
final slipPickerProvider = Provider<Future<Uint8List?> Function()>((ref) {
  return () async {
    final document = await const DocumentPickerService().pickImage();
    if (document == null) return null;
    return compute(prepareSlipImage, document.bytes);
  };
});
