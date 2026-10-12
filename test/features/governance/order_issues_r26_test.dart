import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/business/data/providers/business_review_repository_provider.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/member_access_provider.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/staff_tools_providers.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/order_issue_case.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/staff_tools.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/order_issue_repository.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/withdrawal_review_repository.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/admin_hub_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/order_issue_detail_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/order_issues_page.dart';
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

final class _IssuesOnly implements WithdrawalReviewRepository {
  @override
  Future<StaffTools> tools() async => const StaffTools(orderIssues: true, openOrderIssues: 3);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _issueJson({String status = 'open', String orderStatus = 'shipped'}) => {
  'id': 'i1',
  'kind': 'not_as_described',
  'detail': 'จอแตกมาจากกล่อง',
  'status': status,
  'resolution_note': status == 'open' ? null : 'รูปยืนยันว่าชำรุด',
  'resolved_by_name': status == 'open' ? null : 'แอดมิน',
  'created_at': '2026-10-13T03:00:00Z',
  'resolved_at': status == 'open' ? null : '2026-10-13T05:00:00Z',
  'sort_at': '2026-10-13T03:00:00Z',
  'order': {
    'id': 'o1',
    'order_number': 'SH261013-AB12CD34',
    'status': orderStatus,
    'total': 4900,
    'payment_method': 'wallet',
    'escrow_status': status == 'open' ? 'disputed' : 'refunded',
    'paid_at': '2026-10-12T03:00:00Z',
    'shipped_at': '2026-10-12T09:00:00Z',
    'receive_by': null,
    'carrier': 'Flash Express',
    'tracking_number': 'TH0001',
    'product_title': 'กล้องฟิล์ม Olympus',
  },
  'buyer': {'id': 'p1', 'display_name': 'ผู้ซื้อ A', 'account_code': 'KAO-0001'},
  'seller': {'id': 'p2', 'display_name': 'ร้าน B', 'account_code': 'KAO-0002'},
  'events': [
    {'event': 'shipped', 'note': 'ผู้ขายแจ้งจัดส่ง', 'created_at': '2026-10-12T09:00:00Z'},
    {'event': 'dispute_opened', 'note': 'not_as_described', 'created_at': '2026-10-13T03:00:00Z'},
  ],
  'history': [
    {
      'id': 'i0',
      'kind': 'not_arrived',
      'status': 'withdrawn',
      'detail': null,
      'created_at': '2026-10-12T20:00:00Z',
      'resolved_at': '2026-10-12T21:00:00Z',
    },
  ],
};

final class _FakeIssues implements OrderIssueRepository {
  Map<String, dynamic> current = _issueJson();
  Object? failure;
  final calls = <String>[];

  @override
  Future<List<OrderIssueCase>> queue(OrderIssueQueueFilter filter, {DateTime? before}) async {
    calls.add('queue:${filter.name}');
    final issue = OrderIssueCase.fromJson(current);
    return issue.isOpen == (filter == OrderIssueQueueFilter.open) ? [issue] : [];
  }

  @override
  Future<OrderIssueCase> detail(String id) async => OrderIssueCase.fromJson(current);

  @override
  Future<OrderIssueCase> resolve(String id, OrderIssueDecision decision, String note) async {
    calls.add('${decision.name}:$id:$note');
    if (failure case final error?) throw error;
    current = _issueJson(status: 'refunded', orderStatus: 'refunded');
    return OrderIssueCase.fromJson(current);
  }
}

void main() {
  late _FakeIssues issues;

  setUp(() => issues = _FakeIssues());

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
          withdrawalReviewRepositoryProvider.overrideWithValue(_IssuesOnly()),
          orderIssueRepositoryProvider.overrideWithValue(issues),
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

  test('staff tools read the order issue permission and count', () {
    final tools = StaffTools.fromJson({'order_issues': true, 'open_order_issues': 4});
    expect(tools.orderIssues, isTrue);
    expect(tools.openOrderIssues, 4);
    expect(tools.marketplace, isTrue);
    expect(tools.any, isTrue);
    expect(StaffTools.fromJson({}).marketplace, isFalse);
  });

  testWidgets('order resolvers see the marketplace group with open problems, and the queue', (tester) async {
    await pump(tester, const AdminHubPage());
    expect(find.text(l.adminGroupMarketplace), findsOneWidget);
    expect(find.text(l.moderationTitle), findsNothing);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text(l.orderIssuesTitle));
    await tester.pumpAndSettle();
    expect(find.byType(OrderIssuesPage), findsOneWidget);
    expect(find.byKey(const ValueKey('order-issue-i1')), findsOneWidget);
    expect(find.textContaining(l.orderIssueKindNotAsDescribed), findsOneWidget);
    expect(find.textContaining('จอแตกมาจากกล่อง'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('order-issues-closed')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('order-issue-i1')), findsNothing);
    expect(find.text(l.staffEmpty), findsOneWidget);
    expect(issues.calls, ['queue:open', 'queue:closed']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a decision needs a note; refunding closes the report', (tester) async {
    await pump(tester, const OrderIssueDetailPage(id: 'i1'));
    expect(find.text('กล้องฟิล์ม Olympus'), findsOneWidget);
    expect(find.text(l.orderIssueEscrowDisputed), findsOneWidget);
    expect(find.text('ผู้ขายแจ้งจัดส่ง'), findsOneWidget);
    expect(find.textContaining(l.orderIssueStatusWithdrawn), findsOneWidget);
    final refund = find.byKey(const ValueKey('order-issue-refund'));
    expect(tester.widget<ButtonStyleButton>(refund).onPressed, isNull);
    expect(tester.widget<ButtonStyleButton>(find.byKey(const ValueKey('order-issue-dismiss'))).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('order-issue-note')), ' รูปยืนยันว่าชำรุด ');
    await tester.pump();
    await tester.tap(refund);
    await tester.pumpAndSettle();
    expect(find.text(l.orderIssueRefundConfirm), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('order-issue-decision-confirm')));
    await tester.pumpAndSettle();

    expect(issues.calls, ['refund:i1:รูปยืนยันว่าชำรุด']);
    expect(find.text(l.orderIssueDone), findsOneWidget);
    expect(find.byKey(const ValueKey('order-issue-closed')), findsOneWidget);
    expect(find.byKey(const ValueKey('order-issue-refund')), findsNothing);
    expect(find.text(l.orderIssueStatusRefunded), findsOneWidget);
    expect(find.text('รูปยืนยันว่าชำรุด'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('refusals are translated and nothing is marked done', (tester) async {
    issues.failure = const PostgrestException(message: 'mfa_required', code: '42501');
    await pump(tester, const OrderIssueDetailPage(id: 'i1'));
    await tester.enterText(find.byKey(const ValueKey('order-issue-note')), 'ส่งช้าแต่ถึงแล้ว');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('order-issue-release')));
    await tester.pumpAndSettle();
    expect(find.text(l.orderIssueReleaseConfirm), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('order-issue-decision-confirm')));
    await tester.pumpAndSettle();
    expect(issues.calls, ['release:i1:ส่งช้าแต่ถึงแล้ว']);
    expect(find.text(l.mfaSessionRequired), findsOneWidget);
    expect(find.byKey(const ValueKey('order-issue-done')), findsNothing);
    expect(orderIssueErrorText(l, Exception('own_order')), l.orderIssueErrorOwn);
    expect(orderIssueErrorText(l, Exception('order_issue_closed')), l.orderIssueErrorClosed);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
