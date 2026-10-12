import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/admin_hub_page.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/member_access_provider.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/pages/review/kyc_review_detail_page.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/kyc_review_providers.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;

void main() {
  for (final language in ['th', 'en']) {
    testWidgets('Hub removes revoked menus after access refresh: $language', (tester) async {
      var allowed = true;
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        memberAccessProvider.overrideWith((ref) async => allowed),
        kycReviewerAccessProvider.overrideWith((ref) async => allowed),
      ], child: MaterialApp(locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AdminHubPage())));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(AdminHubPage)));
      expect(find.text(l.staffTitle), findsOneWidget);
      allowed = false;
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text(l.staffTitle), findsNothing);
      expect(find.text(l.reviewTitle), findsNothing);
      expect(find.text(l.adminAccessDenied), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('Direct review detail hides evidence after revocation: $language', (tester) async {
      var allowed = true;
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        kycReviewerAccessProvider.overrideWith((ref) async => allowed),
      ], child: MaterialApp(locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const KycReviewDetailPage(row: {
          'id':'test-request','full_name':'PRIVATE EVIDENCE NAME',
          'document_type':'passport','paths':<String>[],
        }))));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(KycReviewDetailPage)));
      expect(find.textContaining('PRIVATE EVIDENCE NAME'), findsOneWidget);
      allowed = false;
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.textContaining('PRIVATE EVIDENCE NAME'), findsNothing);
      expect(find.text(l.adminAccessDenied), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('Access failure is retryable, never treated as permission: $language', (tester) async {
      var failed = true;
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        memberAccessProvider.overrideWith((ref) async {
          if (failed) { throw StateError('test access unavailable'); }
          return true;
        }),
        kycReviewerAccessProvider.overrideWith((ref) async => false),
      ], child: MaterialApp(locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AdminHubPage())));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(AdminHubPage)));
      expect(find.text(l.kycLoadFailed), findsOneWidget);
      expect(find.text(l.staffTitle), findsNothing);
      failed = false;
      await tester.tap(find.widgetWithText(OutlinedButton, l.authCheckAgain));
      await tester.pumpAndSettle();
      expect(find.text(l.staffTitle), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
