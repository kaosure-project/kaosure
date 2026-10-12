import 'package:flutter/foundation.dart';

abstract interface class KycReviewRepository {
  Future<bool> canReview();
  Future<List<Map<String, dynamic>>> queue();
  Future<Uint8List> preview(String path);
  Future<void> decide(String request, bool approve, String reason);
  Future<Map<String, dynamic>?> myIdentity();
  Future<String> issue();
}
