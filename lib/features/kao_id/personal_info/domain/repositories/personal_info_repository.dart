import '../entities/personal_info.dart';
import '../entities/sensitive_field.dart';

abstract interface class PersonalInfoRepository {
  /// Owner summary with sensitive values already masked by the server.
  Future<PersonalInfo> load();

  /// Re-checks the password; throws [PersonalInfoFailure] with code `password` on mismatch.
  Future<RevealGrant> unlock(String password);

  /// Full value of one field; every call is audited server-side.
  Future<String> reveal(RevealGrant grant, SensitiveField field);

  Future<void> release(RevealGrant grant);
}
