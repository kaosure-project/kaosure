import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/business/data/providers/business_review_repository_provider.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_registration.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_review_outcome.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_review_failure.dart';
import 'package:kaosure/features/kao_id/business/presentation/pages/review/business_review_detail_page.dart';
import 'package:kaosure/features/kao_id/business/presentation/pages/review/business_review_queue_page.dart';
import 'package:kaosure/features/kao_id/business/presentation/widgets/status/registration_status_view.dart';
import 'package:kaosure/features/kao_id/notifications/data/repositories/supabase_notice_target_repository.dart';
import 'package:kaosure/features/kao_id/notifications/presentation/pages/notice_target_page.dart';
import 'package:kaosure/features/kao_id/notifications/presentation/pages/notification_center_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../localization/auth_localization_r2_test.dart' show TestAuthNotifier;
import '../../localization/notice_routing_r14b_test.dart' show TargetFixture;
import 'business_review_fakes.dart';

void main() {
  late FakeBusinessReviewRepository repository;

  setUp(() => repository = FakeBusinessReviewRepository());

  Future<AppLocalizations> pump(WidgetTester tester, Widget home, {
    String language = 'en',
    Size size = const Size(1024, 1600),
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        businessReviewRepositoryProvider.overrideWithValue(repository),
        ...overrides,
      ],
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
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

  bool enabled(WidgetTester tester, String label) {
    final button = tester.widget<ButtonStyleButton>(
        find.ancestor(of: find.text(label), matching: find.bySubtype<ButtonStyleButton>()).first);
    return button.onPressed != null;
  }

  for (final language in ['th', 'en', 'my', 'lo']) {
    testWidgets('queue lists pending businesses on a phone in $language', (tester) async {
      final l10n = await pump(tester, const BusinessReviewQueuePage(),
          language: language, size: const Size(360, 780));
      expect(find.text(l10n.businessReviewTitle), findsOneWidget);
      expect(find.text('ร้านเก้าเทรดดิ้ง'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('filters split new requests from those awaiting a second reviewer', (tester) async {
    repository.items = [
      reviewItem(),
      reviewItem(id: 'reg-2', name: 'Second Vote Shop', dualReview: true,
          firstReviewerId: 'other', firstDecisionApprove: true),
    ];
    final l10n = await pump(tester, const BusinessReviewQueuePage(onlySecondVote: true));
    expect(find.text('Second Vote Shop'), findsOneWidget);
    expect(find.text('ร้านเก้าเทรดดิ้ง'), findsNothing);

    await tapText(tester, '${l10n.businessReviewStatusNew} (1)');
    expect(find.text('Second Vote Shop'), findsNothing);
    expect(find.text('ร้านเก้าเทรดดิ้ง'), findsOneWidget);

    await tapText(tester, '${l10n.businessReviewFilterAll} (2)');
    expect(find.text('Second Vote Shop'), findsOneWidget);
    expect(find.text('ร้านเก้าเทรดดิ้ง'), findsOneWidget);
  });

  testWidgets('empty queue and missing permission show clear messages', (tester) async {
    repository.items = [];
    final l10n = await pump(tester, const BusinessReviewQueuePage());
    expect(find.text(l10n.businessReviewEmpty), findsOneWidget);

    repository.failNext = BusinessReviewFailureCode.noPermission;
    await tester.tap(find.byTooltip(l10n.authCheckAgain));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reviewNoPermission), findsOneWidget);
    expect(find.text(l10n.twoFactorAuthentication), findsOneWidget);
  });

  testWidgets('approving needs the document opened and the checklist ticked', (tester) async {
    final l10n = await pump(tester, Builder(builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => BusinessReviewDetailPage(item: reviewItem()))),
            child: const Text('open'),
          ),
        )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('KAB12CD34EF'), findsOneWidget);
    expect(find.text(l10n.businessReviewBankAccountEnding('7890')), findsOneWidget);
    expect(find.text(l10n.businessReviewViewAllHint), findsOneWidget);
    expect(enabled(tester, l10n.businessReviewApprove), isFalse);

    await tapText(tester, l10n.businessReviewOpenDocument);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text(l10n.businessReviewDocumentViewed), findsOneWidget);
    expect(enabled(tester, l10n.businessReviewApprove), isFalse);

    await tapText(tester, l10n.businessReviewChecked);
    expect(enabled(tester, l10n.businessReviewApprove), isTrue);

    await tapText(tester, l10n.businessReviewApprove);
    expect(find.text(l10n.businessReviewApproveConfirmTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, l10n.businessReviewApprove).last);
    await tester.pumpAndSettle();

    expect(repository.decisions.single.approve, isTrue);
    expect(find.byType(BusinessReviewDetailPage), findsNothing);
    expect(find.text(l10n.businessReviewApprovedMessage), findsOneWidget);
  });

  testWidgets('rejecting asks for a reason before confirming', (tester) async {
    repository.outcome = BusinessReviewOutcome.rejected;
    final l10n = await pump(tester, BusinessReviewDetailPage(item: reviewItem()), language: 'th');

    await tapText(tester, l10n.businessReviewReject);
    expect(find.text(l10n.reviewReasonRequired), findsOneWidget);
    expect(find.text(l10n.businessReviewRejectConfirmTitle), findsNothing);

    await tester.enterText(find.byType(TextField), 'เลขทะเบียนไม่ตรงกับเอกสาร');
    await tapText(tester, l10n.businessReviewReject);
    expect(find.text(l10n.businessReviewRejectConfirmTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, l10n.businessReviewReject).last);
    await tester.pumpAndSettle();
    expect(repository.decisions.single.reason, 'เลขทะเบียนไม่ตรงกับเอกสาร');
  });

  testWidgets('first reviewer sees the pending vote and cannot decide again', (tester) async {
    final l10n = await pump(tester, BusinessReviewDetailPage(
        item: reviewItem(dualReview: true, firstReviewerId: reviewerId, firstDecisionApprove: true)));
    expect(find.text(l10n.dualReviewHelp), findsOneWidget);
    expect(find.text(l10n.dualOwnVote), findsWidgets);
    expect(enabled(tester, l10n.businessReviewReject), isFalse);
  });

  testWidgets('server failure is shown without leaving the page', (tester) async {
    final l10n = await pump(tester, BusinessReviewDetailPage(item: reviewItem()));
    repository.failNext = BusinessReviewFailureCode.ownerBankRequired;
    await tester.enterText(find.byType(TextField), 'Bank changed');
    await tapText(tester, l10n.businessReviewReject);
    await tester.tap(find.widgetWithText(FilledButton, l10n.businessReviewReject).last);
    await tester.pumpAndSettle();
    expect(find.text(l10n.businessReviewErrorOwnerBank), findsOneWidget);
    expect(find.byType(BusinessReviewDetailPage), findsOneWidget);
  });

  testWidgets('business review notice opens the review detail', (tester) async {
    final l10n = await pump(tester, const NoticeTargetPage(noticeId: 'n1'), overrides: [
      noticeTargetRepositoryProvider.overrideWithValue(TargetFixture({
        'kind': 'business_review',
        'row': {
          'id': 'reg-1',
          'business_type': 'registered_business',
          'business_name': 'Kao Trading',
          'registration_number': '0105561234567',
          'business_category': 'retail',
          'paths': ['doc.png'],
          'document_mime': 'image/png',
        },
      })),
    ]);
    expect(find.byType(BusinessReviewDetailPage), findsOneWidget);
    expect(find.text('Kao Trading'), findsWidgets);
    expect(noticeLabel(l10n, 'business_review_new'), l10n.noticeBusinessReviewNew);
    expect(noticeLabel(l10n, 'business_rejected'), l10n.noticeBusinessRejected);
  });

  testWidgets('rejected registration shows the reviewer note to the owner', (tester) async {
    final l10n = await pump(tester, Scaffold(body: SingleChildScrollView(child: RegistrationStatusView(
      registration: const BusinessRegistration(
        id: 'reg-1',
        userId: 'owner',
        businessType: 'registered_business',
        businessName: 'Kao Trading',
        registrationNumber: '0105561234567',
        businessCategory: 'retail',
        status: BusinessRegistrationStatus.rejected,
        reviewReason: 'Document is blurry',
      ),
      refreshing: false,
      onRefresh: () {},
      onStartNew: () {},
      onDone: () {},
    ))), language: 'th');
    expect(find.text(l10n.businessRegStatusReasonLabel), findsOneWidget);
    expect(find.text('Document is blurry'), findsOneWidget);
  });
}
