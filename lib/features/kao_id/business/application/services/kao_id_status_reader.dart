import '../../../issuance/domain/repositories/kao_id_issuance_repository.dart';

/// True when the signed-in person holds an active personal Kao ID.
typedef KaoIdStatusReader = Future<bool> Function();

KaoIdStatusReader kaoIdStatusReader(KaoIdIssuanceRepository repository) =>
    () async => (await repository.getCurrentIdentity())?.isActive ?? false;
