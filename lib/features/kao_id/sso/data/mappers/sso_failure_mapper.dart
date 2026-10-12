import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/failures/sso_failure.dart';

SsoFailure ssoFailureFrom(Object error) {
  if (error is SsoFailure) return error;
  if (error is AuthException) {
    return SsoFailure(switch (error.statusCode) {
      '400' || '404' || '410' => SsoFailureCode.requestNotFound,
      _ => SsoFailureCode.session,
    });
  }
  if (error is PostgrestException) return SsoFailure(_codeFor(error.message));
  return const SsoFailure(SsoFailureCode.unknown);
}

SsoFailureCode _codeFor(String message) => switch (message) {
      'authentication_required' || 'session_required' => SsoFailureCode.session,
      'owner_required' => SsoFailureCode.ownerRequired,
      'mfa_required' => SsoFailureCode.mfaRequired,
      'invalid_app_client' || 'app_client_not_found' => SsoFailureCode.invalidClient,
      'oauth_client_not_found' => SsoFailureCode.oauthClientNotFound,
      'client_already_registered' => SsoFailureCode.clientAlreadyRegistered,
      'client_not_allowed' || 'client_scope_denied' => SsoFailureCode.appNotAllowed,
      _ => SsoFailureCode.unknown,
    };
