import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/business/data/providers/business_review_repository_provider.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/member_access_provider.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/staff_tools_providers.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/marketplace_review.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/staff_tools.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/system_content_item.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/review_moderation_repository.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/system_content_repository.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/withdrawal_review_repository.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/admin_hub_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/review_moderation_detail_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/review_moderation_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/system_contents_page.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/kyc_review_providers.dart';
import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_kyc_review_repository.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/kyc_review_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../localization/auth_localization_r2_test.dart' show TestAuthNotifier;
import '../business/business_review_fakes.dart';

final l = lookupAppLocalizations(const Locale('th'));

final class _EmptyKyc implements KycReviewRepository {
  @override
  Future<List<Map<String, dynamic>>> queue() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ReviewsOnly implements WithdrawalReviewRepository {
  @override
  Future<StaffTools> tools() async => const StaffTools(reviews: true, pendingReviewReports: 2);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _reviewJson({bool visible = true, int pending = 2}) => {
  'id': 'r1',
  'order_id': 'o1',
  'order_number': 'SH261013-AB12CD34',
  'verdict': 'bad',
  'comment': 'ผู้ขายโกง เบอร์ 0812345678',
  'preset_text': null,
  'reviewer_role': 'buyer',
  'created_at': '2026-10-13T03:00:00Z',
  'is_visible': visible,
  'hidden_at': visible ? null : '2026-10-13T05:00:00Z',
  'hidden_reason': visible ? null : 'เปิดเผยเบอร์โทร',
  'hidden_by_name': visible ? null : 'แอดมิน',
  'reviewer': {'id': 'p1', 'display_name': 'ผู้ซื้อ A', 'account_code': 'KAO-0001'},
  'reviewee': {'id': 'p2', 'display_name': 'ร้าน B', 'account_code': 'KAO-0002'},
  'pending_reports': pending,
  'total_reports': 2,
  'last_reported_at': '2026-10-13T04:00:00Z',
  'reasons': pending > 0 ? {'personal_info': 1, 'abusive': 1} : <String, int>{},
  'sort_at': '2026-10-13T04:00:00Z',
  'reports': [
    {
      'id': 'rp1',
      'reason': 'personal_info',
      'detail': 'มีเบอร์โทรของผม',
      'status': pending > 0 ? 'pending' : (visible ? 'dismissed' : 'upheld'),
      'created_at': '2026-10-13T04:00:00Z',
      'reporter': {'id': 'p2', 'display_name': 'ร้าน B', 'account_code': 'KAO-0002'},
    },
  ],
};

final class _FakeReviews implements ReviewModerationRepository {
  Map<String, dynamic> current = _reviewJson();
  Object? failure;
  final calls = <String>[];

  @override
  Future<List<MarketplaceReview>> queue(ReviewQueueFilter filter, {DateTime? before}) async {
    calls.add('queue:${filter.name}');
    final review = MarketplaceReview.fromJson(current);
    final match = switch (filter) {
      ReviewQueueFilter.reported => review.pendingReports > 0,
      ReviewQueueFilter.hidden => !review.isVisible,
      ReviewQueueFilter.recent => true,
    };
    return match ? [review] : [];
  }

  @override
  Future<MarketplaceReview> detail(String id) async => MarketplaceReview.fromJson(current);

  @override
  Future<MarketplaceReview> moderate(String id, {required bool hide, String? note}) async {
    calls.add('${hide ? 'hide' : 'show'}:$id:${note ?? '-'}');
    if (failure case final error?) throw error;
    current = _reviewJson(visible: !hide, pending: 0);
    return MarketplaceReview.fromJson(current);
  }
}

final class _FakeContents implements SystemContentRepository {
  final saved = <SystemContentItem>[];

  @override
  Future<List<SystemContentItem>> list({String? app}) async => [];

  @override
  Future<SystemContentItem> save(SystemContentItem item) async {
    saved.add(item);
    return item;
  }

  @override
  Future<void> delete(String id, int version) async {}
}

void main() {
  late _FakeReviews reviews;
  late _FakeContents contents;

  setUp(() {
    reviews = _FakeReviews();
    contents = _FakeContents();
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
          memberAccessProvider.overrideWith((ref) async => false),
          kycReviewerAccessProvider.overrideWith((ref) async => false),
          businessReviewRepositoryProvider.overrideWithValue(FakeBusinessReviewRepository()),
          kycReviewRepositoryProvider.overrideWithValue(_EmptyKyc()),
          withdrawalReviewRepositoryProvider.overrideWithValue(_ReviewsOnly()),
          reviewModerationRepositoryProvider.overrideWithValue(reviews),
          systemContentRepositoryProvider.overrideWithValue(contents),
        ],
        child: MaterialApp(
          locale: const Locale('th'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('review-decision-confirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('review moderators see only the marketplace group, with reported reviews waiting', (tester) async {
    await pump(tester, const AdminHubPage());
    expect(find.text(l.adminGroupMarketplace), findsOneWidget);
    expect(find.text(l.adminGroupFinance), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text(l.adminAccessDenied), findsNothing);

    await tester.tap(find.text(l.moderationTitle));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewModerationPage), findsOneWidget);
    expect(find.byKey(const ValueKey('review-r1')), findsOneWidget);
    expect(find.textContaining(l.moderationPendingReports(2)), findsOneWidget);
    expect(find.textContaining(l.moderationReasonPersonalInfo), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reviews-hidden')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('review-r1')), findsNothing);
    expect(find.text(l.staffEmpty), findsOneWidget);
    expect(reviews.calls, ['queue:reported', 'queue:hidden']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hiding needs a note; the hidden review can be shown again', (tester) async {
    await pump(tester, const ReviewModerationDetailPage(id: 'r1'));
    expect(find.text('ผู้ขายโกง เบอร์ 0812345678'), findsOneWidget);
    expect(find.byKey(const ValueKey('review-report-rp1')), findsOneWidget);
    expect(find.textContaining('มีเบอร์โทรของผม'), findsOneWidget);
    final hide = find.byKey(const ValueKey('review-hide'));
    expect(tester.widget<ButtonStyleButton>(hide).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('review-note')), ' เปิดเผยเบอร์โทร ');
    await tester.pump();
    await tester.tap(hide);
    await tester.pumpAndSettle();
    expect(find.text(l.moderationHideConfirm), findsOneWidget);
    await confirm(tester);

    expect(reviews.calls, ['hide:r1:เปิดเผยเบอร์โทร']);
    expect(find.text(l.moderationDone), findsOneWidget);
    expect(find.text('เปิดเผยเบอร์โทร'), findsOneWidget);
    expect(find.byKey(const ValueKey('review-hide')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('review-show')));
    await tester.pumpAndSettle();
    expect(find.text(l.moderationShowConfirm), findsOneWidget);
    await confirm(tester);
    expect(reviews.calls.last, 'show:r1:-');
    expect(find.byKey(const ValueKey('review-hide')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('keeping a reported review dismisses the reports; refusals are translated', (tester) async {
    reviews.failure = const PostgrestException(message: 'own_review', code: '42501');
    await pump(tester, const ReviewModerationDetailPage(id: 'r1'));
    await tester.tap(find.byKey(const ValueKey('review-keep')));
    await tester.pumpAndSettle();
    expect(find.text(l.moderationKeepConfirm), findsOneWidget);
    await confirm(tester);
    expect(reviews.calls, ['show:r1:-']);
    expect(find.text(l.moderationErrorOwn), findsOneWidget);
    expect(find.byKey(const ValueKey('review-done')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a review preset is saved for Secondhand with whose form shows it', (tester) async {
    await pump(tester, const SystemContentsPage());
    await tester.tap(find.byKey(const ValueKey('contents-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('content-preset-role')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('content-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.contentsCategoryPreset).last);
    await tester.pumpAndSettle();
    expect(find.text(l.contentsPresetHelp), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('content-preset-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.contentsPresetRoleSeller).last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('content-key')), 'secondhand.review_preset.seller_polite');
    await tester.enterText(find.byKey(const ValueKey('content-title-th')), 'สุภาพ');
    await tester.enterText(find.byKey(const ValueKey('content-body-th')), 'ผู้ซื้อสุภาพ ติดต่อง่าย');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('content-save')));
    await tester.pumpAndSettle();

    final item = contents.saved.single;
    expect(item.app, 'secondhand');
    expect(item.category, 'preset');
    expect(item.meta, {'role': 'seller'});
    expect(item.body, {'th': 'ผู้ซื้อสุภาพ ติดต่อง่าย'});
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
