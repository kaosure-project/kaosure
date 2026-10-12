import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/business/application/providers/business_registration_provider.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/payout_bank_account.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_registration_failure.dart';
import 'package:kaosure/features/kao_id/business/domain/usecases/business_registration_use_cases.dart';
import 'package:kaosure/features/kao_id/business/presentation/pages/business_registration_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'business_registration_fakes.dart';

void main() {
  late FakeBusinessRegistrationRepository repository;
  late PayoutBankAccount bank;

  setUp(() {
    repository = FakeBusinessRegistrationRepository();
    bank = pendingBank;
  });

  Future<AppLocalizations> pumpPage(WidgetTester tester, {
    String language = 'en',
    Size size = const Size(1024, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        businessRegistrationUseCasesProvider
            .overrideWithValue(BusinessRegistrationUseCases(repository)),
        payoutBankReaderProvider.overrideWithValue(() async => bank),
        businessDocumentPickerProvider.overrideWithValue(() async => pdfFile()),
      ],
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BusinessRegistrationPage(),
      ),
    ));
    await tester.pumpAndSettle();
    return lookupAppLocalizations(Locale(language));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text).last;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('details step validates in Thai and moves to the document step', (tester) async {
    final l10n = await pumpPage(tester, language: 'th');
    expect(find.text(l10n.businessRegDetailsHeading), findsOneWidget);

    await tapText(tester, l10n.businessRegContinue);
    expect(find.text(l10n.businessRegFieldRequired), findsNWidgets(3));
    expect(repository.calls, isNot(contains('createDraft')));

    await tester.enterText(find.widgetWithText(TextFormField, l10n.businessRegNameLabel), 'ร้านเก้า');
    await tester.enterText(find.widgetWithText(TextFormField, l10n.businessRegNumberLabel), '12345');
    await tapText(tester, l10n.businessRegCategoryLabel);
    await tapText(tester, l10n.businessRegCategoryRetail);
    await tapText(tester, l10n.businessRegContinue);
    expect(find.text(l10n.businessRegNumberInvalid), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, l10n.businessRegNumberLabel), '0105561234567');
    await tapText(tester, l10n.businessRegContinue);
    expect(repository.calls, contains('createDraft'));
    expect(find.text(l10n.businessRegDocumentHeading), findsOneWidget);
    expect(find.textContaining(l10n.businessRegStepCounter(2, 4)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('document upload unlocks continue', (tester) async {
    repository.current = draft();
    final l10n = await pumpPage(tester);
    final continueButton = find.widgetWithText(FilledButton, l10n.businessRegContinue);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    await tapText(tester, l10n.businessRegDocumentChoose);
    expect(repository.calls, contains('attachDocument:certificate.pdf'));
    expect(find.text(l10n.businessRegDocumentUploaded), findsOneWidget);
    expect(find.text('certificate.pdf'), findsOneWidget);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);

    await tapText(tester, l10n.businessRegContinue);
    expect(find.text(l10n.businessRegBankHeading), findsOneWidget);
  });

  testWidgets('pending bank blocks the review step until it is approved', (tester) async {
    repository.current = draft(documentId: 'doc-1');
    final l10n = await pumpPage(tester);
    expect(find.text(l10n.businessRegBankHeading), findsOneWidget);
    expect(find.text(l10n.businessRegBankPending), findsOneWidget);
    expect(find.text('xxx-x-x1234-x'), findsOneWidget);
    final continueButton = find.widgetWithText(FilledButton, l10n.businessRegContinue);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    bank = approvedBank;
    await tapText(tester, l10n.businessRegBankCheckAgain);
    expect(find.text(l10n.businessRegBankApproved), findsOneWidget);
    await tapText(tester, l10n.businessRegContinue);
    expect(find.text(l10n.businessRegReviewHeading), findsOneWidget);
  });

  testWidgets('review needs consent and confirmation before submitting', (tester) async {
    repository.current = draft(documentId: 'doc-1');
    bank = approvedBank;
    final l10n = await pumpPage(tester);
    expect(find.text(l10n.businessRegReviewHeading), findsOneWidget);
    expect(find.text('Kao Shop'), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, l10n.businessRegSubmit);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tapText(tester, l10n.businessRegConsent);
    await tapText(tester, l10n.businessRegSubmit);
    expect(find.text(l10n.businessRegSubmitConfirmTitle), findsOneWidget);
    await tapText(tester, l10n.businessRegKeepEditing);
    expect(repository.calls, isNot(contains('submit')));

    await tapText(tester, l10n.businessRegSubmit);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text(l10n.businessRegSubmit)));
    await tester.pumpAndSettle();
    expect(repository.calls, contains('submit'));
    expect(find.text(l10n.businessRegStatusReviewTitle), findsOneWidget);
    expect(find.text(l10n.businessRegCancelDraft), findsNothing);
  });

  testWidgets('cancelling a draft asks first and returns to an empty form', (tester) async {
    repository.current = draft(documentId: 'doc-1');
    final l10n = await pumpPage(tester);
    await tapText(tester, l10n.businessRegCancelDraft);
    expect(find.text(l10n.businessRegCancelConfirmTitle), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text(l10n.businessRegCancelDraft)));
    await tester.pumpAndSettle();
    expect(repository.calls, contains('cancelDraft'));
    expect(find.text(l10n.businessRegDetailsHeading), findsOneWidget);
  });

  testWidgets('server failures show a readable message without internals', (tester) async {
    final l10n = await pumpPage(tester);
    await tester.enterText(find.widgetWithText(TextFormField, l10n.businessRegNameLabel), 'Kao');
    await tester.enterText(
        find.widgetWithText(TextFormField, l10n.businessRegNumberLabel), '0105561234567');
    await tapText(tester, l10n.businessRegCategoryLabel);
    await tapText(tester, l10n.businessRegCategoryOther);
    repository.failNext = BusinessRegistrationFailureCode.duplicateRegistration;
    await tapText(tester, l10n.businessRegContinue);
    expect(find.text(l10n.businessRegErrorDuplicate), findsOneWidget);
    expect(find.text(l10n.businessRegDetailsHeading), findsOneWidget);
  });

  for (final language in ['th', 'en', 'my', 'lo']) {
    testWidgets('narrow phone layout has no overflow in $language', (tester) async {
      repository.current = draft(documentId: 'doc-1');
      bank = approvedBank;
      final l10n = await pumpPage(tester, language: language, size: const Size(320, 900));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(l10n.businessRegReviewHeading), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
