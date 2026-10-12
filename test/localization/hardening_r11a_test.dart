import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/account/data/repositories/supabase_account_access_repository.dart';
import 'package:kaosure/features/kao_id/account/presentation/widgets/account_access_gate.dart';
import 'package:kaosure/features/kao_id/account/domain/repositories/sessions_repository.dart';
import 'package:kaosure/features/kao_id/account/data/repositories/supabase_sessions_repository.dart';
import 'package:kaosure/features/kao_id/account/presentation/pages/security/sessions_page.dart';
import 'package:kaosure/features/kao_id/kyc/maintenance/document_health_page.dart';
import 'package:kaosure/features/kao_id/kyc/identity_card/national_id_repository.dart';
import 'package:kaosure/features/kao_id/kyc/passport/passport_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'closure_r10d_test.dart' show AccessFixture;

class SessionsFixture implements SessionsRepository {
  bool fail = false;
  int calls = 0;
  @override
  Future<List<Map<String, dynamic>>> list() async {
    if (fail) { throw StateError('sensitive backend failure'); }
    return [
      {'id':'current','current_session':true,'user_agent':'Current browser','created_at':'2026-01-01T12:00:00Z'},
      if (calls == 0) {'id':'other','current_session':false,'user_agent':'Other browser','created_at':'2026-01-02T12:00:00Z'},
    ];
  }
  @override
  Future<void> revoke(String? id, {bool others = false, required String expectedUser}) async { calls++; }
}
class HealthFixture implements DocumentHealthRepository {
  bool fail = false;
  int calls = 0;
  @override
  Future<Map<String, dynamic>> load(String? profile) async {
    if (fail) { throw StateError('private evidence detail'); }
    return {'eligible':false,'documents':[{'id':'doc','document_type':'passport','status':calls>0?'revoked':'approved','expiry_date':'2026-12-31'}],'history':[]};
  }
  @override
  Future<void> revoke(String document, String reason) async { calls++; }
}
Future<void> mount(WidgetTester tester, Widget home, AccessFixture access, {Locale locale = const Locale('en'), SessionsFixture? sessions, HealthFixture? health}) async {
  await tester.pumpWidget(ProviderScope(overrides: [
    accountAccessRepositoryProvider.overrideWithValue(access),
    if (sessions != null) sessionsRepositoryProvider.overrideWithValue(sessions),
    if (health != null) documentHealthRepositoryProvider.overrideWithValue(health),
  ], child: MaterialApp(locale: locale, supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates, home: home)));
  await tester.pumpAndSettle();
}
void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('Restricted account never displays protected content: $locale', (tester) async {
      final access = AccessFixture()..state='suspended';
      await mount(tester, AccountAccessGate(navigatorKey: GlobalKey<NavigatorState>(), child: const Text('SECRET')), access, locale: locale);
      final l=AppLocalizations.of(tester.element(find.byType(AccountAccessGate)));
      expect(find.text('SECRET'),findsNothing);
      expect(find.text(l.restrictedAccountHelp),findsOneWidget);
      expect(find.widgetWithText(FilledButton,l.lifeRecover),findsNothing);
      access.state='unavailable';access.events.add(null);await tester.pumpAndSettle();
      expect(find.text(l.unavailableAccountHelp),findsOneWidget);
      access.state='active';access.events.add(null);await tester.pumpAndSettle();
      expect(find.text('SECRET'),findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());await access.events.close();
    });
  }
  testWidgets('Session revoke requires confirmation and preserves current session', (tester) async {
    final access=AccessFixture(),repo=SessionsFixture();
    await mount(tester,const SessionsPage(),access,sessions:repo);
    final l=AppLocalizations.of(tester.element(find.byType(SessionsPage)));
    expect(find.widgetWithText(OutlinedButton,l.sessionRevoke),findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton,l.sessionOthers));await tester.pumpAndSettle();
    expect(repo.calls,0);
    await tester.tap(find.widgetWithText(TextButton,l.cancel));await tester.pumpAndSettle();
    expect(repo.calls,0);
    await tester.tap(find.widgetWithText(FilledButton,l.sessionOthers));await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton,l.continueLabel));await tester.pumpAndSettle();
    expect(repo.calls,1);expect(find.text('Current browser'),findsOneWidget);expect(find.text('Other browser'),findsNothing);
    access.userId='changed';access.events.add(null);await tester.pumpAndSettle();
    expect(find.text('Current browser'),findsNothing);expect(find.text(l.contactSessionChanged),findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());await access.events.close();
  });
  testWidgets('Session failure is not an empty successful list', (tester) async {
    final access=AccessFixture();
    await mount(tester,const SessionsPage(),access,sessions:SessionsFixture()..fail=true);
    final l=AppLocalizations.of(tester.element(find.byType(SessionsPage)));
    expect(find.text(l.kycLoadFailed),findsOneWidget);expect(find.text(l.adminSearchEmpty),findsNothing);
    expect(find.text('sensitive backend failure'),findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());await access.events.close();
  });
  testWidgets('Document revocation requires a reason and explicit confirmation', (tester) async {
    final access=AccessFixture(),repo=HealthFixture();
    await mount(tester,const DocumentHealthPage(profile:'another-member'),access,health:repo);
    final l=AppLocalizations.of(tester.element(find.byType(DocumentHealthPage)));
    await tester.tap(find.widgetWithText(OutlinedButton,l.documentRevoke));await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton,l.continueLabel)).onPressed,isNull);
    await tester.enterText(find.byType(TextField),'Document invalid after investigation');await tester.pumpAndSettle();
    expect(repo.calls,0);
    await tester.tap(find.widgetWithText(FilledButton,l.continueLabel));await tester.pumpAndSettle();
    expect(repo.calls,1);expect(find.text(l.documentRevoked),findsOneWidget);
    expect(find.widgetWithText(OutlinedButton,l.documentRevoke),findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());await access.events.close();
  });
  test('Revoked and expiring records allow replacement; lifetime does not', () {
    expect(const NationalIdRecord(id:'d',owner:'u',status:'revoked',paths:[]).canResubmit,isTrue);
    expect(const NationalIdRecord(id:'d',owner:'u',status:'approved',paths:[]).canResubmit,isFalse);
    expect(NationalIdRecord.fromJson({'id':'d','owner_id':'u','status':'approved','expiry_date':'2000-01-01'}).canResubmit,isTrue);
    expect(PassportRecord({'id':'d','status':'revoked'}).canResubmit,isTrue);
    expect(PassportRecord({'id':'d','status':'approved','expiry_date':'2099-01-01'}).canResubmit,isFalse);
  });
}
