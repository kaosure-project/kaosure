import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/business/data/providers/business_review_repository_provider.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/member_access_provider.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/staff_tools_providers.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/staff_tools.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/topup_review.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/topup_review_repository.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/admin_hub_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/topup_detail_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/topup_settings_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/topups_page.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/kyc_review_providers.dart';
import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_kyc_review_repository.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/kyc_review_repository.dart';
import 'package:kaosure/features/wallet/domain/entities/topup_request.dart';
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

TopupReviewItem _item({
  TopupStatus status = TopupStatus.pendingReview,
  double amount = 500,
  bool dual = false,
  String? firstReviewer,
  String? reference,
}) => TopupReviewItem(
  request: TopupRequest(
    id: 't1',
    code: 'TU1A2B3C4D',
    amount: amount,
    status: status,
    sourceApp: 'secondhand',
    receiverName: 'บริษัท เก้าชัวร์ จำกัด',
    promptPayMasked: '081-xxx-5678',
    createdAt: DateTime.utc(2026, 10, 13, 3),
    slipUploadedAt: DateTime.utc(2026, 10, 13, 4),
  ),
  profileId: 'member-1',
  dualReview: dual,
  displayName: 'สมชาย',
  accountCode: 'KAO-0001',
  firstReviewer: firstReviewer,
  firstReviewerName: firstReviewer == null ? null : 'Finance One',
  bankReference: reference,
);

final class _FakeReviews implements TopupReviewRepository {
  _FakeReviews({this.item_, this.kaoIdActive = true, this.own = false});

  TopupReviewItem? item_;
  final bool kaoIdActive;
  final bool own;
  final calls = <String>[];
  Object? failure;
  TopupSettings stored = const TopupSettings(
    enabled: false,
    minAmount: 100,
    maxAmount: 50000,
    dailyMax: 200000,
    dualReviewFrom: 50000,
    slipHours: 24,
    version: 1,
  );
  final saved = <TopupSettings>[];

  TopupReviewItem get item => item_ ??= _item();

  @override
  Future<List<TopupReviewItem>> queue(TopupStatus status, {DateTime? before}) async =>
      item.request.status == status && before == null ? [item] : [];

  @override
  Future<TopupReviewDetail> detail(String id) async => TopupReviewDetail(
    item: item,
    kaoIdActive: kaoIdActive,
    ownRequest: own,
    slipPath: 'member-1/t1/slip.jpg',
    memberName: 'สมชาย ใจดี',
    kaoId: 'KAO-1234-5678',
    walletBalance: 250,
    walletStatus: 'active',
    todayTotal: 500,
    duplicates: const [TopupDuplicateSlip(code: 'TU99999999', status: TopupStatus.approved, amount: 500)],
  );

  @override
  Future<Uint8List> slip(String path) async {
    calls.add('slip:$path');
    throw StateError('no image in tests');
  }

  @override
  Future<TopupReviewItem> approve(String id, {required bool payerConfirmed, required String reference}) async {
    calls.add('approve:$id:$payerConfirmed:$reference');
    if (failure case final error?) throw error;
    final next = item.dualReview && item.request.status == TopupStatus.pendingReview
        ? _item(status: TopupStatus.awaitingSecond, dual: true, amount: item.request.amount, firstReviewer: 'test-user')
        : _item(status: TopupStatus.approved, amount: item.request.amount, reference: reference);
    return item_ = next;
  }

  @override
  Future<TopupReviewItem> reject(String id, String reason) async {
    calls.add('reject:$id:$reason');
    if (failure case final error?) throw error;
    return item_ = _item(status: TopupStatus.rejected);
  }

  @override
  Future<TopupSettings> settings() async => stored;

  @override
  Future<TopupSettings> saveSettings(TopupSettings settings) async {
    saved.add(settings);
    if (failure case final error?) throw error;
    return stored = TopupSettings(
      enabled: settings.enabled,
      promptPayType: settings.promptPayType,
      promptPayId: settings.promptPayId,
      receiverName: settings.receiverName,
      minAmount: settings.minAmount,
      maxAmount: settings.maxAmount,
      dailyMax: settings.dailyMax,
      dualReviewFrom: settings.dualReviewFrom,
      slipHours: settings.slipHours,
      version: settings.version + 1,
    );
  }
}

