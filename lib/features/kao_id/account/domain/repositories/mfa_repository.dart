
abstract interface class MfaRepository {
  Future<Map<String, dynamic>> load();
  Future<Map<String, String>> enroll(String name, String password);
  Future<void> verify(String factor, String code);
  Future<void> cancelEnrollment(String factor);
  Future<void> enablePolicy();
}
