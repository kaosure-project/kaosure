import 'package:kaosure/features/kao_id/kyc/review/kyc_review_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/account/lifecycle/recovery_evidence_page.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/kyc/identity_card/national_id_repository.dart';
import 'package:kaosure/features/kao_id/kyc/review/kyc_review_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;

class RecoveryFixture implements RecoveryRepository {
  bool fail = false;
  bool submitted = false;
  @override
  Future<List<Map<String, dynamic>>> snapshot() async {
    if (fail) { throw StateError('private backend detail'); }
    return submitted ? [{'id': 'proof', 'lifecycle_id': 'request', 'document_type': 'passport', 'status': 'submitted', 'paths': <String>[]}] : [];
  }
  @override
  Future<Map<String, dynamic>> prepare(String request, String type) async => throw StateError('unexpected submission');
  @override
  Future<void> submit(Map<String, dynamic> draft, Map<String, dynamic> data, List<IdImage> files) async => throw StateError('unexpected submission');
  @override
  Future<Uint8List> preview(String path) async => Uint8List(0);
}
Future<void> mount(WidgetTester tester, RecoveryFixture repo, Locale locale, {Widget? page}) async {
  await tester.pumpWidget(ProviderScope(overrides: [
    authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
    recoveryRepositoryProvider.overrideWithValue(repo),
    kycReviewerAccessProvider.overrideWith((ref) async => true),
  ], child: MaterialApp(locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: page ?? const RecoveryEvidencePage(requestId: 'request'))));
  await tester.pumpAndSettle();
}
void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('Submitted recovery remains pending and cannot be edited: $locale', (tester) async {
      await mount(tester, RecoveryFixture()..submitted = true, locale);
      final l = AppLocalizations.of(tester.element(find.byType(RecoveryEvidencePage)));
      expect(find.text(l.lifePending), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.widgetWithText(FilledButton, l.idSubmit), findsNothing);
      expect(find.text(l.recoveryRestored), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Load error is not an empty editable recovery form', (tester) async {
    await mount(tester, RecoveryFixture()..fail = true, const Locale('en'));
    final l = AppLocalizations.of(tester.element(find.byType(RecoveryEvidencePage)));
    expect(find.text(l.recoveryActionFailed), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('private backend detail'), findsNothing);
  });
  testWidgets('Incomplete recovery cannot submit', (tester) async {
    await mount(tester, RecoveryFixture(), const Locale('th'));
    final l = AppLocalizations.of(tester.element(find.byType(RecoveryEvidencePage)));
    final send = find.widgetWithText(FilledButton, l.idSubmit);
    await tester.scrollUntilVisible(send, 200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Recovery approval requires explicit identity comparison', (tester) async {
    await mount(tester, RecoveryFixture(), const Locale('en'), page: const KycReviewDetailPage(row: {
      'id': 'review', 'document_type': 'passport', 'is_recovery': true,
      'paths': ['new/data.jpg'], 'previous_paths': ['old/front.jpg'],
      'full_name': 'Test Applicant', 'previous_name': 'Previous Name',
    }));
    final l = AppLocalizations.of(tester.element(find.byType(KycReviewDetailPage)));
    expect(find.text(l.recoveryReviewTitle), findsOneWidget);
    final approve = find.widgetWithText(FilledButton, l.reviewApprove);
    await tester.scrollUntilVisible(approve, 200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<FilledButton>(approve).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
