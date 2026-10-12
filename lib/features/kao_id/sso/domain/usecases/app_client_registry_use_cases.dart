import '../entities/app_client.dart';
import '../failures/sso_failure.dart';
import '../repositories/app_client_registry_repository.dart';

final class AppClientRegistryUseCases {
  const AppClientRegistryUseCases(this._repository);

  final AppClientRegistryRepository _repository;

  Future<List<AppClient>> list() => _repository.list();

  Future<void> save(AppClientDraft draft) {
    if (!draft.isValid) throw const SsoFailure(SsoFailureCode.invalidClient);
    return _repository.save(draft.normalized());
  }

  Future<void> setActive(String appCode, {required bool active}) =>
      _repository.setActive(appCode, active: active);
}
