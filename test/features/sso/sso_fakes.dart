import 'package:kaosure/features/kao_id/sso/domain/entities/app_client.dart';
import 'package:kaosure/features/kao_id/sso/domain/entities/authorization_request.dart';
import 'package:kaosure/features/kao_id/sso/domain/entities/connected_app.dart';
import 'package:kaosure/features/kao_id/sso/domain/entities/sso_app.dart';
import 'package:kaosure/features/kao_id/sso/domain/failures/sso_failure.dart';
import 'package:kaosure/features/kao_id/sso/domain/repositories/app_client_registry_repository.dart';
import 'package:kaosure/features/kao_id/sso/domain/repositories/oauth_consent_repository.dart';

const secondhandClientId = '6f1c2b8e-4d3a-4b7e-9c11-2a5d8e0f7b34';

SsoApp secondhandApp({bool active = true, Set<SsoClaim>? claims}) => SsoApp(
  appCode: 'secondhand_web',
  clientId: secondhandClientId,
  displayName: 'Kao Secondhand',
  active: active,
  firstParty: true,
  claims: claims ?? {SsoClaim.profile, SsoClaim.verification, SsoClaim.business},
  lastSeenAt: DateTime(2026, 10, 12, 9),
);

ConsentRequest consentRequest({SsoApp? app, bool registered = true}) => ConsentRequest(
  authorizationId: 'auth_request_0001',
  clientId: secondhandClientId,
  clientName: 'secondhand-oauth',
  scopes: const ['openid', 'email', 'profile'],
  redirectUri: Uri.parse('http://localhost:5000/auth/callback'),
  clientUri: Uri.parse('https://secondhand.kaosure.test'),
  app: registered ? app ?? secondhandApp() : null,
);

AppClient appClient({bool active = true, bool registered = true}) => AppClient(
  appCode: 'secondhand_web',
  clientId: secondhandClientId,
  displayName: 'Kao Secondhand',
  active: active,
  firstParty: true,
  claims: const {SsoClaim.profile, SsoClaim.verification},
  rpcs: const ['get_my_seller_readiness', 'create_personal_shop'],
  tables: const ['products', 'shops'],
  oauthRegistered: registered,
  redirectUris: const ['http://localhost:5000/auth/callback'],
  members: 3,
);

final class FakeOAuthConsentRepository implements OAuthConsentRepository {
  AuthorizationRequest? request;
  SsoFailure? loadFailure;
  List<ConnectedApp> apps = [];
  final List<String> calls = [];

  @override
  String? currentUserId() => 'test-user';

  @override
  Future<AuthorizationRequest> load(String authorizationId) async {
    calls.add('load:$authorizationId');
    if (loadFailure case final failure?) throw failure;
    return request ?? consentRequest();
  }

  @override
  Future<Uri> approve(String authorizationId) async {
    calls.add('approve:$authorizationId');
    return Uri.parse('http://localhost:5000/auth/callback?code=abc&state=xyz');
  }

  @override
  Future<Uri> deny(String authorizationId) async {
    calls.add('deny:$authorizationId');
    return Uri.parse('http://localhost:5000/auth/callback?error=access_denied&state=xyz');
  }

  @override
  Future<List<ConnectedApp>> connectedApps() async => apps;

  @override
  Future<void> revoke(String clientId) async {
    calls.add('revoke:$clientId');
    apps = apps.where((app) => app.clientId != clientId).toList();
  }

  /// Origins of active registered apps.
  Set<String> appOrigins = {'http://localhost:5000'};

  @override
  Future<bool> isAppPage(Uri target) async {
    calls.add('isAppPage:$target');
    return appOrigins.contains(target.origin);
  }
}

final class FakeAppClientRegistryRepository implements AppClientRegistryRepository {
  List<AppClient> clients = [];
  SsoFailure? failure;
  final List<AppClientDraft> saved = [];
  final List<String> statusChanges = [];

  @override
  Future<List<AppClient>> list() async {
    if (failure case final failure?) throw failure;
    return clients;
  }

  @override
  Future<void> save(AppClientDraft draft) async => saved.add(draft);

  @override
  Future<void> setActive(String appCode, {required bool active}) async => statusChanges.add('$appCode:$active');
}
