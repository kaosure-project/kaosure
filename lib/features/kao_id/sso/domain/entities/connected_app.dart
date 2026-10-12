import 'sso_app.dart';

/// An app the member has granted access to.
final class ConnectedApp {
  const ConnectedApp({
    required this.clientId,
    required this.name,
    required this.scopes,
    required this.grantedAt,
    this.clientUri,
    this.app,
  });

  final String clientId;
  final String name;
  final List<String> scopes;
  final DateTime grantedAt;
  final Uri? clientUri;
  final SsoApp? app;

  String get displayName => app?.displayName ?? name;
}
