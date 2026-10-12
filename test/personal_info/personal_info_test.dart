import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/personal_info/application/controllers/reveal_controller.dart';
import 'package:kaosure/features/kao_id/personal_info/application/providers/personal_info_providers.dart';
import 'package:kaosure/features/kao_id/personal_info/data/models/personal_info_model.dart';
import 'package:kaosure/features/kao_id/personal_info/domain/entities/personal_info.dart';
import 'package:kaosure/features/kao_id/personal_info/domain/entities/sensitive_field.dart';
import 'package:kaosure/features/kao_id/personal_info/domain/repositories/personal_info_repository.dart';
import 'package:kaosure/features/kao_id/personal_info/presentation/pages/personal_info_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class _Grant extends RevealGrant {
  _Grant(this.expiresAt);
  @override
  final DateTime expiresAt;
}

class FakePersonalInfoRepository implements PersonalInfoRepository {
  int reveals = 0;
  int released = 0;
  String password = 'correct-password';
  Duration grantLifetime = const Duration(minutes: 4);

  @override
  Future<PersonalInfo> load() async => sampleInfo;

  @override
  Future<RevealGrant> unlock(String value) async {
    if (value != password) throw const PersonalInfoFailure('password');
    return _Grant(DateTime.now().add(grantLifetime));
  }

  @override
  Future<String> reveal(RevealGrant grant, SensitiveField field) async {
    reveals++;
    return field == SensitiveField.phone ? '081-234-5678' : '1-2345-67890-12-3';
  }

  @override
  Future<void> release(RevealGrant grant) async => released++;
}

final sampleInfo = PersonalInfoModel.fromJson({
  'name': {'value': 'สมชาย ใจดี', 'status': 'verified'},
  'email': {'value': 'somchai@example.com', 'status': 'verified'},
  'phone': {'masked': '081-XXX-5678', 'status': 'verified'},
  'document': {
    'type': 'thai_national_id',
    'masked_number': '1-XXXX-XXXXX-12-3',
    'status': 'verified',
    'issued_date': '2024-01-15',
    'expiry_date': '2032-01-14',
  },
  'address': {
    'line': '99/1 หมู่ 4 ถนนสุขุมวิท',
    'subdistrict': 'คลองตัน',
    'district': 'คลองเตย',
    'province': 'กรุงเทพมหานคร',
    'postal_code': '10110',
    'status': 'verified',
  },
});

void main() {
  group('PersonalInfoModel', () {
    test('parses statuses and keeps server masking', () {
      expect(sampleInfo.name.mark, VerificationMark.verified);
      expect(sampleInfo.phone.value, '081-XXX-5678');
      expect(sampleInfo.document!.maskedNumber, '1-XXXX-XXXXX-12-3');
      expect(sampleInfo.address!.postalCode, '10110');
    });

    test('masks an unmasked value that slipped into the summary', () {
      final info = PersonalInfoModel.fromJson({
        'phone': {'masked': '0812345678', 'status': 'verified'},
        'document': {'type': 'thai_national_id', 'masked_number': '1234567890123', 'status': 'pending'},
      });
      expect(info.phone.value, 'XXXXXX5678');
      expect(info.document!.maskedNumber, 'XXXXXXXXX0123');
      expect(info.document!.mark, VerificationMark.pending);
      expect(info.address, isNull);
      expect(info.name.isEmpty, isTrue);
    });
  });

  test('RevealController requires the password before revealing', () async {
    final repo = FakePersonalInfoRepository();
    final container = ProviderContainer(
      overrides: [personalInfoRepositoryProvider.overrideWithValue(repo)]);
    final subscription = container.listen(revealControllerProvider, (_, _) {});
    final controller = container.read(revealControllerProvider.notifier);

    expect(controller.needsPassword, isTrue);
    await controller.reveal(SensitiveField.phone);
    expect(subscription.read().error, 'password');
    expect(repo.reveals, 0);

    expect(await controller.unlock('wrong'), 'password');
    expect(controller.needsPassword, isTrue);
    expect(await controller.unlock('correct-password'), isNull);
    expect(controller.needsPassword, isFalse);

    await controller.reveal(SensitiveField.phone);
    expect(subscription.read().revealed[SensitiveField.phone], '081-234-5678');
    controller.hide(SensitiveField.phone);
    expect(subscription.read().revealed, isEmpty);

    container.dispose();
    expect(repo.released, 1);
  });

  testWidgets('shows masked data and reveals after password confirmation', (tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakePersonalInfoRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [personalInfoRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PersonalInfoContent(info: sampleInfo)),
      ),
    ));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(PersonalInfoContent)));

    expect(find.text('081-XXX-5678'), findsOneWidget);
    expect(find.text('1-XXXX-XXXXX-12-3'), findsOneWidget);
    expect(find.text('081-234-5678'), findsNothing);
    expect(find.text(l10n.piBadgeKycVerified), findsWidgets);
    expect(find.text('99/1 หมู่ 4 ถนนสุขุมวิท'), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.piShow).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.piPasswordTitle), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('reveal-password')), 'wrong');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reveal-confirm')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.piPasswordWrong), findsOneWidget);
    expect(repo.reveals, 0);

    await tester.enterText(find.byKey(const ValueKey('reveal-password')), 'correct-password');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reveal-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('081-234-5678'), findsOneWidget);
    expect(repo.reveals, 1);

    await tester.tap(find.byTooltip(l10n.piShow).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.piPasswordTitle), findsNothing);
    expect(find.text('1-2345-67890-12-3'), findsOneWidget);

    await tester.pump(RevealController.visibleFor + const Duration(seconds: 1));
    expect(find.text('081-234-5678'), findsNothing);
    expect(find.text('081-XXX-5678'), findsOneWidget);
  });
}