void main() {
  late _FakeReviews reviews;
  StaffTools tools = const StaffTools(topups: true, topupSettings: true, pendingTopups: 4);

  setUp(() {
    reviews = _FakeReviews();
    tools = const StaffTools(topups: true, topupSettings: true, pendingTopups: 4);
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1280, 3200);
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
          staffToolsProvider.overrideWith((ref) async => tools),
          topupReviewRepositoryProvider.overrideWithValue(reviews),
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
    await tester.tap(find.byKey(const ValueKey('topup-confirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('finance staff open top-ups from the hub with the waiting count', (tester) async {
    await pump(tester, const AdminHubPage());
    expect(find.text(l.topupsTitle), findsOneWidget);
    expect(find.text(l.topupSettingsTitle), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text(l.withdrawalsTitle), findsNothing);

    await tester.tap(find.text(l.topupsTitle));
    await tester.pumpAndSettle();
    expect(find.byType(TopupsPage), findsOneWidget);
    expect(find.byKey(const ValueKey('topup-t1')), findsOneWidget);
    expect(find.byKey(const ValueKey('topups-settings')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('staff without the settings permission get no settings entry', (tester) async {
    tools = const StaffTools(topups: true);
    await pump(tester, const AdminHubPage());
    expect(find.text(l.topupSettingsTitle), findsNothing);
    await tester.tap(find.text(l.topupsTitle));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('topups-settings')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('approving needs the payer confirmation and a bank reference', (tester) async {
    await pump(tester, const TopupDetailPage(id: 't1'));
    expect(find.text('สมชาย ใจดี'), findsOneWidget);
    expect(find.byKey(const ValueKey('topup-duplicate-TU99999999')), findsOneWidget);
    expect(find.text(l.topupReviewSlipFailed), findsOneWidget);
    final approve = find.byKey(const ValueKey('topup-approve'));
    expect(tester.widget<ButtonStyleButton>(approve).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('topup-reference')), ' KBANK-001 ');
    await tester.pump();
    expect(tester.widget<ButtonStyleButton>(approve).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('topup-payer')));
    await tester.pump();
    await tester.tap(approve);
    await tester.pumpAndSettle();
    expect(find.text(l.topupReviewApproveConfirm('฿500.00', 'สมชาย ใจดี')), findsOneWidget);
    await confirm(tester);

    expect(reviews.calls.where((c) => c.startsWith('approve')), ['approve:t1:true:KBANK-001']);
    expect(find.text(l.topupReviewApprovedDone), findsOneWidget);
    expect(find.text(l.topupStatusApproved), findsOneWidget);
    expect(find.byKey(const ValueKey('topup-reference')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('large amounts take a first vote, then wait for someone else', (tester) async {
    reviews = _FakeReviews(item_: _item(amount: 60000, dual: true));
    await pump(tester, const TopupDetailPage(id: 't1'));
    expect(find.byKey(const ValueKey('topup-dual')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('topup-payer')));
    await tester.enterText(find.byKey(const ValueKey('topup-reference')), 'SCB-777');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('topup-approve')));
    await tester.pumpAndSettle();
    expect(find.text(l.topupReviewFirstConfirm('฿60,000.00')), findsOneWidget);
    await confirm(tester);

    expect(find.text(l.topupReviewFirstDone), findsOneWidget);
    expect(find.byKey(const ValueKey('topup-waiting-other')), findsOneWidget);
    expect(find.byKey(const ValueKey('topup-approve')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('server refusals are translated, and declining needs a reason', (tester) async {
    reviews.failure = const PostgrestException(message: 'reference_used', code: '23505');
    await pump(tester, const TopupDetailPage(id: 't1'));
    await tester.tap(find.byKey(const ValueKey('topup-payer')));
    await tester.enterText(find.byKey(const ValueKey('topup-reference')), 'KBANK-001');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('topup-approve')));
    await tester.pumpAndSettle();
    await confirm(tester);
    expect(find.text(l.topupReviewReferenceUsed), findsOneWidget);

    reviews.failure = null;
    final reject = find.byKey(const ValueKey('topup-reject'));
    expect(tester.widget<ButtonStyleButton>(reject).onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey('topup-reason')), 'ชื่อผู้โอนไม่ตรง');
    await tester.pump();
    await tester.tap(reject);
    await tester.pumpAndSettle();
    expect(find.text(l.topupReviewRejectConfirm('฿500.00')), findsOneWidget);
    await confirm(tester);
    expect(reviews.calls, contains('reject:t1:ชื่อผู้โอนไม่ตรง'));
    expect(find.text(l.topupReviewRejectedDone), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('own requests and inactive Kao IDs cannot be approved here', (tester) async {
    reviews = _FakeReviews(own: true);
    await pump(tester, const TopupDetailPage(id: 't1'));
    expect(find.byKey(const ValueKey('topup-own')), findsOneWidget);
    expect(find.byKey(const ValueKey('topup-approve')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());

    reviews = _FakeReviews(kaoIdActive: false);
    await pump(tester, const TopupDetailPage(id: 't1'));
    expect(find.byKey(const ValueKey('topup-kao-id-inactive')), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(find.byKey(const ValueKey('topup-payer'))).onChanged, isNull);
    expect(tester.widget<ButtonStyleButton>(find.byKey(const ValueKey('topup-approve'))).onPressed, isNull);
    expect(find.byKey(const ValueKey('topup-reject')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings check the PromptPay number and send the version', (tester) async {
    await pump(tester, const TopupSettingsPage());
    final save = find.byKey(const ValueKey('topup-settings-save'));
    await tester.tap(find.byKey(const ValueKey('topup-settings-enabled')));
    await tester.pump();
    expect(find.byKey(const ValueKey('topup-settings-not-ready')), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(save).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('topup-settings-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.topupSettingsTypePhone).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('topup-settings-id')), '081-234');
    await tester.enterText(find.byKey(const ValueKey('topup-settings-receiver')), 'บริษัท เก้าชัวร์ จำกัด');
    await tester.pump();
    expect(find.text(l.topupSettingsPromptPayInvalid), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(save).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('topup-settings-id')), '081-234-5678');
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    final sent = reviews.saved.single;
    expect(sent.enabled, isTrue);
    expect(sent.promptPayType, PromptPayType.phone);
    expect(sent.promptPayId, '0812345678');
    expect(sent.version, 1);
    expect(find.text(l.topupSettingsSaved), findsOneWidget);

    reviews.failure = const PostgrestException(message: 'settings_changed', code: '40001');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(reviews.saved.last.version, 2);
    expect(find.text(l.topupSettingsChanged), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
