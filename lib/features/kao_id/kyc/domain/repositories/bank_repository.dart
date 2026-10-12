import 'package:flutter/foundation.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/bank_account.dart';

abstract interface class BankRepository {
  Future<String> owner();
  Future<List<BankRecord>> list(String owner);
  Future<BankRecord> submit(BankDraft draft);
  Future<Uint8List> preview(String owner, String path);
}
