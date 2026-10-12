import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/failures/national_id_failure.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/id_image.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/id_image_picker_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/passport.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/passport_repository.dart';
import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_passport_repository.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/passport/passport_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;
import 'kyc_form_helpers.dart';
import 'national_id_r7a_test.dart' show imageBytes;

class PassportFixture implements PassportRepository {
  PassportRecord? record;
  bool pending = false, failLoad = false, loseResponse = false;
  final submitted = <PassportDraft>[];
  @override
  Future<String> owner() async => 'test-user';
  @override
  Future<PassportRecord?> latest(String owner) async {
    if (failLoad) { throw const NationalIdFailure('load'); }
    return record;
  }
  @override
  Future<bool> hasPendingRequest(String owner) async => pending;
  @override
  Future<PassportRecord> submit(PassportDraft draft) async {
    submitted.add(draft);
    record = PassportRecord({'id': draft.id, 'status': 'pending_review',
      'full_name': draft.given, 'expiry_date': '2030-01-01', 'document_files': <dynamic>[]});
    if (loseResponse) { loseResponse = false; throw const NationalIdFailure('save'); }
    return record!;
  }
  @override
  Future<Uint8List> preview(String owner, String path) async => imageBytes();
}
Widget passportApp(PassportFixture repo, String language) => ProviderScope(overrides: [
  authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
  passportRepositoryProvider.overrideWithValue(repo),
  nationalIdImagePickerProvider.overrideWithValue(() async => IdImage('test.png', imageBytes())),
], child: MaterialApp(locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: const PassportPage()));
Future<void> tap(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(f, 180, scrollable: find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(f.hitTestable(), findsOneWidget, reason: 'The action must not be covered by another widget.');
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
void main() {
  for (final language in ['th', 'en']) {
    testWidgets('Pending national ID blocks another passport request: $language', (tester) async {
      await tester.pumpWidget(passportApp(PassportFixture()..pending = true, language));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(PassportPage)));
      expect(find.text(l.passportOtherPending), findsOneWidget);
      expect(find.byKey(const ValueKey('passport-submit')), findsNothing);
    });
    testWidgets('Unknown state cannot send a passport: $language', (tester) async {
      await tester.pumpWidget(passportApp(PassportFixture()..failLoad = true, language));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(PassportPage)));
      expect(find.text(l.contactLoadFailed), findsOneWidget);
      expect(find.byKey(const ValueKey('passport-submit')), findsNothing);
    });
    testWidgets('Single name preserves Unicode and lost-response retry ID: $language', (tester) async {
      final repo = PassportFixture()..loseResponse = true;
      await tester.pumpWidget(passportApp(repo, language));
      await tester.pumpAndSettle();
      await tap(tester, 'passport-single');
      expect(find.byKey(const ValueKey('passport-family')), findsNothing);
      await enter(tester, 'passport-given', 'Élodie');
      await enter(tester, 'passport-number', 'ex ample001');
      await choosePickerOption(tester, 'passport-nationality', 'Japan', 'JPN');
      await fillThaiAddress(tester, 'passport');
      for (final key in ['passport-birth', 'passport-issued']) {
        await tap(tester, key);
        final l = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog)));
        await tester.tap(find.widgetWithText(TextButton, l.okButtonLabel));
        await tester.pumpAndSettle();
      }
      // Select tomorrow using the date picker's input mode, with localized formatting.
      await tap(tester, 'passport-expiry');
      final dialog = tester.element(find.byType(DatePickerDialog));
      final l = MaterialLocalizations.of(dialog);
      await tester.tap(find.byTooltip(l.inputDateModeButtonLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, l.formatCompactDate(DateTime.now().add(const Duration(days: 30))));
      await tester.tap(find.widgetWithText(TextButton, l.okButtonLabel));
      await tester.pumpAndSettle();
      await tap(tester, 'passport-image');
      await tap(tester, 'passport-submit');
      expect(repo.submitted.length, 1);
      final messages = AppLocalizations.of(tester.element(find.byType(PassportPage)));
      expect(find.text(messages.idSaveFailed), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tap(tester, 'passport-submit');
      expect(repo.submitted.length, 2);
      expect(repo.submitted.first.id, repo.submitted.last.id);
      expect(repo.submitted.last.given, 'Élodie');
      expect(repo.submitted.last.family, isEmpty);
      expect(repo.submitted.last.singleName, isTrue);
      expect(repo.submitted.last.number, 'EXAMPLE001');
      expect(repo.submitted.last.nationality, 'JPN');
      expect(repo.submitted.last.address.district, 'Khlong Toei');
      expect(repo.submitted.last.address.province, 'กรุงเทพมหานคร');
      expect(find.byKey(const ValueKey('passport-submit')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(passportApp(repo, language));
      await tester.pumpAndSettle();
      final text = AppLocalizations.of(tester.element(find.byType(PassportPage)));
      expect(find.text(text.kycPendingStatus), findsOneWidget);
    });
  }
}
