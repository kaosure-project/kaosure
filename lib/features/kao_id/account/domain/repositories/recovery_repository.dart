import 'package:flutter/foundation.dart';
import '../../../kyc/domain/entities/id_image.dart';

abstract class RecoveryRepository {
  Future<List<Map<String, dynamic>>> snapshot();
  Future<Map<String, dynamic>> prepare(String request, String type);
  Future<void> submit(Map<String, dynamic> draft, Map<String, dynamic> data, List<IdImage> files);
  Future<Uint8List> preview(String path);
}
