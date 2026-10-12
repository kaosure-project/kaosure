import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/account/domain/repositories/account_access_repository.dart';
import 'package:kaosure/features/kao_id/account/data/repositories/supabase_account_access_repository.dart';
import 'package:kaosure/features/kao_id/account/presentation/widgets/account_access_gate.dart';
import 'package:kaosure/features/kao_id/governance/data/repositories/supabase_owner_requests_repository.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/owner_request_actions.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/owner_request_detail_page.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;
import 'owner_requests_r10c_test.dart' show RequestFixture;

class AccessFixture implements AccountAccessRepository {
  @override
  String? userId = 'member-test';
  String state = 'active';
  bool fail = false;
  final events = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => events.stream;
  @override
  Future<String> check() async {
    if (fail) { throw StateError('private error detail'); }
    return state;
  }
  @override
  Future<void> signOut() async { userId = null; events.add(null); }
}
class CloseFixture extends RequestFixture {
  bool ready = true;
  @override
  Future<Map<String, dynamic>> checks(String id) async => {
    ...await super.checks(id),
    'request': {'id': id, 'kind': 'closure', 'status': status, 'reason': 'Member request'},
    'close_ready': ready && status == 'pending', 'blockers': [],
  };
}
void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('Closure hides protected screens and shows limited access: $locale', (tester) async {
      final repo = AccessFixture();
      final restrictedKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(ProviderScope(overrides: [
        accountAccessRepositoryProvider.overrideWithValue(repo),
      ], child: MaterialApp(locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => AccountAccessGate(navigatorKey: restrictedKey, child: child!),
        home: const Scaffold(body: Text('Protected account data')))));
      await tester.pumpAndSettle();
      expect(find.text('Protected account data'), findsOneWidget);
      repo.state = 'session_revoked'; repo.events.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Protected account data'), findsNothing);
      final l = AppLocalizations.of(tester.element(find.byType(AccountAccessGate)));
      expect(find.text(l.closeSessionEnded), findsOneWidget);
      repo.state = 'closed'; repo.events.add(null);
      await tester.pumpAndSettle();
      expect(find.text(l.closeAccountHelp), findsOneWidget);
      expect(find.widgetWithText(FilledButton, l.lifeRecover), findsOneWidget);
      expect(find.text('Protected account data'), findsNothing);
      repo.fail = true; repo.events.add(null);
      await tester.pumpAndSettle();
      expect(find.text(l.kycLoadFailed), findsOneWidget);
      expect(find.widgetWithText(FilledButton, l.lifeRecover), findsNothing);
      expect(find.text('private error detail'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await repo.events.close();
    });
  }
  for (final ready in [false, true]) {
    testWidgets('Close action is gated by real preflight=$ready and confirmation', (tester) async {
      final repo = CloseFixture()..ready = ready;
      var calls = 0;
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        ownerRequestsRepositoryProvider.overrideWithValue(repo),
        closeAccountActionProvider.overrideWithValue((id, reason) async {
          expect(id, 'request-test'); expect(reason, 'Close after review');
          calls++; repo.status = 'approved';
        }),
      ], child: MaterialApp(locale: const Locale('th'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: OwnerRequestDetail(row: RequestFixture.row))));
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('close-account'));
      await tester.scrollUntilVisible(find.byType(TextField), 200,
        scrollable: find.byType(Scrollable).first);
      if (!ready) { expect(action, findsNothing); return; }
      await tester.scrollUntilVisible(action, 120, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<FilledButton>(action).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'Close after review');
      tester.testTextInput.hide(); await tester.pumpAndSettle();
      await tester.ensureVisible(action); await tester.tap(action); await tester.pumpAndSettle();
      expect(calls, 0);
      final l = AppLocalizations.of(tester.element(find.byType(OwnerRequestDetail)));
      await tester.tap(find.widgetWithText(TextButton, l.cancel)); await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.tap(action); await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l.continueLabel)); await tester.pumpAndSettle();
      expect(calls, 1); expect(action, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
