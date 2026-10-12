import 'sso_app.dart';

/// An OAuth authorization request that a sub-app sent to Kao ID.
sealed class AuthorizationRequest {
  const AuthorizationRequest();
}

/// The member still has to approve or deny.
final class ConsentRequest extends AuthorizationRequest {
  const ConsentRequest({
    required this.authorizationId,
    required this.clientId,
    required this.clientName,
    required this.scopes,
    required this.redirectUri,
    required this.app,
    this.clientUri,
    this.logoUri,
  });

  final String authorizationId;
  final String clientId;
  final String clientName;
  final List<String> scopes;
  final Uri redirectUri;
  final Uri? clientUri;
  final Uri? logoUri;

  /// Registry entry for the requesting client; null when Kao ID does not know it.
  final SsoApp? app;

  /// Only active registered apps may receive a member's tokens.
  bool get appAllowed => app?.active == true;

  String get displayName => app?.displayName ?? clientName;
}

/// The member approved this client before, so the server only returns where to
/// go. The response does not name the client; the request guard still rejects
/// tokens of unregistered or suspended apps.
final class ConsentAlreadyGiven extends AuthorizationRequest {
  const ConsentAlreadyGiven({required this.redirectUrl});

  final Uri redirectUrl;
}
