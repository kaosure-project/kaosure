import 'dart:async';

abstract class AccountAccessRepository {
  String? get userId;
  Stream<void> get changes;
  Future<String> check();
  Future<void> signOut();
}
