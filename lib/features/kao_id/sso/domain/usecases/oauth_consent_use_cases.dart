import '../entities/authorization_request.dart';
import '../entities/connected_app.dart';
import '../failures/sso_failure.dart';
import '../repositories/oauth_consent_repository.dart';

final class OAuthConsentUseCases {
  const OAuthConsentUseCases(this._repository);

  final OAuthConsentRepository _repository;

  static final RegExp _authorizationId = RegExp(r'^[A-Za-z0-9_-]{8,128}$');
  static final RegExp _nativeScheme = RegExp(r'^[a-z][a-z0-9+-]*(\.[a-z0-9+-]+)+$');

  static bool isValidAuthorizationId(String? value) => value != null && _authorizationId.hasMatch(value);

  /// Web apps over https (http only on loopback while developing), or a native
  /// app's reverse-domain scheme (RFC 8252).
  static bool isSafeRedirect(Uri uri) {
    if (!uri.isAbsolute || uri.userInfo.isNotEmpty) return false;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'https') return uri.host.isNotEmpty;
    if (scheme == 'http') {
      return const {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
    }
    return _nativeScheme.hasMatch(scheme);
  }

  String? currentUserId() => _repository.currentUserId();

  Future<AuthorizationRequest> load(String authorizationId) {
    if (!isValidAuthorizationId(authorizationId)) {
      throw const SsoFailure(SsoFailureCode.requestNotFound);
    }
    return _repository.load(authorizationId);
  }

  /// Only active registered apps may receive tokens.
  Future<Uri> approve(ConsentRequest request) async {
    if (!request.appAllowed) throw const SsoFailure(SsoFailureCode.appNotAllowed);
    return _safe(await _repository.approve(request.authorizationId));
  }

  Future<Uri> deny(ConsentRequest request) async => _safe(await _repository.deny(request.authorizationId));

  Uri continueApproved(ConsentAlreadyGiven request) => _safe(request.redirectUrl);

  /// "Use another account": the app gets `error=account_selection_required`
  /// with its own `state` back, and starts a fresh login once Kao ID has
  /// signed out. A pending request is denied so its code can never be issued.
  Future<Uri> switchAccount(AuthorizationRequest request) async {
    final reply = _safe(switch (request) {
      ConsentRequest() => await _repository.deny(request.authorizationId),
      ConsentAlreadyGiven(:final redirectUrl) => redirectUrl,
    });
    final state = reply.queryParameters['state'];
    return reply.replace(queryParameters: {'error': 'account_selection_required', 'state': ?state}).removeFragment();
  }

  /// Where `/logout` may send the member afterwards: only an http(s) page of an
  /// active registered app, without query or fragment. Null means Kao ID home.
  Future<Uri?> signOutReturn(String? raw) async {
    final target = Uri.tryParse(raw?.trim() ?? '');
    if (target == null ||
        !isSafeRedirect(target) ||
        !const {'http', 'https'}.contains(target.scheme.toLowerCase()) ||
        target.hasQuery ||
        target.hasFragment) {
      return null;
    }
    try {
      return await _repository.isAppPage(target) ? target : null;
    } on SsoFailure {
      return null;
    }
  }

  Future<List<ConnectedApp>> connectedApps() => _repository.connectedApps();

  Future<void> revoke(String clientId) => _repository.revoke(clientId);

  Uri _safe(Uri uri) {
    if (!isSafeRedirect(uri)) throw const SsoFailure(SsoFailureCode.invalidRedirect);
    return uri;
  }
}
