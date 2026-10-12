
abstract class PartnerRepository {
  Future<List<Map<String, dynamic>>> list(String user);
  Future<void> create(String user, String code, String name, String environment, List<String> capabilities);
  Future<void> decide(String user, String id, int revision, String action, String reason);
}
