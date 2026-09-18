import '../../domain/entities/kao_id_identity.dart';
import '../../domain/repositories/kao_id_issuance_repository.dart';
import '../datasources/supabase_kao_id_issuance_datasource.dart';

final class KaoIdIssuanceRepositoryImpl implements KaoIdIssuanceRepository {
  const KaoIdIssuanceRepositoryImpl(this._dataSource);

  final SupabaseKaoIdIssuanceDataSource _dataSource;

  @override
  Future<KaoIdIdentity?> getCurrentIdentity() async {
    return (await _dataSource.getCurrentIdentity())?.toEntity();
  }

  @override
  Future<String> issueCurrentUserKaoId() {
    return _dataSource.issueCurrentUserKaoId();
  }
}
