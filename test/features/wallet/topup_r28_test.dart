import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/wallet/application/providers/topup_providers.dart';
import 'package:kaosure/features/wallet/data/repositories/supabase_topup_repository.dart';
import 'package:kaosure/features/wallet/domain/entities/topup_request.dart';
import 'package:kaosure/features/wallet/domain/failures/topup_failure.dart';
import 'package:kaosure/features/wallet/domain/repositories/topup_repository.dart';
import 'package:kaosure/features/wallet/presentation/pages/topup_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../localization/auth_localization_r2_test.dart' show TestAuthNotifier;

final l = lookupAppLocalizations(const Locale('th'));

TopupRequest _request(TopupStatus status, {double amount = 500}) => TopupRequest(
  id: 't1',
  code: 'TU1A2B3C4D',
  amount: amount,
  status: status,
  receiverName: 'บริษัท เก้าชัวร์ จำกัด',
  promptPayType: 'phone',
  promptPayMasked: '081-xxx-5678',
  qrPayload: status == TopupStatus.awaitingSlip ? '00020101021229370016A000000677010111' : null,
  expiresAt: DateTime.utc(2026, 10, 14, 3),
  createdAt: DateTime.utc(2026, 10, 13, 3),
);

TopupInfo _info({bool can = true, TopupBlock? block, TopupRequest? open}) => TopupInfo(
  canTopUp: can,
  block: block,
  balance: 250,
  minAmount: 100,
  maxAmount: 50000,
  dailyMax: 200000,
  todayTotal: 0,
  slipHours: 24,
  receiverName: 'บริษัท เก้าชัวร์ จำกัด',
  open: open,
);

final class _FakeTopups implements TopupRepository {
  TopupInfo current = _info();
  final history_ = <TopupRequest>[];
  final calls = <String>[];
  Object? failure;

  @override
  Future<TopupInfo> info() async => current;

  @override
  Future<TopupRequest> create(double amount) async {
    calls.add('create:$amount');
    if (failure case final error?) throw error;
    final request = _request(TopupStatus.awaitingSlip, amount: amount);
    current = _info(can: false, block: TopupBlock.requestOpen, open: request);
    return request;
  }

  @override
  Future<TopupRequest> sendSlip(TopupRequest request, Uint8List jpeg) async {
    calls.add('slip:${request.id}:${jpeg.length}');
    if (failure case final error?) throw error;
    final sent = _request(TopupStatus.pendingReview, amount: request.amount);
    current = _info(can: false, block: TopupBlock.requestOpen, open: sent);
    return sent;
  }

  @override
  Future<TopupRequest> cancel(String id) async {
    calls.add('cancel:$id');
    final cancelled = _request(TopupStatus.cancelled);
    current = _info();
    history_.insert(0, cancelled);
    return cancelled;
  }

  @override
  Future<List<TopupRequest>> history({DateTime? before}) async => before == null ? history_ : [];
}

void main() {
  late _FakeTopups topups;
  Uint8List? picked;

  setUp(() {
    topups = _FakeTopups();
    picked = Uint8List.fromList(List.filled(64, 1));
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
          topupRepositoryProvider.overrideWithValue(topups),
          slipPickerProvider.overrideWithValue(() async => picked),
        ],
        child: MaterialApp(
          locale: const Locale('th'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TopupPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a member creates a PromptPay QR within the limits, then sends the slip', (tester) async {
    await pump(tester);
    final create = find.byKey(const ValueKey('topup-create'));
    expect(tester.widget<ButtonStyleButton>(create).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('topup-amount')), '50');
    await tester.pump();
    expect(tester.widget<ButtonStyleButton>(create).onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey('topup-amount')), '12.345');
    await tester.pump();
    expect(tester.widget<ButtonStyleButton>(create).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('topup-amount')), '1,500.50');
    await tester.pump();
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(topups.calls, ['create:1500.5']);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(l.topupCreatedDone), findsOneWidget);
    expect(find.textContaining('081-xxx-5678'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('topup-send-slip')));
    await tester.pumpAndSettle();
    expect(topups.calls.last, 'slip:t1:64');
    expect(find.byType(QrImageView), findsNothing);
    expect(find.byKey(const ValueKey('topup-checking')), findsOneWidget);
    expect(find.text(l.topupSlipSentDone), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('closing the picker sends nothing; a reused slip is explained', (tester) async {
    topups.current = _info(can: false, block: TopupBlock.requestOpen, open: _request(TopupStatus.awaitingSlip));
    picked = null;
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('topup-send-slip')));
    await tester.pumpAndSettle();
    expect(topups.calls, isEmpty);
    expect(find.byKey(const ValueKey('topup-error')), findsNothing);

    picked = Uint8List(8);
    topups.failure = const TopupFailure('slip_duplicate');
    await tester.tap(find.byKey(const ValueKey('topup-send-slip')));
    await tester.pumpAndSettle();
    expect(find.text(l.topupErrorSlipDuplicate), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cancelling asks first and frees the member to start again', (tester) async {
    topups.current = _info(can: false, block: TopupBlock.requestOpen, open: _request(TopupStatus.awaitingSlip));
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('topup-cancel')));
    await tester.pumpAndSettle();
    expect(find.text(l.topupCancelConfirm('฿500.00')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('topup-cancel-confirm')));
    await tester.pumpAndSettle();

    expect(topups.calls, ['cancel:t1']);
    expect(find.text(l.topupCancelledDone), findsOneWidget);
    expect(find.byKey(const ValueKey('topup-create')), findsOneWidget);
    expect(find.byKey(const ValueKey('topup-row-t1')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('without a Kao ID the member sees why and cannot create a QR', (tester) async {
    topups.current = _info(can: false, block: TopupBlock.kaoIdRequired);
    await pump(tester);
    expect(find.text(l.topupBlockKaoId), findsOneWidget);
    expect(find.byKey(const ValueKey('topup-create')), findsNothing);
    expect(find.text(l.topupNoHistory), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('server refusals are shown in the member language', (tester) async {
    topups.failure = const TopupFailure('daily_limit_reached');
    await pump(tester);
    await tester.enterText(find.byKey(const ValueKey('topup-amount')), '500');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('topup-create')));
    await tester.pumpAndSettle();
    expect(find.text(l.topupBlockDaily), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
