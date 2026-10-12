import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/business/data/providers/business_review_repository_provider.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/member_access_provider.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/staff_tools_providers.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/staff_tools.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/system_content_item.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/withdrawal_request.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/system_content_repository.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/withdrawal_review_repository.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/admin_hub_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/system_contents_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/withdrawal_detail_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/withdrawals_page.dart';
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

WithdrawalRequest _request({WithdrawalStatus status = WithdrawalStatus.pending, String? reference}) =>
    WithdrawalRequest(
      id: 'w1',
      profileId: 'member-1',
      amount: 1500,
      status: status,
      bankName: 'ธนาคารกสิกรไทย',
      accountName: 'สมชาย ใจดี',
      last4: '7890',
      displayName: 'สมชาย',
      accountCode: 'KAO-0001',
      createdAt: DateTime.utc(2026, 10, 13, 3),
      transferReference: reference,
    );

final class _FakeWithdrawals implements WithdrawalReviewRepository {
  _FakeWithdrawals({this.bankStillVerified = true});

  final bool bankStillVerified;
  WithdrawalRequest current = _request();
  Object? failure;
  final calls = <String>[];

  @override
  Future<StaffTools> tools() async => const StaffTools(withdrawals: true, contents: true, pendingWithdrawals: 3);

  @override
  Future<List<WithdrawalRequest>> queue(WithdrawalStatus status, {DateTime? before}) async =>
      current.status == status ? [current] : [];

  @override
  Future<WithdrawalTransfer> detail(String id) async => WithdrawalTransfer(
    request: current,
    accountNumber: '1234567890',
    bankStillVerified: bankStillVerified,
    walletBalance: 200,
    walletHold: 1500,
  );

  @override
  Future<WithdrawalRequest> markPaid(String id, String reference) async {
    calls.add('paid:$id:$reference');
    if (failure case final error?) throw error;
    return current = _request(status: WithdrawalStatus.paid, reference: reference);
  }

  @override
  Future<WithdrawalRequest> reject(String id, String reason) async {
    calls.add('reject:$id:$reason');
    if (failure case final error?) throw error;
    return current = _request(status: WithdrawalStatus.rejected);
  }
}

SystemContentItem _content({String id = 'c1', String key = 'secondhand.help.buying', int version = 2}) =>
    SystemContentItem(
      id: id,
      key: key,
      app: 'secondhand',
      category: 'help',
      title: const {'th': 'วิธีซื้อสินค้า', 'en': 'How to buy'},
      body: const {'th': 'กดซื้อทันที', 'en': 'Tap Buy now'},
      meta: const {'icon': 'shopping_bag'},
      version: version,
    );

final class _FakeContents implements SystemContentRepository {
  final items = [_content()];
  final saved = <SystemContentItem>[];
  final deleted = <String>[];
  Object? failure;

  @override
  Future<List<SystemContentItem>> list({String? app}) async => [
    for (final item in items)
      if (app == null || item.app == app) item,
  ];

  @override
  Future<SystemContentItem> save(SystemContentItem item) async {
    if (failure case final error?) throw error;
    saved.add(item);
    final stored = SystemContentItem(
      id: item.id ?? 'c${items.length + 1}',
      key: item.key,
      app: item.app,
      category: item.category,
      title: item.title,
      body: item.body,
      meta: item.meta,
      sortOrder: item.sortOrder,
      isActive: item.isActive,
      version: (item.version ?? 0) + 1,
    );
    items
      ..removeWhere((old) => old.id == stored.id)
      ..add(stored);
    return stored;
  }

  @override
  Future<void> delete(String id, int version) async {
    if (failure case final error?) throw error;
    deleted.add('$id@$version');
    items.removeWhere((item) => item.id == id);
  }
}

