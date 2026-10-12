import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/authorization_request.dart';
import '../../domain/failures/sso_failure.dart';
import '../../domain/usecases/oauth_consent_use_cases.dart';
import '../states/consent_state.dart';

/// Leaves Kao ID for the app's redirect URL in the same tab.
typedef SsoRedirect = Future<bool> Function(Uri target);

final class ConsentController extends StateNotifier<ConsentState> {
  ConsentController({required this._useCases, required this._redirect}) : super(const ConsentState());

  final OAuthConsentUseCases _useCases;
  final SsoRedirect _redirect;

  Future<void> approve(ConsentRequest request) => _leave(ConsentPhase.approving, () => _useCases.approve(request));

  Future<void> deny(ConsentRequest request) => _leave(ConsentPhase.denying, () => _useCases.deny(request));

  Future<void> continueApproved(ConsentAlreadyGiven request) =>
      _leave(ConsentPhase.redirecting, () async => _useCases.continueApproved(request));

  /// Hands the request back to the app for a fresh login, then ends the Kao ID
  /// session. Signing out may dispose this controller, so the redirect does
  /// not depend on it.
  Future<void> switchAccount(AuthorizationRequest request, {required Future<void> Function() signOut}) async {
    if (state.busy) return;
    state = const ConsentState(phase: ConsentPhase.switching);
    final redirect = _redirect;
    try {
      final target = await _useCases.switchAccount(request);
      await signOut();
      if (!await redirect(target)) throw const SsoFailure(SsoFailureCode.invalidRedirect);
    } on SsoFailure catch (failure) {
      if (mounted) state = ConsentState(failure: failure.code);
    } catch (_) {
      if (mounted) state = const ConsentState(failure: SsoFailureCode.unknown);
    }
  }

  Future<void> _leave(ConsentPhase phase, Future<Uri> Function() decide) async {
    if (state.busy) return;
    state = ConsentState(phase: phase);
    try {
      final target = await decide();
      if (!mounted) return;
      state = const ConsentState(phase: ConsentPhase.redirecting);
      if (!await _redirect(target)) throw const SsoFailure(SsoFailureCode.invalidRedirect);
    } on SsoFailure catch (failure) {
      if (mounted) state = ConsentState(failure: failure.code);
    } catch (_) {
      if (mounted) state = const ConsentState(failure: SsoFailureCode.unknown);
    }
  }
}
