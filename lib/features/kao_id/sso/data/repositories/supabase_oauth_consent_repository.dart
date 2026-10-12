import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/authorization_request.dart';
import '../../domain/entities/connected_app.dart';
import '../../domain/entities/sso_app.dart';
import '../../domain/failures/sso_failure.dart';
import '../../domain/repositories/oauth_consent_repository.dart';
import '../mappers/sso_failure_mapper.dart';
import '../models/sso_app_model.dart';

/// Consent decisions go to Supabase Auth's OAuth 2.1 server; app names, claims
/// and last use come from the Kao ID registry.
final class SupabaseOAuthConsentRepository implements OAuthConsentRepository {
  SupabaseOAuthConsentRepository(this._client);

  final SupabaseClient _client;

  @override
  String? currentUserId() => _client.auth.currentUser?.id;

  @override
  Future<AuthorizationRequest> load(String authorizationId) => _pinned((userId) async {
    final response = await _client.auth.oauth.getAuthorizationDetails(authorizationId);
    switch (response) {
      case OAuthAuthorizationRedirectResponse(:final redirectUrl):
        return ConsentAlreadyGiven(redirectUrl: _uri(redirectUrl));
      case OAuthAuthorizationDetailsResponse details:
        if (details.user.id != userId) throw const SsoFailure(SsoFailureCode.session);
        final apps = await _directory();
        final clientId = details.client.clientId.toLowerCase();
        return ConsentRequest(
          authorizationId: details.authorizationId,
          clientId: clientId,
          clientName: details.client.clientName ?? clientId,
          scopes: [
            for (final scope in (details.scope ?? '').split(' '))
              if (scope.isNotEmpty) scope,
          ],
          redirectUri: _uri(details.redirectUri),
          clientUri: Uri.tryParse(details.client.clientUri ?? ''),
          logoUri: Uri.tryParse(details.client.logoUri ?? ''),
          app: apps[clientId],
        );
    }
  });

  @override
  Future<Uri> approve(String authorizationId) =>
      _pinned((_) async => _uri((await _client.auth.oauth.approveAuthorization(authorizationId)).redirectUrl));

  @override
  Future<Uri> deny(String authorizationId) =>
      _pinned((_) async => _uri((await _client.auth.oauth.denyAuthorization(authorizationId)).redirectUrl));

  @override
  Future<List<ConnectedApp>> connectedApps() => _pinned((_) async {
    final grants = await _client.auth.oauth.listGrants();
    final apps = await _directory();
    return [
      for (final grant in grants)
        ConnectedApp(
          clientId: grant.client.clientId.toLowerCase(),
          name: grant.client.clientName ?? grant.client.clientId,
          scopes: grant.scopes,
          grantedAt: grant.grantedAt.toLocal(),
          clientUri: Uri.tryParse(grant.client.clientUri ?? ''),
          app: apps[grant.client.clientId.toLowerCase()],
        ),
    ]..sort((a, b) => b.grantedAt.compareTo(a.grantedAt));
  });

  @override
  Future<void> revoke(String clientId) => _pinned((_) => _client.auth.oauth.revokeGrant(clientId));

  @override
  Future<bool> isAppPage(Uri target) async {
    try {
      return await _client.rpc<dynamic>('kao_id_sign_out_return_ok', params: {'p_url': target.toString()}) == true;
    } catch (error) {
      throw ssoFailureFrom(error);
    }
  }

  Future<Map<String, SsoApp>> _directory() async {
    final rows = await _client.rpc<dynamic>('app_directory_r18');
    final apps = [
      for (final row in rows is List ? rows : const [])
        if (row is Map) SsoAppModel.fromJson(Map<String, dynamic>.from(row)),
    ];
    return {for (final app in apps) app.clientId: app};
  }

  Uri _uri(String? raw) {
    final uri = Uri.tryParse(raw ?? '');
    if (uri == null || !uri.isAbsolute) throw const SsoFailure(SsoFailureCode.invalidRedirect);
    return uri;
  }

  /// Fails if the signed-in member changes while the call is in flight.
  Future<T> _pinned<T>(Future<T> Function(String userId) run) async {
    try {
      final userId = currentUserId();
      if (userId == null) throw const SsoFailure(SsoFailureCode.session);
      final result = await run(userId);
      if (currentUserId() != userId) throw const SsoFailure(SsoFailureCode.session);
      return result;
    } catch (error) {
      throw ssoFailureFrom(error);
    }
  }
}
