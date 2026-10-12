import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/account/security/mfa_page.dart';
import 'package:kaosure/features/kao_id/account/security/mfa_repository.dart';
import 'package:kaosure/features/kao_id/account/security/security_operations_page.dart';
import 'package:kaosure/features/kao_id/kyc/review/kyc_review_page.dart';
import 'package:kaosure/features/kao_id/kyc/review/kyc_review_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;

class MfaFixture implements MfaRepository {
  bool failed = false, owner = false;
  int factors = 1, reviewers = 0, enables = 0;
  @override
  Future<Map<String, dynamic>> load() async {
    if (failed) { throw StateError('private-error'); }
    return {'owner': owner, 'aal2': true, 'verified_factors': factors,
      'ready_reviewers': reviewers, 'mfa_required': false, 'dual_review': false,
      'factors': [{'id':'factor-test','name':'Test device'}]};
  }
  @override
  Future<Map<String, String>> enroll(String name, String password) async => {'id':'draft','secret':'TEST-SECRET-NOT-REAL'};
  @override
  Future<void> verify(String factor, String code) async {}
  @override
  Future<void> cancelEnrollment(String factor) async {}
  @override
  Future<void> enablePolicy() async { enables++; }
}
Widget shell(Widget child, Locale locale) => MaterialApp(locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates, home: child);
void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('MFA Owner cannot enforce with incomplete setup: $locale', (tester) async {
      final repo = MfaFixture()..owner = true;
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        mfaRepositoryProvider.overrideWithValue(repo),
      ], child: shell(const MfaPage(), locale)));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(MfaPage)));
      final button = find.widgetWithText(FilledButton, l.securityEnable);
      await tester.scrollUntilVisible(button, 250, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(repo.enables, 0);
      expect(tester.takeException(), isNull);
    });
    testWidgets('MFA load error does not invent active protection: $locale', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        mfaRepositoryProvider.overrideWithValue(MfaFixture()..failed = true),
      ], child: shell(const MfaPage(), locale)));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(MfaPage)));
      expect(find.text(l.mfaFailed), findsOneWidget);
      expect(find.text(l.securityEnabled), findsNothing);
      expect(find.text('private-error'), findsNothing);
    });
  }
  for (final language in ['th','en']) {
    testWidgets('First reviewer cannot supply second vote: $language', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        kycReviewerAccessProvider.overrideWith((ref) async => true),
      ], child: shell(const KycReviewDetailPage(row: {
        'id':'test-request','document_type':'passport','paths':<String>[],
        'dual_review':true,'first_reviewer':'test-user','first_decision':true,
      }), Locale(language))));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(KycReviewDetailPage)));
      expect(find.text(l.dualOwnVote), findsOneWidget);
      final reject = find.widgetWithText(OutlinedButton, l.reviewReject);
      await tester.scrollUntilVisible(reject, 200, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<OutlinedButton>(reject).onPressed, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('Operations failure never appears as zero queued work: $language', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        securityOperationsProvider.overrideWith((ref) async => throw StateError('internal')),
      ], child: shell(const SecurityOperationsPage(), Locale(language))));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(SecurityOperationsPage)));
      expect(find.text(l.kycLoadFailed), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.text('internal'), findsNothing);
    });
  }
}
