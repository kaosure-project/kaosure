import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kaosure/features/kao_id/kyc/domain/failures/national_id_failure.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/id_image.dart';
import 'package:kaosure/features/kao_id/kyc/data/services/id_image_preparer.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/id_image_picker_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/national_id.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/national_id_repository.dart';
import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_national_id_repository.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/identity_card/identity_card_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class IdFixture implements NationalIdRepository {
  NationalIdRecord? record;
  bool failLoad = false;
  bool failAfterCommit = false;
  int submits = 0;
  final ids = <String>[];
  String? submittedName;
  @override
  Future<String> owner() async => 'owner';
  @override
  Future<NationalIdRecord?> latest(String owner) async {
    if (failLoad) { throw const NationalIdFailure('load'); }
    return record;
  }
  @override
  Future<NationalIdRecord> submit(NationalIdDraft draft) async {
    submits++;
    submittedName = draft.fullName;
    ids.add(draft.id);
    record = NationalIdRecord(id: draft.id, owner: draft.owner,
      status: 'pending_review', paths: const []);
    if (failAfterCommit) {
      failAfterCommit = false;
      throw const NationalIdFailure('save');
    }
    return record!;
  }
  @override
  Future<Uint8List> preview(String owner, String path) async => imageBytes();
}

Uint8List imageBytes() => Uint8List.fromList(
  img.encodePng(img.Image(width: 120, height: 120)));

Widget app(IdFixture repo, String locale) => ProviderScope(
  overrides: [
    nationalIdRepositoryProvider.overrideWithValue(repo),
    nationalIdImagePickerProvider.overrideWithValue(
      () async => IdImage('sample.png', imageBytes())),
  ],
  child: MaterialApp(locale: Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const IdentityCardPage()),
);

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(finder, 180,
    scrollable: find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> fillForm(WidgetTester tester) async {
  await tester.enterText(find.byKey(const ValueKey('id-name')), 'Test');
  await tester.enterText(find.byKey(const ValueKey('id-surname')), 'Account');
  await tester.enterText(find.byKey(const ValueKey('id-number')), '0000000000000');
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await tapKey(tester, 'id-issued');
  final dialog = find.byType(DatePickerDialog);
  final ok = MaterialLocalizations.of(tester.element(dialog)).okButtonLabel;
  await tester.tap(find.widgetWithText(TextButton, ok));
  await tester.pumpAndSettle();
  await tapKey(tester, 'id-lifetime');
  await tapKey(tester, 'id-front');
  await tapKey(tester, 'id-back');
}

void main() {
  test('Reject empty, unsupported and oversized bytes', () {
    for (final bytes in [Uint8List(0), Uint8List.fromList([1, 2, 3]), Uint8List(10485761)]) {
      expect(() => prepareIdImage(bytes), throwsA(isA<NationalIdFailure>()));
    }
  });
  test('Reject images too small to review', () {
    final bytes = Uint8List.fromList(img.encodePng(img.Image(width: 32, height: 32)));
    expect(() => prepareIdImage(bytes), throwsA(isA<NationalIdFailure>()));
  });
  test('Valid PNG becomes a decodable JPEG', () {
    final bytes = prepareIdImage(imageBytes());
    expect(bytes.take(2), [255, 216]);
    final decoded = img.decodeJpg(bytes)!;
    expect(decoded.width, 120);
    expect(decoded.height, 120);
  });
  for (final language in ['th', 'en']) {
    testWidgets('Form is localized without overflow at 320px: $language', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(app(IdFixture(), language));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(IdentityCardPage)));
      expect(find.text(l.idFirstName), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        expect(tester.takeException(), isNull);
        if (language == 'en') {
          for (final text in tester.widgetList<Text>(find.byType(Text))) {
            expect(RegExp(r'[\u0E00-\u0E7F]').hasMatch(text.data ?? ''), isFalse);
          }
        }
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
        await tester.pumpAndSettle();
      }
    });
    testWidgets('Incomplete form explains missing fields and sends nothing: $language', (tester) async {
      final repo = IdFixture();
      await tester.pumpWidget(app(repo, language));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(IdentityCardPage)));
      await tapKey(tester, 'id-submit');
      expect(repo.submits, 0);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.descendant(of: find.byType(SnackBar), matching: find.text(l.idCheckHighlightedFields)), findsOneWidget);
      final first = find.byKey(const ValueKey('id-name'));
      await tester.scrollUntilVisible(first, -200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(first).decoration!.errorText, l.idFirstNameRequired);
      final surname = find.byKey(const ValueKey('id-surname'));
      await tester.scrollUntilVisible(surname, 150, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<TextField>(surname).decoration!.errorText, l.idLastNameRequired);
    });
    testWidgets('Failed load cannot submit and retry restores form: $language', (tester) async {
      final repo = IdFixture()..failLoad = true;
      await tester.pumpWidget(app(repo, language));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(IdentityCardPage)));
      expect(find.text(l.contactLoadFailed), findsOneWidget);
      expect(find.byKey(const ValueKey('id-submit')), findsNothing);
      repo.failLoad = false;
      await tester.tap(find.text(l.authCheckAgain));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('id-name')), findsOneWidget);
    });
    testWidgets('Existing pending submission is read only: $language', (tester) async {
      final repo = IdFixture()..record = const NationalIdRecord(
        id: 'saved', owner: 'owner', status: 'pending_review', paths: []);
      await tester.pumpWidget(app(repo, language));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(IdentityCardPage)));
      expect(find.text(l.kycPendingStatus), findsOneWidget);
      expect(find.byKey(const ValueKey('id-submit')), findsNothing);
    });
    testWidgets('Lost response retries same document ID: $language', (tester) async {
      final repo = IdFixture()..failAfterCommit = true;
      await tester.pumpWidget(app(repo, language));
      await tester.pumpAndSettle();
      await fillForm(tester);
      await tapKey(tester, 'id-submit');
      expect(repo.submits, 1);
      expect(repo.submittedName, 'Test Account');
      await tapKey(tester, 'id-submit');
      expect(repo.submits, 2);
      expect(repo.ids.toSet().length, 1);
      expect(find.byKey(const ValueKey('id-submit')), findsNothing);
      // Reopening reads the stored result instead of starting another submission.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app(repo, language));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(IdentityCardPage)));
      expect(find.text(l.kycPendingStatus), findsOneWidget);
      expect(find.byKey(const ValueKey('id-submit')), findsNothing);
    });
  }
}
