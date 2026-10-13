import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/application/kao_id_sso_handoff.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../data/providers/sso_repository_providers.dart';
import '../../domain/entities/app_client.dart';
import '../../domain/entities/authorization_request.dart';
import '../../domain/entities/connected_app.dart';
import '../../domain/failures/sso_failure.dart';
import '../../domain/usecases/app_client_registry_use_cases.dart';
import '../../domain/usecases/oauth_consent_use_cases.dart';
import '../controllers/consent_controller.dart';
import '../states/consent_state.dart';

final oauthConsentUseCasesProvider = Provider<OAuthConsentUseCases>((ref) {
  return OAuthConsentUseCases(ref.watch(oauthConsentRepositoryProvider));
});

final appClientRegistryUseCasesProvider = Provider<AppClientRegistryUseCases>((ref) {
  return AppClientRegistryUseCases(ref.watch(appClientRegistryRepositoryProvider));
});

/// Reloads every SSO view when the signed-in member changes.
String _requireMember(Ref ref) {
  final userId = ref.watch(authProvider.select((s) => s.asData?.value?.id));
  if (userId == null) throw const SsoFailure(SsoFailureCode.session);
  return userId;
}

final authorizationRequestProvider = FutureProvider.autoDispose.family<AuthorizationRequest, String>((
  ref,
  authorizationId,
) {
  _requireMember(ref);
  return ref.watch(oauthConsentUseCasesProvider).load(authorizationId);
});

final connectedAppsProvider = FutureProvider.autoDispose<List<ConnectedApp>>((ref) {
  _requireMember(ref);
  return ref.watch(oauthConsentUseCasesProvider).connectedApps();
});

final appClientsProvider = FutureProvider.autoDispose<List<AppClient>>((ref) {
  _requireMember(ref);
  return ref.watch(appClientRegistryUseCasesProvider).list();
});

final ssoRedirectProvider = Provider<SsoRedirect>((ref) {
  return (target) => launchUrl(target, webOnlyWindowName: '_self');
});

/// One-shot: whether this member pressed "Open" on a service a moment ago.
final serviceLaunchCheckProvider = Provider<Future<bool> Function(String? userId)>(
  (ref) => KaoIdSsoHandoff.takeServiceLaunch,
);

final consentControllerProvider = StateNotifierProvider.autoDispose.family<ConsentController, ConsentState, String>(
  (ref, authorizationId) =>
      ConsentController(useCases: ref.watch(oauthConsentUseCasesProvider), redirect: ref.watch(ssoRedirectProvider)),
);
