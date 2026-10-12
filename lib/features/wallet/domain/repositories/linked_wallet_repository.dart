import 'dart:async';

abstract class LinkedWalletRepository {
  Future<List<Map<String,dynamic>>> load(String user,String? profile);
}
