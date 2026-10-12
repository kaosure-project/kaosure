import '../entities/authorization_request.dart';
import '../entities/connected_app.dart';

/// Kao ID's side of the OAuth 2.1 authorization flow and the member's grants.
abstract interface class OAuthConsentRepository {
  String? currentUserId();

  Future<AuthorizationRequest> load(String authorizationId);

  /// Returns the app's redirect URL carrying the authorization code.
  Future<Uri> approve(String authorizationId);

  /// Returns the app's redirect URL carrying `error=access_denied`.
  Future<Uri> deny(String authorizationId);

  Future<List<ConnectedApp>> connectedApps();

  /// Withdraws consent; the app's tokens for this member stop working.
  Future<void> revoke(String clientId);
}
