import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/sso/application/providers/sso_providers.dart';
import 'package:kaosure/features/kao_id/sso/data/providers/sso_repository_providers.dart';
import 'package:kaosure/features/kao_id/sso/domain/entities/authorization_request.dart';
import 'package:kaosure/features/kao_id/sso/domain/entities/connected_app.dart';
import 'package:kaosure/features/kao_id/sso/domain/failures/sso_failure.dart';
import 'package:kaosure/features/kao_id/sso/presentation/pages/app_clients_page.dart';
import 'package:kaosure/features/kao_id/sso/presentation/pages/connected_apps_page.dart';
import 'package:kaosure/features/kao_id/sso/presentation/pages/oauth_consent_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../localization/auth_localization_r2_test.dart' show TestAuthNotifier;
import 'sso_fakes.dart';

Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late FakeOAuthConsentRepository consent;
  late FakeAppClientRegistryRepository registry;
  late List<Uri> redirects;

  setUp(() {
    consent = FakeOAuthConsentRepository();
    registry = FakeAppClientRegistryRepository();
    redirects = [];
  });

  Future<AppLocalizations> pump(WidgetTester tester, Widget home, {
    String language = 'en',
    Size size = const Size(1024, 1400),
    bool settle = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        oauthConsentRepositoryProvider.overrideWithValue(consent),
        appClientRegistryRepositoryProvider.overrideWithValue(registry),
        ssoRedirectProvider.overrideWithValue((target) async {
          redirects.add(target);
          return true;
        }),
      ],
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ));
    settle ? await tester.pumpAndSettle() : await frames(tester);
    return lookupAppLocalizations(Locale(language));
  }

  /// Leaving for the app keeps a spinner running, so these taps do not settle.
  Future<void> tap(WidgetTester tester, Finder target, {bool settle = true}) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    settle ? await tester.pumpAndSettle() : await frames(tester);
  }

  bool enabled(WidgetTester tester, Key key) =>
      tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed != null;

  const consentPage = OAuthConsentPage(authorizationId: 'auth_request_0001');

  group('consent', () {
    for (final language in ['th', 'en', 'my', 'lo']) {
      testWidgets('shows the app, scopes and shared claims on a phone in $language', (tester) async {
        final l10n = await pump(tester, consentPage, language: language, size: const Size(360, 900));
        expect(find.text(l10n.ssoConsentTitle('Kao Secondhand')), findsOneWidget);
        expect(find.text(l10n.ssoFirstParty), findsOneWidget);
        expect(find.text(l10n.ssoScopeEmail), findsOneWidget);
        expect(find.text(l10n.ssoClaimVerification), findsOneWidget);
        expect(find.text(l10n.ssoClaimRoles), findsNothing);
        expect(find.text(l10n.ssoConsentSignedInAs('example@example.com')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('allow approves the request and returns to the app', (tester) async {
      await pump(tester, consentPage);
      await tap(tester, find.byKey(const Key('sso-consent-allow')), settle: false);
      expect(consent.calls, ['load:auth_request_0001', 'approve:auth_request_0001']);
      expect(redirects.single.queryParameters['code'], 'abc');
    });

    testWidgets('deny returns access_denied to the app', (tester) async {
      await pump(tester, consentPage);
      await tap(tester, find.byKey(const Key('sso-consent-deny')), settle: false);
      expect(consent.calls.last, 'deny:auth_request_0001');
      expect(redirects.single.queryParameters['error'], 'access_denied');
    });

    testWidgets('unregistered or suspended apps can only be denied', (tester) async {
      consent.request = consentRequest(app: secondhandApp(active: false));
      final l10n = await pump(tester, consentPage);
      expect(find.text(l10n.ssoAppBlocked), findsOneWidget);
      expect(enabled(tester, const Key('sso-consent-allow')), isFalse);
      expect(enabled(tester, const Key('sso-consent-deny')), isTrue);
    });

    testWidgets('an earlier consent continues straight to the app', (tester) async {
      consent.request = ConsentAlreadyGiven(
          redirectUrl: Uri.parse('http://localhost:5000/auth/callback?code=again'));
      await pump(tester, consentPage, settle: false);
      expect(redirects.single.queryParameters['code'], 'again');
    });

    testWidgets('expired requests explain how to start again', (tester) async {
      consent.loadFailure = const SsoFailure(SsoFailureCode.requestNotFound);
      final l10n = await pump(tester, consentPage);
      expect(find.text(l10n.ssoErrorRequestNotFound), findsOneWidget);
      expect(find.text(l10n.ssoBackToKaoId), findsOneWidget);
    });

    testWidgets('a malformed id never reaches the server', (tester) async {
      final l10n = await pump(tester, const OAuthConsentPage(authorizationId: ''));
      expect(find.text(l10n.ssoErrorRequestNotFound), findsOneWidget);
      expect(consent.calls, isEmpty);
    });
  });

  group('connected apps', () {
    testWidgets('lists granted apps and disconnects after confirmation', (tester) async {
      consent.apps = [ConnectedApp(clientId: secondhandClientId, name: 'secondhand-oauth',
          scopes: const ['openid', 'email'], grantedAt: DateTime(2026, 10, 1),
          clientUri: Uri.parse('https://secondhand.kaosure.test'), app: secondhandApp())];
      final l10n = await pump(tester, const ConnectedAppsPage(), language: 'th',
          size: const Size(360, 900));
      expect(find.text('Kao Secondhand'), findsOneWidget);
      expect(find.text(l10n.ssoClaimBusiness), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tap(tester, find.byKey(const Key('sso-disconnect-$secondhandClientId')));
      expect(find.text(l10n.ssoDisconnectConfirm('Kao Secondhand')), findsOneWidget);
      await tap(tester, find.widgetWithText(FilledButton, l10n.ssoDisconnect));
      expect(consent.calls, contains('revoke:$secondhandClientId'));
      expect(find.text(l10n.ssoConnectedAppsEmpty), findsOneWidget);
    });
  });

  group('app registry', () {
    testWidgets('owner sees registered apps with their allow-lists', (tester) async {
      registry.clients = [appClient(registered: false)];
      final l10n = await pump(tester, const AppClientsPage(), language: 'th',
          size: const Size(400, 1400));
      expect(find.text('Kao Secondhand'), findsOneWidget);
      expect(find.text('create_personal_shop'), findsOneWidget);
      expect(find.text(l10n.ssoAppOauthMissing), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tap(tester, find.byKey(const Key('sso-app-toggle-secondhand_web')));
      await tap(tester, find.widgetWithText(FilledButton, l10n.ssoAppSuspend));
      expect(registry.statusChanges, ['secondhand_web:false']);
    });

    testWidgets('register dialog validates before saving', (tester) async {
      final l10n = await pump(tester, const AppClientsPage());
      await tap(tester, find.byKey(const Key('sso-app-register')));
      await tester.enterText(find.byKey(const Key('sso-app-code')), 'Bad Code');
      await tap(tester, find.byKey(const Key('sso-app-save')));
      expect(find.text(l10n.ssoErrorInvalidClient), findsOneWidget);
      expect(registry.saved, isEmpty);

      await tester.enterText(find.byKey(const Key('sso-app-code')), 'secondhand_web');
      await tester.enterText(find.byKey(const Key('sso-app-client-id')), secondhandClientId);
      await tester.enterText(find.byKey(const Key('sso-app-name')), 'Kao Secondhand');
      await tester.enterText(find.byKey(const Key('sso-app-rpcs')), 'get_my_seller_readiness\ncreate_personal_shop');
      await tester.enterText(find.byKey(const Key('sso-app-tables')), 'products, public.favorites:write');
      await tap(tester, find.byKey(const Key('sso-app-claim-verification')));
      await tap(tester, find.byKey(const Key('sso-app-save')));
      final saved = registry.saved.single;
      expect(saved.appCode, 'secondhand_web');
      expect(saved.rpcs, ['public.get_my_seller_readiness', 'public.create_personal_shop']);
      expect(saved.tables, ['public.products', 'public.favorites:write']);
      expect(saved.claims.map((claim) => claim.name), ['verification']);
      expect(find.text(l10n.ssoAppSaved), findsOneWidget);
    });

    testWidgets('non-owners see why the registry is closed', (tester) async {
      registry.failure = const SsoFailure(SsoFailureCode.ownerRequired);
      final l10n = await pump(tester, const AppClientsPage());
      expect(find.text(l10n.ssoErrorOwner), findsOneWidget);
      expect(find.byKey(const Key('sso-app-register')), findsNothing);
    });
  });
}
