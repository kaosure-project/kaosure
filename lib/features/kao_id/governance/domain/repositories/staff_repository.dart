
abstract interface class StaffRepository {
  Future<Map<String, dynamic>> load();
  Future<void> assign(String target, String role);
  Future<void> revoke(String id);
  Future<void> createRole(String code, String name, String? description);
  Future<void> updateRole(String code, String name, String? description, bool active);
  Future<void> setPermission(String role, String permission, bool enabled);
  Future<void> cancelGrant(String id);
  Future<void> decideGrant(String id, bool approve, String? reason);

  /// Role requests waiting for a second approver; needs `admin.assignments.approve`.
  Future<List<Map<String, dynamic>>> grantQueue();
}
