import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_client.dart';
import '../../domain/repositories/app_client_registry_repository.dart';
import '../mappers/sso_failure_mapper.dart';
import '../models/app_client_model.dart';

final class SupabaseAppClientRegistryRepository implements AppClientRegistryRepository {
  SupabaseAppClientRegistryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AppClient>> list() => _guard(() async {
        final rows = await _client.rpc<dynamic>('app_clients_list_r18');
        return [
          for (final row in rows is List ? rows : const [])
            if (row is Map) AppClientModel.fromJson(Map<String, dynamic>.from(row)),
        ];
      });

  @override
  Future<void> save(AppClientDraft draft) => _guard(() => _client.rpc<void>(
        'app_client_save_r18',
        params: {
          'p_app_code': draft.appCode,
          'p_client_id': draft.clientId,
          'p_display_name': draft.displayName,
          'p_first_party': draft.firstParty,
          'p_claims': [for (final claim in draft.claims) claim.name],
          'p_rpcs': draft.rpcs,
          'p_tables': draft.tables,
        },
      ));

  @override
  Future<void> setActive(String appCode, {required bool active}) => _guard(() => _client.rpc<void>(
        'app_client_set_status_r18',
        params: {'p_app_code': appCode, 'p_status': active ? 'active' : 'suspended'},
      ));

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (error) {
      throw ssoFailureFrom(error);
    }
  }
}
