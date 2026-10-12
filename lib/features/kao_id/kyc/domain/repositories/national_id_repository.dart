import 'package:flutter/foundation.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/national_id.dart';

abstract interface class NationalIdRepository {
  Future<String> owner();
  Future<NationalIdRecord?> latest(String owner);
  Future<NationalIdRecord> submit(NationalIdDraft draft);
  Future<Uint8List> preview(String owner, String path);
}
