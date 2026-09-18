import '../entities/kao_id_identity.dart';

abstract interface class KaoIdIssuanceRepository {
  Future<KaoIdIdentity?> getCurrentIdentity();

  Future<String> issueCurrentUserKaoId();
}
