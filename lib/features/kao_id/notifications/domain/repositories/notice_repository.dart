import 'dart:async';

abstract interface class NoticeRepository {
  Future<Map<String, dynamic>> inbox();
  Future<void> read(String id);
}
