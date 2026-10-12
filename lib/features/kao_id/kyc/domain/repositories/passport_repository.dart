import 'package:flutter/foundation.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/passport.dart';

abstract interface class PassportRepository {
  Future<String> owner();
  Future<PassportRecord?> latest(String owner);
  Future<bool> hasPendingRequest(String owner);
  Future<PassportRecord> submit(PassportDraft draft);
  Future<Uint8List> preview(String owner, String path);
}
