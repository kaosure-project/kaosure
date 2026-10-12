
abstract interface class AccountStateRepository {
  Future<List<Map<String, dynamic>>> history(String target);
  Future<void> change(String target, String expected, String next, String reason);
}
