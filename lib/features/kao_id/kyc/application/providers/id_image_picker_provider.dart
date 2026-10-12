import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kaosure/core/services/document_picker_service.dart';
import 'package:kaosure/features/kao_id/kyc/data/services/id_image_preparer.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/id_image.dart';

final nationalIdImagePickerProvider = Provider<Future<IdImage?> Function()>((ref) {
  return () async {
    final document = await const DocumentPickerService().pickImage();
    if (document == null) { return null; }
    return IdImage(document.name, await compute(prepareIdImage, document.bytes));
  };
});
