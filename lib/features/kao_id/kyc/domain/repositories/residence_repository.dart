import 'package:flutter/foundation.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/residence.dart';

abstract interface class ResidenceRepository {
  Future<String> owner();
  Future<ResidenceRecord?> latest(String owner);
  Future<bool> hasPendingRequest(String owner);
  Future<ResidenceRecord> submit(ResidenceDraft draft);
  Future<Uint8List> preview(String owner, String path);
}
