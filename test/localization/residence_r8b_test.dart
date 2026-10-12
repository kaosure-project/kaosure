import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/failures/national_id_failure.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/id_image.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/id_image_picker_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/residence.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/residence_repository.dart';
import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_residence_repository.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/screens/residence_permit_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;
import 'national_id_r7a_test.dart' show imageBytes;

class ResidenceFixture implements ResidenceRepository {
  ResidenceRecord? record;
  bool pending = false, failLoad = false, loseResponse = false;
  final submitted = <ResidenceDraft>[];
  @override
  Future<String> owner() async => 'test-user';
  @override
  Future<ResidenceRecord?> latest(String owner) async {
    if (failLoad) { throw const NationalIdFailure('load'); }
    return record;
  }
  @override
  Future<bool> hasPendingRequest(String owner) async => pending;
  @override
  Future<ResidenceRecord> submit(ResidenceDraft draft) async {
    submitted.add(draft);
    record = ResidenceRecord({'id': draft.id, 'status': 'pending_review',
      'full_name': draft.given, 'no_expiry': draft.noExpiry,
      'document_files': [
        {'file_path': 'test-user/residence/${draft.id}/front.jpg'},
        if (draft.back != null) {'file_path': 'test-user/residence/${draft.id}/back.jpg'},
      ]});
    if (loseResponse) { loseResponse = false; throw const NationalIdFailure('save'); }
    return record!;
  }
  @override
  Future<Uint8List> preview(String owner, String path) async => imageBytes();
}
Widget residenceApp(ResidenceFixture repo, String language) => ProviderScope(overrides: [
  authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
  residenceRepositoryProvider.overrideWithValue(repo),
  nationalIdImagePickerProvider.overrideWithValue(() async => IdImage('test.png', imageBytes())),
], child: MaterialApp(locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: const ResidencePermitPage()));
Future<void> tap(WidgetTester tester, String key, {double delta = 180}) async {
  final f = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(f, delta, scrollable: find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(f.hitTestable(), findsOneWidget);
  await tester.tap(f);
  await tester.pumpAndSettle();
}
Future<void> enter(WidgetTester tester, String key, String value) async {
  final f = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(f, 180, scrollable: find.byType(Scrollable).first);
  await tester.enterText(f, value);
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}
Future<void> fill(WidgetTester tester, {bool paper = false}) async {
  if (paper) { await tap(tester, 'residence-card'); }
  await tap(tester, 'residence-single');
  await enter(tester, 'residence-given', 'Élodie');
  await enter(tester, 'residence-number', 'EXAMPLE001');
  await enter(tester, 'residence-country', 'Example authority');
  await tap(tester, 'residence-issued');
  final l = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog)));
  await tester.tap(find.widgetWithText(TextButton, l.okButtonLabel));
  await tester.pumpAndSettle();
  await tap(tester, 'residence-no-expiry');
  await tap(tester, 'residence-front');
}
void main() {
  for (final language in ['th', 'en']) {
    testWidgets('Pending request blocks residence submission: $language', (tester) async {
      await tester.pumpWidget(residenceApp(ResidenceFixture()..pending = true, language));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(ResidencePermitPage)));
      expect(find.text(l.residenceOtherPending), findsOneWidget);
      expect(find.byKey(const ValueKey('residence-submit')), findsNothing);
    });
    testWidgets('Failed load cannot be mistaken for an empty residence record: $language', (tester) async {
      await tester.pumpWidget(residenceApp(ResidenceFixture()..failLoad = true, language));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(ResidencePermitPage)));
      expect(find.text(l.contactLoadFailed), findsOneWidget);
      expect(find.byKey(const ValueKey('residence-submit')), findsNothing);
    });
    testWidgets('Card needs both sides; retry preserves ID and reopening shows both images: $language', (tester) async {
      final repo = ResidenceFixture()..loseResponse = true;
      await tester.pumpWidget(residenceApp(repo, language));
      await tester.pumpAndSettle();
      await fill(tester);
      await tap(tester, 'residence-submit');
      expect(repo.submitted, isEmpty);
      final l = AppLocalizations.of(tester.element(find.byType(ResidencePermitPage)));
      expect(find.text(l.residenceCompleteForm), findsOneWidget);
      await tap(tester, 'residence-back', delta: -180);
      await tap(tester, 'residence-submit');
      expect(repo.submitted.length, 1);
      expect(find.text(l.idSaveFailed), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tap(tester, 'residence-submit');
      expect(repo.submitted.length, 2);
      expect(repo.submitted.first.id, repo.submitted.last.id);
      expect(repo.submitted.last.back, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(residenceApp(repo, language));
      await tester.pumpAndSettle();
      expect(find.text(l.kycPendingStatus), findsOneWidget);
      expect(find.text(l.residenceViewFront), findsOneWidget);
      expect(find.text(l.residenceViewBack), findsOneWidget);
      expect(find.byKey(const ValueKey('residence-submit')), findsNothing);
    });
    testWidgets('Single-page permit keeps single Unicode name and has no back image: $language', (tester) async {
      final repo = ResidenceFixture();
      await tester.pumpWidget(residenceApp(repo, language));
      await tester.pumpAndSettle();
      await fill(tester, paper: true);
      expect(find.byKey(const ValueKey('residence-back')), findsNothing);
      await tap(tester, 'residence-submit');
      final draft = repo.submitted.single;
      expect(draft.given, 'Élodie');
      expect(draft.family, isEmpty);
      expect(draft.singleName, isTrue);
      expect(draft.format, 'paper');
      expect(draft.back, isNull);
      expect(draft.noExpiry, isTrue);
      expect(draft.expiry, isNull);
    });
  }
}
