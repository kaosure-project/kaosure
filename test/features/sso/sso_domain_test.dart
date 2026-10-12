import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/sso/data/models/app_client_model.dart';
import 'package:kaosure/features/kao_id/sso/data/models/sso_app_model.dart';
import 'package:kaosure/features/kao_id/sso/domain/entities/app_client.dart';
import 'package:kaosure/features/kao_id/sso/domain/entities/authorization_request.dart';
import 'package:kaosure/features/kao_id/sso/domain/entities/sso_app.dart';
import 'package:kaosure/features/kao_id/sso/domain/failures/sso_failure.dart';
import 'package:kaosure/features/kao_id/sso/domain/usecases/app_client_registry_use_cases.dart';
import 'package:kaosure/features/kao_id/sso/domain/usecases/oauth_consent_use_cases.dart';

import 'sso_fakes.dart';

Matcher failsWith(SsoFailureCode code) =>
    throwsA(isA<SsoFailure>().having((failure) => failure.code, 'code', code));

void main() {
  AppClientDraft draft({String code = 'secondhand_web', String clientId = secondhandClientId,
      String name = 'Kao Secondhand', List<String> rpcs = const ['get_my_seller_readiness'],
      List<String> tables = const ['products']}) => AppClientDraft(
        appCode: code, clientId: clientId, displayName: name, firstParty: true,
        claims: const {SsoClaim.profile}, rpcs: rpcs, tables: tables);

  group('AppClientDraft', () {
    test('accepts a well-formed app and normalizes its names', () {
      final value = draft(code: ' Secondhand_Web ', clientId: secondhandClientId.toUpperCase(),
          rpcs: const ['Create_Personal_Shop', 'create_personal_shop']);
      expect(value.isValid, isTrue);
      final normalized = value.normalized();
      expect(normalized.appCode, 'secondhand_web');
      expect(normalized.clientId, secondhandClientId);
      expect(normalized.rpcs, ['create_personal_shop']);
    });

    test('flags each invalid field', () {
      expect(draft(code: '9app').invalidFields, {AppClientField.appCode});
      expect(draft(clientId: 'not-a-uuid').invalidFields, {AppClientField.clientId});
      expect(draft(name: 'K').invalidFields, {AppClientField.displayName});
      expect(draft(rpcs: const ['drop table;']).invalidFields, {AppClientField.rpcs});
    });

    test('rejects Kao ID admin, KYC and security names in allow-lists', () {
      for (final name in ['kyc_review_queue_r7c', 'admin_set_role', 'app_client_save_r18',
          'security_events', 'mfa_reset']) {
        expect(draft(rpcs: [name]).invalidFields, {AppClientField.rpcs}, reason: name);
      }
      for (final table in ['identity_documents', 'verification_requests', 'company_owners']) {
        expect(draft(tables: [table]).invalidFields, {AppClientField.tables}, reason: table);
      }
    });

    test('parses names separated by commas, spaces and new lines', () {
      expect(AppClientDraft.parseNames('products, shops\ncategories  products'),
          ['products', 'shops', 'categories']);
    });

    test('registry use case refuses invalid drafts before calling the server', () async {
      final repository = FakeAppClientRegistryRepository();
      final useCases = AppClientRegistryUseCases(repository);
      expect(() => useCases.save(draft(code: 'x')), failsWith(SsoFailureCode.invalidClient));
      await useCases.save(draft(code: 'Secondhand_Web'));
      expect(repository.saved.single.appCode, 'secondhand_web');
    });
  });

  group('OAuthConsentUseCases', () {
    final repository = FakeOAuthConsentRepository();
    final useCases = OAuthConsentUseCases(repository);

    test('validates the authorization id before loading', () async {
      expect(OAuthConsentUseCases.isValidAuthorizationId('auth_request_0001'), isTrue);
      expect(OAuthConsentUseCases.isValidAuthorizationId('short'), isFalse);
      expect(OAuthConsentUseCases.isValidAuthorizationId('../../user'), isFalse);
      expect(OAuthConsentUseCases.isValidAuthorizationId(null), isFalse);
      expect(() => useCases.load('bad id'), failsWith(SsoFailureCode.requestNotFound));
    });

    test('accepts https, loopback http and native reverse-domain schemes only', () {
      bool safe(String uri) => OAuthConsentUseCases.isSafeRedirect(Uri.parse(uri));
      expect(safe('https://secondhand.kaosure.com/auth/callback'), isTrue);
      expect(safe('http://localhost:5000/auth/callback'), isTrue);
      expect(safe('http://127.0.0.1:5000/cb'), isTrue);
      expect(safe('com.kaosure.auction:/oauth'), isTrue);
      expect(safe('http://evil.example/cb'), isFalse);
      expect(safe('javascript:alert(1)'), isFalse);
      expect(safe('https://user@secondhand.kaosure.com/cb'), isFalse);
      expect(safe('/relative'), isFalse);
    });

    test('approval needs an active registered app', () async {
      expect(() => useCases.approve(consentRequest(registered: false)),
          failsWith(SsoFailureCode.appNotAllowed));
      expect(() => useCases.approve(consentRequest(app: secondhandApp(active: false))),
          failsWith(SsoFailureCode.appNotAllowed));
      final target = await useCases.approve(consentRequest());
      expect(target.queryParameters['code'], 'abc');
    });

    test('deny works even for unknown apps', () async {
      final target = await useCases.deny(consentRequest(registered: false));
      expect(target.queryParameters['error'], 'access_denied');
    });

    test('an earlier consent continues only to a safe address', () {
      expect(useCases.continueApproved(ConsentAlreadyGiven(
          redirectUrl: Uri.parse('https://secondhand.kaosure.com/cb?code=1'))).host,
          'secondhand.kaosure.com');
      expect(() => useCases.continueApproved(ConsentAlreadyGiven(
          redirectUrl: Uri.parse('javascript:alert(1)'))), failsWith(SsoFailureCode.invalidRedirect));
    });
  });

  group('models', () {
    test('directory rows keep known claims only', () {
      final app = SsoAppModel.fromJson({
        'app_code': 'secondhand_web', 'client_id': secondhandClientId.toUpperCase(),
        'display_name': 'Kao Secondhand', 'status': 'active', 'first_party': true,
        'claims': ['profile', 'business', 'unknown'], 'last_seen_at': '2026-10-12T09:00:00Z',
      });
      expect(app.clientId, secondhandClientId);
      expect(app.claims, {SsoClaim.profile, SsoClaim.business});
      expect(app.lastSeenAt, isNotNull);
    });

    test('registry rows split comma separated redirect URIs', () {
      final client = AppClientModel.fromJson({
        'app_code': 'secondhand_web', 'client_id': secondhandClientId,
        'display_name': 'Kao Secondhand', 'status': 'suspended', 'first_party': false,
        'claims': ['verification'], 'rpcs': ['create_personal_shop'], 'tables': [],
        'redirect_uris': 'http://localhost:5000/auth/callback, https://secondhand.kaosure.com/cb',
        'oauth_registered': true, 'members': 2,
      });
      expect(client.active, isFalse);
      expect(client.redirectUris, hasLength(2));
      expect(client.members, 2);
      expect(client.toDraft().isValid, isTrue);
    });
  });
}
