
abstract interface class StaffRepository {
  Future<Map<String, dynamic>> load();
  Future<void> assign(String target, String role);
  Future<void> revoke(String id);
}
