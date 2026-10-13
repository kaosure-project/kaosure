import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/business/application/providers/business_registration_provider.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_registration.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_registration_failure.dart';
import 'package:kaosure/features/kao_id/business/domain/usecases/business_registration_use_cases.dart';
import 'package:kaosure/features/kao_id/business/presentation/pages/business_registration_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'business_registration_fakes.dart';

void main() {
  late FakeBusinessRegistrationRepository repository;
  late bool kaoIdActive;

  setUp(() {
    repository = FakeBusinessRegistrationRepository();
    kaoIdActive = true;
  });

  Future<AppLocalizations> pumpPage(
    WidgetTester tester, {
    String language = 'en',
    Size size = const Size(1024, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessRegistrationUseCasesProvider.overrideWithValue(BusinessRegistrationUseCases(repository)),
          kaoIdStatusReaderProvider.overrideWithValue(() async => kaoIdActive),
          businessDocumentPickerProvider.overrideWithValue(() async => pdfFile()),
        ],
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BusinessRegistrationPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return lookupAppLocalizations(Locale(language));
  }

  Future<void> tapFinder(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) => tapFinder(tester, find.text(text).last);

  /// Opens the date picker and accepts its default (today), which is always a valid issue date.
  Future<void> pickCertificateDate(WidgetTester tester, AppLocalizations l10n) async {
    await tapText(tester, l10n.businessRegCertificateDateLabel);
    final ok = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();
  }

  testWidgets('details step validates in Thai and moves to the document step', (tester) async {
    final l10n = await pumpPage(tester, language: 'th');
    expect(find.text(l10n.businessRegDetailsHeading), findsOneWidget);

    await tapText(tester, l10n.businessRegContinue);
    expect(find.text(l10n.businessRegFieldRequired), findsNWidgets(3));
    expect(find.text(l10n.businessRegCertificateDateRequired), findsOneWidget);
    expect(repository.calls, isNot(contains('createDraft')));

    await tester.enterText(find.widgetWithText(TextFormField, l10n.businessRegNameLabel), 'บริษัท เก้า จำกัด');
    await tester.enterText(find.widgetWithText(TextFormField, l10n.businessRegNumberLabel), '0105561234567');
    await tester.enterText(find.widgetWithText(TextFormField, l10n.businessRegNameEnLabel), 'ร้านเก้า');
    await tapText(tester, l10n.businessRegCategoryLabel);
    await tapText(tester, l10n.businessRegCategoryRetail);
    await pickCertificateDate(tester, l10n);
    await tapText(tester, l10n.businessRegContinue);
    expect(find.text(l10n.businessRegNumberInvalid), findsOneWidget);
    expect(find.text(l10n.businessRegNameEnInvalid), findsOneWidget);
    expect(repository.calls, isNot(contains('createDraft')));

    await tester.enterText(find.widgetWithText(TextFormField, l10n.businessRegNumberLabel), validJuristicNumber);
    await tester.enterText(find.widgetWithText(TextFormField, l10n.businessRegNameEnLabel), 'KAO CO., LTD.');
    await tapText(tester, l10n.businessRegContinue);
    expect(repository.calls, contains('createDraft'));
    expect(repository.current!.legalNameEn, 'KAO CO., LTD.');
    expect(repository.current!.certificateIssuedOn, isNotNull);
    expect(find.text(l10n.businessRegDocumentHeading), findsOneWidget);
    expect(find.textContaining(l10n.businessRegStepCounter(2, 4)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('certificate is required, VAT is optional and removable', (tester) async {
    repository.current = draft();
    final l10n = await pumpPage(tester);
    final continueButton = find.widgetWithText(FilledButton, l10n.businessRegContinue);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    Finder chooseIn(String card) =>
        find.descendant(of: find.byKey(ValueKey(card)), matching: find.text(l10n.businessRegDocumentChoose));

    await tapFinder(tester, chooseIn('vat-card'));
    expect(repository.calls, contains('attachDocument:vat:certificate.pdf'));
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    await tapText(tester, l10n.businessRegDocumentRemove);
    expect(repository.calls, contains('removeVatDocument'));
    expect(find.text(l10n.businessRegDocumentRemove), findsNothing);

    await tapFinder(tester, chooseIn('certificate-card'));
    expect(repository.calls, contains('attachDocument:certificate:certificate.pdf'));
    expect(find.text(l10n.businessRegDocumentUploaded), findsOneWidget);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);

    await tapText(tester, l10n.businessRegContinue);
    expect(find.text(l10n.businessRegAuthorityHeading), findsOneWidget);
  });

  testWidgets('the director declaration unlocks the review step', (tester) async {
    repository.current = draft(documentId: 'doc-1');
    final l10n = await pumpPage(tester);
    expect(find.text(l10n.businessRegAuthorityHeading), findsOneWidget);
    final continueButton = find.widgetWithText(FilledButton, l10n.businessRegContinue);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    await tapFinder(tester, find.byKey(const ValueKey('director-declaration')));
    await tapText(tester, l10n.businessRegContinue);
    expect(find.text(l10n.businessRegReviewHeading), findsOneWidget);
  });

  testWidgets('review needs consent and confirmation before submitting', (tester) async {
    repository.current = draft(documentId: 'doc-1');
    final l10n = await pumpPage(tester);
    await tapFinder(tester, find.byKey(const ValueKey('director-declaration')));
    await tapText(tester, l10n.businessRegContinue);
    expect(find.text(l10n.businessRegReviewHeading), findsOneWidget);
    expect(find.text('Kao Shop'), findsOneWidget);
    expect(find.text(l10n.businessRegVatNotProvided), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, l10n.businessRegSubmit);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tapText(tester, l10n.businessRegConsent);
    await tapText(tester, l10n.businessRegSubmit);
    expect(find.text(l10n.businessRegSubmitConfirmTitle), findsOneWidget);
    await tapText(tester, l10n.businessRegKeepEditing);
    expect(repository.calls.where((c) => c.startsWith('submit')), isEmpty);

    await tapText(tester, l10n.businessRegSubmit);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(l10n.businessRegSubmit)));
    await tester.pumpAndSettle();
    expect(repository.calls, contains('submit:true'));
    expect(find.text(l10n.businessRegStatusReviewTitle), findsOneWidget);
    expect(find.text(l10n.businessRegCancelDraft), findsNothing);
  });

  testWidgets('without an active Kao ID the form is replaced by the verification gate', (tester) async {
    kaoIdActive = false;
    final l10n = await pumpPage(tester, language: 'th');
    expect(find.text(l10n.businessRegKaoIdRequiredTitle), findsOneWidget);
    expect(find.text(l10n.businessRegDetailsHeading), findsNothing);

    kaoIdActive = true;
    await tapText(tester, l10n.businessRegKaoIdCheckAgain);
    expect(find.text(l10n.businessRegDetailsHeading), findsOneWidget);
  });

  testWidgets('an approved registration links to the company page', (tester) async {
    repository.current = draft(
      documentId: 'doc-1',
      status: BusinessRegistrationStatus.approved,
      submittedAt: DateTime(2026, 10, 1),
    );
    final l10n = await pumpPage(tester);
    expect(find.text(l10n.businessRegStatusApprovedTitle), findsOneWidget);
    expect(find.text(l10n.businessOrgManage), findsOneWidget);
  });

  testWidgets('cancelling a draft asks first and returns to an empty form', (tester) async {
    repository.current = draft(documentId: 'doc-1');
    final l10n = await pumpPage(tester);
    await tapText(tester, l10n.businessRegCancelDraft);
    expect(find.text(l10n.businessRegCancelConfirmTitle), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(l10n.businessRegCancelDraft)));
    await tester.pumpAndSettle();
    expect(repository.calls, contains('cancelDraft'));
    expect(find.text(l10n.businessRegDetailsHeading), findsOneWidget);
  });

  testWidgets('server failures show a readable message without internals', (tester) async {
    final l10n = await pumpPage(tester);
    await tester.enterText(find.widgetWithText(TextFormField, l10n.businessRegNameLabel), 'Kao');
    await tester.enterText(find.widgetWithText(TextFormField, l10n.businessRegNumberLabel), validJuristicNumber);
    await tapText(tester, l10n.businessRegCategoryLabel);
    await tapText(tester, l10n.businessRegCategoryOther);
    await pickCertificateDate(tester, l10n);
    repository.failNext = BusinessRegistrationFailureCode.duplicateRegistration;
    await tapText(tester, l10n.businessRegContinue);
    expect(find.text(l10n.businessRegErrorDuplicate), findsOneWidget);
    expect(find.text(l10n.businessRegDetailsHeading), findsOneWidget);
  });

  for (final language in ['th', 'en', 'my', 'lo']) {
    testWidgets('narrow phone layout has no overflow in $language', (tester) async {
      repository.current = draft(documentId: 'doc-1', vatDocumentId: 'vat-1');
      final l10n = await pumpPage(tester, language: language, size: const Size(320, 900));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(l10n.businessRegAuthorityHeading), findsOneWidget);
      await tapFinder(tester, find.byKey(const ValueKey('director-declaration')));
      await tapText(tester, l10n.businessRegContinue);
      expect(find.text(l10n.businessRegReviewHeading), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
