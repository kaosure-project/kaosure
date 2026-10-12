
abstract class LifecycleRepository {
  Future<Map<String, dynamic>> snapshot();
  Future<void> submit(String kind, String reason);
  Future<void> cancel(String id);
}
