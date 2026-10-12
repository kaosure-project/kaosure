import 'dart:async';

abstract class SessionsRepository {
  Future<List<Map<String, dynamic>>> list();
  Future<void> revoke(String? id, {bool others = false, required String expectedUser});
}
