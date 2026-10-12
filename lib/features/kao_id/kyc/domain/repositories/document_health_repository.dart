import 'dart:async';

abstract class DocumentHealthRepository {
  Future<Map<String, dynamic>> load(String? profile);
  Future<void> revoke(String document, String reason);
}