void main() {
  late _FakeWithdrawals withdrawals;
  late _FakeContents contents;

  setUp(() {
    withdrawals = _FakeWithdrawals();
    contents = _FakeContents();
  });

  Future<void> pump(WidgetTester tester, Widget home, {bool admin = false}) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
          memberAccessProvider.overrideWith((ref) async => admin),
          kycReviewerAccessProvider.overrideWith((ref) async => admin),
          businessReviewRepositoryProvider.overrideWithValue(FakeBusinessReviewRepository()),
          kycReviewRepositoryProvider.overrideWithValue(_EmptyKyc()),
          withdrawalReviewRepositoryProvider.overrideWithValue(withdrawals),
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
    await tester.tap(find.byKey(const ValueKey('withdrawal-confirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('finance staff without member roles see withdrawals and contents in the hub', (tester) async {
    await pump(tester, const AdminHubPage());
    expect(find.text(l.adminGroupFinance), findsOneWidget);
    expect(find.text(l.contentsTitle), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text(l.adminAccessDenied), findsNothing);

    await tester.tap(find.text(l.withdrawalsTitle));
    await tester.pumpAndSettle();
    expect(find.byType(WithdrawalsPage), findsOneWidget);
    expect(find.byKey(const ValueKey('withdrawal-w1')), findsOneWidget);
    expect(find.textContaining('••••7890'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('marking paid needs a reference and confirms the full account number', (tester) async {
    await pump(tester, const WithdrawalDetailPage(id: 'w1'));
    expect(find.text('1234567890'), findsOneWidget);
    final markPaid = find.byKey(const ValueKey('withdrawal-mark-paid'));
    expect(tester.widget<ButtonStyleButton>(markPaid).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('withdrawal-reference')), ' TRX-889 ');
    await tester.pump();
    await tester.tap(markPaid);
    await tester.pumpAndSettle();
    expect(find.text(l.withdrawalPaidConfirm('฿1,500.00', 'ธนาคารกสิกรไทย', '1234567890')), findsOneWidget);
    await confirm(tester);

    expect(withdrawals.calls, ['paid:w1:TRX-889']);
    expect(find.text(l.withdrawalPaidDone), findsOneWidget);
    expect(find.text(l.withdrawalStatusPaid), findsOneWidget);
    expect(find.text('TRX-889'), findsOneWidget);
    expect(find.byKey(const ValueKey('withdrawal-reference')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a changed bank allows only rejecting, and server errors are translated', (tester) async {
    withdrawals = _FakeWithdrawals(bankStillVerified: false)
      ..failure = const PostgrestException(message: 'withdrawal_not_pending', code: 'P0001');
    await pump(tester, const WithdrawalDetailPage(id: 'w1'));
    expect(find.byKey(const ValueKey('withdrawal-bank-changed')), findsOneWidget);
    final markPaid = find.byKey(const ValueKey('withdrawal-mark-paid'));
    expect(tester.widget<ButtonStyleButton>(markPaid).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('withdrawal-reason')), 'บัญชีปลายทางเปลี่ยน');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('withdrawal-reject')));
    await tester.pumpAndSettle();
    expect(find.text(l.withdrawalRejectConfirm('฿1,500.00')), findsOneWidget);
    await confirm(tester);

    expect(withdrawals.calls, ['reject:w1:บัญชีปลายทางเปลี่ยน']);
    expect(find.text(l.withdrawalErrorNotPending), findsOneWidget);
    expect(find.byKey(const ValueKey('withdrawal-done')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('staff add a content with Thai text and see it in the list', (tester) async {
    await pump(tester, const SystemContentsPage());
    expect(find.byKey(const ValueKey('content-secondhand.help.buying')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('contents-add')));
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('content-save'));
    expect(tester.widget<ButtonStyleButton>(save).onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey('content-key')), 'secondhand.rule.Listing-1');
    await tester.enterText(find.byKey(const ValueKey('content-title-th')), 'กฎการลงขาย');
    await tester.enterText(find.byKey(const ValueKey('content-body-th')), 'ห้ามขายสินค้าผิดกฎหมาย');
    await tester.enterText(find.byKey(const ValueKey('content-icon')), 'gavel');
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    final item = contents.saved.single;
    expect(item.id, isNull);
    expect(item.key, 'secondhand.rule.isting1');
    expect(item.app, 'secondhand');
    expect(item.title, {'th': 'กฎการลงขาย'});
    expect(item.body, {'th': 'ห้ามขายสินค้าผิดกฎหมาย'});
    expect(item.icon, 'gavel');
    expect(find.byType(SystemContentsPage), findsOneWidget);
    expect(find.text('กฎการลงขาย'), findsOneWidget);
    expect(find.text(l.contentsSaved), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('editing keeps the key and sends the version; stale copies are refused', (tester) async {
    await pump(tester, const SystemContentsPage());
    await tester.tap(find.byKey(const ValueKey('content-secondhand.help.buying')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const ValueKey('content-key'))).enabled, isFalse);

    contents.failure = const PostgrestException(message: 'content_changed', code: 'P0001');
    await tester.enterText(find.byKey(const ValueKey('content-title-th')), 'วิธีซื้อ (ใหม่)');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('content-save')));
    await tester.pumpAndSettle();
    expect(find.text(l.contentsErrorChanged), findsOneWidget);

    contents.failure = null;
    await tester.tap(find.byKey(const ValueKey('content-delete')));
    await tester.pumpAndSettle();
    expect(find.text(l.contentsDeleteConfirm('secondhand.help.buying')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('content-delete-confirm')));
    await tester.pumpAndSettle();

    expect(contents.deleted, ['c1@2']);
    expect(find.byType(SystemContentsPage), findsOneWidget);
    expect(find.text(l.staffEmpty), findsOneWidget);
    expect(find.text(l.contentsDeleted), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
