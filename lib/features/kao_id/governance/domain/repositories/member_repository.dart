
abstract interface class MemberRepository {
  Future<bool> canRead();
  Future<Map<String, dynamic>?> find(String query);
}
