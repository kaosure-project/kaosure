import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kao_id_identity_model.dart';

final class SupabaseKaoIdIssuanceDataSource {
  const SupabaseKaoIdIssuanceDataSource(this._client);

  final SupabaseClient _client;

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }
    return user;
  }

  Future<KaoIdIdentityModel?> getCurrentIdentity() async {
    final user = _requireUser();

    final response = await _client
        .from('kao_id_identities')
        .select('id, profile_id, kao_id, status, issued_at')
        .eq('profile_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return KaoIdIdentityModel.fromJson(response);
  }

  Future<String> issueCurrentUserKaoId() async {
    final user = _requireUser();
    final result = await _client.rpc(
      'issue_kao_id',
      params: {'p_profile_id': user.id},
    );

    if (result is! String || result.isEmpty) {
      throw StateError('Kao ID issuance returned an invalid result.');
    }
    return result;
  }
}
