import 'dart:async';

abstract class WalletRepository {
  Future<Map<String, dynamic>> load(String user, {String? time, String? id});
}
