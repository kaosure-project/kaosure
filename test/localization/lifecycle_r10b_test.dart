import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/account/domain/repositories/lifecycle_repository.dart';
import 'package:kaosure/features/kao_id/account/data/repositories/supabase_lifecycle_repository.dart';
import 'package:kaosure/features/kao_id/account/presentation/pages/lifecycle/lifecycle_page.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;

class LifecycleFixture implements LifecycleRepository {
  bool owner = false, fail = false;
  String status = 'active';
  int submissions = 0;
  final rows = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> snapshot() async {
    if (fail) throw StateError('private backend error');
    return {'account_status': status, 'owner': owner, 'requests': rows};
  }
  @override
  Future<void> submit(String kind, String reason) async {
    submissions++;
    rows.add({'id': 'request', 'kind': kind, 'status': 'pending', 'reason': reason});
  }
  @override
  Future<void> cancel(String id) async { rows.single['status'] = 'cancelled'; }
}
Future<void> mount(WidgetTester tester, LifecycleFixture repo, Locale locale) async {
  await tester.pumpWidget(ProviderScope(overrides: [
    authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
    lifecycleRepositoryProvider.overrideWithValue(repo),
  ], child: MaterialApp(locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const LifecyclePage())));
  await tester.pumpAndSettle();
}
void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('Request and cancel without closing account: $locale', (tester) async {
      final repo = LifecycleFixture();
      await mount(tester, repo, locale);
      final l = AppLocalizations.of(tester.element(find.byType(LifecyclePage)));
      final initialSend = find.widgetWithText(FilledButton, l.lifeClose);
      expect(tester.widget<FilledButton>(initialSend).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'Request for testing');
      // onChanged schedules a rebuild: wait before tapping the enabled button.
      await tester.pumpAndSettle();
      final send = find.widgetWithText(FilledButton, l.lifeClose);
      await tester.ensureVisible(send);
      expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(repo.submissions, 0);
      expect(find.byType(AlertDialog), findsOneWidget);
      final confirm = find.descendant(of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, l.continueLabel));
      expect(confirm, findsOneWidget);
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(repo.submissions, 1);
      expect(repo.status, 'active');
      expect(find.text(l.lifePending), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      final cancel = find.widgetWithText(TextButton, l.cancel);
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(confirm, findsOneWidget);
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(repo.rows.single['status'], 'cancelled');
    });
  }
  testWidgets('Owner has explanation and no closure form', (tester) async {
    await mount(tester, LifecycleFixture()..owner = true, const Locale('en'));
    expect(find.byType(TextField), findsNothing);
    final l = AppLocalizations.of(tester.element(find.byType(LifecyclePage)));
    expect(find.text(l.lifeOwner), findsOneWidget);
  });
  testWidgets('Load failure does not offer closure and can retry', (tester) async {
    final repo = LifecycleFixture()..fail = true;
    await mount(tester, repo, const Locale('en'));
    final l = AppLocalizations.of(tester.element(find.byType(LifecyclePage)));
    expect(find.text(l.kycLoadFailed), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    repo.fail = false;
    await tester.tap(find.widgetWithText(OutlinedButton, l.authCheckAgain));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });
  testWidgets('Closed account offers request, not automatic recovery', (tester) async {
    final repo = LifecycleFixture()..status = 'closed';
    await mount(tester, repo, const Locale('en'));
    final l = AppLocalizations.of(tester.element(find.byType(LifecyclePage)));
    expect(find.widgetWithText(FilledButton, l.lifeRecover), findsOneWidget);
    expect(repo.submissions, 0);
  });
}
