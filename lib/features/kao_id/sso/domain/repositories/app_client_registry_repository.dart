import '../entities/app_client.dart';

/// Company-owner registry of sub-apps allowed to sign members in with Kao ID.
abstract interface class AppClientRegistryRepository {
  Future<List<AppClient>> list();

  Future<void> save(AppClientDraft draft);

  Future<void> setActive(String appCode, {required bool active});
}
