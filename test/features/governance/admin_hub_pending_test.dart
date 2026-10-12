import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/business/data/providers/business_review_repository_provider.dart';
import 'package:kaosure/features/kao_id/business/presentation/pages/review/business_review_queue_page.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/member_access_provider.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/admin_hub_page.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/kyc_review_providers.dart';
import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_kyc_review_repository.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/kyc_review_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../localization/auth_localization_r2_test.dart' show TestAuthNotifier;
import '../business/business_review_fakes.dart';

final class _KycQueue implements KycReviewRepository {
  _KycQueue(this.size);
  final int size;

  @override
  Future<List<Map<String, dynamic>>> queue() async =>
      [for (var i = 0; i < size; i++) {'id': 'k$i'}];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<AppLocalizations> pump(WidgetTester tester, {required int kyc, Size size = const Size(1280, 1200)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final business = FakeBusinessReviewRepository()
      ..items = [
        reviewItem(),
        reviewItem(id: 'reg-2', name: 'Second Vote Shop', dualReview: true,
            firstReviewerId: 'other', firstDecisionApprove: true),
      ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        memberAccessProvider.overrideWith((ref) async => true),
        kycReviewerAccessProvider.overrideWith((ref) async => true),
        businessReviewRepositoryProvider.overrideWithValue(business),
        kycReviewRepositoryProvider.overrideWithValue(_KycQueue(kyc)),
      ],
      child: MaterialApp(
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdminHubPage(),
      ),
    ));
    await tester.pumpAndSettle();
    return lookupAppLocalizations(const Locale('th'));
  }

  testWidgets('hub shows waiting counts and caps the queue limit', (tester) async {
    final l10n = await pump(tester, kyc: 50);
    expect(find.text('50+'), findsNWidgets(2));
    expect(find.text('2'), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
    expect(find.text(l10n.adminStatBusiness), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('second-reviewer card opens the queue filtered to that state', (tester) async {
    final l10n = await pump(tester, kyc: 0, size: const Size(400, 1400));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(l10n.dualWaiting));
    await tester.pumpAndSettle();
    expect(find.byType(BusinessReviewQueuePage), findsOneWidget);
    expect(find.text('Second Vote Shop'), findsOneWidget);
    expect(find.text('ร้านเก้าเทรดดิ้ง'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
