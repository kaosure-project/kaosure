final class KaoIdIdentity {
  const KaoIdIdentity({
    required this.id,
    required this.profileId,
    required this.kaoId,
    required this.status,
    required this.issuedAt,
  });

  final String id;
  final String profileId;
  final String kaoId;
  final String status;
  final DateTime issuedAt;

  bool get isActive => status == 'active';
}
