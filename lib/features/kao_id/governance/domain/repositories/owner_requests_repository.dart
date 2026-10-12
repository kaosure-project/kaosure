
abstract class OwnerRequestsRepository {
  Future<List<Map<String, dynamic>>> list(String status, Map<String, dynamic>? cursor);
  Future<Map<String, dynamic>> checks(String id);
  Future<void> reject(String id, String reason);
}
