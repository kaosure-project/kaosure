enum SsoFailureCode {
  session,
  requestNotFound,
  appNotAllowed,
  invalidRedirect,
  ownerRequired,
  mfaRequired,
  invalidClient,
  oauthClientNotFound,
  clientAlreadyRegistered,
  unknown,
}

final class SsoFailure implements Exception {
  const SsoFailure(this.code);

  final SsoFailureCode code;

  @override
  String toString() => 'SsoFailure(${code.name})';
}
