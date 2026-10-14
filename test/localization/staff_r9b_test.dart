import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/governance/data/repositories/supabase_member_repository.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/staff_page.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/staff_repository.dart';
import 'package:kaosure/features/kao_id/governance/data/repositories/supabase_staff_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;
import 'member_admin_r9a_test.dart' show MemberFixture;

class StaffFixture implements StaffRepository {
  bool denied = false;
  int assignments = 0;
  @override
  Future<Map<String, dynamic>> load() async {
    if (denied) { throw const PostgrestException(message: 'owner_required'); }
    return {'roles': [
        {'code': 'kaoid_admin', 'name': 'Kao ID admin', 'is_system': true, 'is_active': true,
          'permissions': ['admin.dashboard.view', 'kaoid.kyc.review']},
        {'code': 'kyc_officer', 'is_system': true, 'is_active': false, 'legacy': true, 'permissions': []},
      ],
      'assignments': [], 'grants': [], 'history': []};
  }
  @override
  Future<void> assign(String target, String role) async {
    expect(target, 'test-member'); expect(role, 'kaoid_admin'); assignments++;
  }
  @override
  Future<void> revoke(String id) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('Staff direct entry denies unauthorized access: $locale', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        staffRepositoryProvider.overrideWithValue(StaffFixture()..denied = true),
      ], child: MaterialApp(locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const StaffPage())));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(StaffPage)));
      expect(find.text(l.adminAccessDenied), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  }
  testWidgets('Role assignment requires explicit confirmation of selected member', (tester) async {
    final repo = StaffFixture();
    await tester.pumpWidget(ProviderScope(overrides: [
      authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
      staffRepositoryProvider.overrideWithValue(repo),
      memberRepositoryProvider.overrideWithValue(MemberFixture()),
    ], child: MaterialApp(locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const StaffPage())));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(StaffPage)));
    await tester.enterText(find.byType(TextField), 'test@example.invalid');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, l.adminSearch));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(DropdownButton<String>), 120,
      scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    expect(find.text(l.staffReviewer), findsNothing);
    await tester.tap(find.text(l.staffRoleKaoidAdmin).last);
    await tester.pumpAndSettle();
    expect(find.text(l.staffKaoidMfaScope), findsOneWidget);
    final assign = find.widgetWithText(FilledButton, l.staffAssign);
    await tester.scrollUntilVisible(assign, 150, scrollable: find.byType(Scrollable).first);
    await tester.tap(assign);
    await tester.pumpAndSettle();
    expect(repo.assignments, 0);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, l.continueLabel));
    await tester.pumpAndSettle();
    expect(repo.assignments, 1);
    expect(tester.takeException(), isNull);
  });
}
