import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/member_page.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/member_repository.dart';
import 'package:kaosure/features/kao_id/governance/data/repositories/supabase_member_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;

class MemberFixture implements MemberRepository {
  bool allowed = true;
  @override
  Future<bool> canRead() async => allowed;
  @override
  Future<Map<String, dynamic>?> find(String query) async => {
    'id': 'test-member', 'display_name': 'Test member', 'email': 'test@example.invalid',
    'phone': '', 'email_verified': true, 'phone_verified': false,
    'account_status': 'active', 'kyc_status': 'pending', 'kao_id': null,
  };
}
Finder selectable(String value) => find.byWidgetPredicate(
  (widget) => widget is SelectableText && widget.data == value,
  description: 'SelectableText containing the expected member value');

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('Member summary uses real response fields: $locale', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        memberRepositoryProvider.overrideWithValue(MemberFixture()),
      ], child: MaterialApp(locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const MemberPage())));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'test@example.invalid');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(selectable('test-member'), 120,
        scrollable: find.byType(Scrollable).first);
      expect(selectable('test-member'), findsOneWidget);
      expect(selectable('Test member'), findsOneWidget);
      final l = AppLocalizations.of(tester.element(find.byType(MemberPage)));
      expect(selectable('test@example.invalid · ${l.kycVerifiedStatus}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('Direct entry denies non-owner: $locale', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        memberRepositoryProvider.overrideWithValue(MemberFixture()..allowed = false),
      ], child: MaterialApp(locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const MemberPage())));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(MemberPage)));
      expect(find.text(l.adminAccessDenied), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  }
}
