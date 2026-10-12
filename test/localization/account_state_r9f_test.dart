import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/governance/members/account_state_page.dart';
import 'package:kaosure/features/kao_id/governance/members/member_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;
class AccountFixture implements AccountStateRepository {
  int changes = 0;
  @override
  Future<List<Map<String, dynamic>>> history(String target) async => [];
  @override
  Future<void> change(String target, String expected, String next, String reason) async { changes++; }
}
void main() {
  for (final language in ['th', 'en']) {
    testWidgets('Account action requires reason and confirmation: $language', (tester) async {
      final repo = AccountFixture();
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        memberAccessProvider.overrideWith((ref) async => true),
        accountStateRepositoryProvider.overrideWithValue(repo),
      ], child: MaterialApp(locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AccountStatePage(target: 'another-account', initialStatus: 'active'))));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(AccountStatePage)));
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'Documented reason');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.accountSuspend));
      await tester.pumpAndSettle();
      expect(repo.changes, 0);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(repo.changes, 0);
      await tester.tap(find.text(l.accountSuspend));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.continueLabel));
      await tester.pumpAndSettle();
      expect(repo.changes, 1);
      expect(find.text(l.accountRestore), findsOneWidget);
    });
    testWidgets('Non-owner has no status controls: $language', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        memberAccessProvider.overrideWith((ref) async => false),
        accountStateRepositoryProvider.overrideWithValue(AccountFixture()),
      ], child: MaterialApp(locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AccountStatePage(target: 'another-account', initialStatus: 'active'))));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });
  }
}
