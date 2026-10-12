import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/email/email_verification_page.dart';
import 'package:kaosure/features/kao_id/phone_verification/application/providers/phone_verification_provider.dart';
import 'package:kaosure/features/kao_id/phone_verification/presentation/pages/phone_verification_page.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/phone_verification/application/controllers/phone_verification_controller.dart';
import 'package:kaosure/features/kao_id/phone_verification/domain/phone_verification_repository.dart';

class PhoneFixture implements PhoneVerificationRepository {
  PhoneIdentity identity = const PhoneIdentity('owner', '', false);
  bool confirms = false;
  bool failSend = false;
  int sends = 0;
  int resends = 0;
  int verifies = 0;
  Completer<void>? gate;
  @override
  Future<PhoneIdentity> current() async => identity;
  @override
  Future<void> send(String phone) async {
    sends++;
    if (gate != null) await gate!.future;
    if (failSend) throw StateError('private-provider-message');
  }
  @override
  Future<void> resend(String phone) async { resends++; }
  @override
  Future<void> verify(String phone, String token) async {
    verifies++;
    if (confirms) identity = PhoneIdentity(identity.userId, phone, true);
  }
}

void main() {
  for (final language in ['th', 'en']) {
    for (final email in [true, false]) {
      testWidgets('Contact page fits 320px / large text: $language email=$email', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ProviderScope(overrides: [
          authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
          phoneVerificationRepositoryProvider.overrideWithValue(PhoneFixture()),
        ], child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: email ? const EmailVerificationPage() : const PhoneVerificationPage(),
        )));
        await tester.pumpAndSettle();
        expect(find.text(language == 'th' ? 'ยังไม่ยืนยัน' : 'Not verified'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  test('Thai and international normalization rejects malformed input', () {
    expect(normalizePhone('081-234-5678'), '+66812345678');
    expect(normalizePhone('+81 90 1234 5678'), '+819012345678');
    expect(normalizePhone('hello0812345678'), isNull);
    expect(normalizePhone('123'), isNull);
  });
  test('Successful OTP response alone never confirms a number', () async {
    final repository = PhoneFixture();
    final controller = PhoneVerificationController(repository);
    addTearDown(controller.dispose);
    await controller.sendOtp(phoneNumber: '0812345678');
    await controller.verifyOtp(otp: '123456');
    expect(controller.state.isVerified, isFalse);
    expect(controller.state.isOtpSent, isTrue);
    expect(controller.state.errorMessage, 'pending');
  });
  test('Confirmation requires authoritative matching phone', () async {
    final repository = PhoneFixture()..confirms = true;
    final controller = PhoneVerificationController(repository);
    addTearDown(controller.dispose);
    await controller.sendOtp(phoneNumber: '0812345678');
    await controller.verifyOtp(otp: '123456');
    expect(controller.state.phoneNumber, '+66812345678');
    expect(controller.state.isVerified, isTrue);
    expect(controller.state.pendingPhone, isEmpty);
    expect(controller.state.isOtpSent, isFalse);
  });
  test('Cooldown and resend do not start a second phone change', () async {
    var clock = DateTime(2026);
    final repository = PhoneFixture();
    final controller = PhoneVerificationController(repository, clock: () => clock);
    addTearDown(controller.dispose);
    await controller.sendOtp(phoneNumber: '0812345678');
    await controller.sendOtp(phoneNumber: '0812345678');
    expect(repository.sends, 1);
    expect(repository.resends, 0);
    clock = clock.add(const Duration(seconds: 61));
    await controller.sendOtp(phoneNumber: '0812345678');
    expect(repository.sends, 1);
    expect(repository.resends, 1);
  });
  test('Double submission and dispose do not update dead state', () async {
    final repository = PhoneFixture()..gate = Completer<void>();
    final controller = PhoneVerificationController(repository);
    final pending = controller.sendOtp(phoneNumber: '0812345678');
    await controller.sendOtp(phoneNumber: '0812345678');
    await Future<void>.delayed(Duration.zero);
    expect(repository.sends, 1);
    controller.dispose();
    repository.gate!.complete();
    await pending;
  });
  test('Different signed-in account cannot submit the old OTP', () async {
    final repository = PhoneFixture();
    final controller = PhoneVerificationController(repository);
    addTearDown(controller.dispose);
    await controller.sendOtp(phoneNumber: '0812345678');
    repository.identity = const PhoneIdentity('another-owner', '', false);
    await controller.verifyOtp(otp: '123456');
    expect(repository.verifies, 0);
    expect(controller.state.isOtpSent, isFalse);
    expect(controller.state.errorMessage, 'session');
  });
  test('Transport failure does not expose server messages or remove cooldown', () async {
    final repository = PhoneFixture()..failSend = true;
    final controller = PhoneVerificationController(repository);
    addTearDown(controller.dispose);
    await controller.sendOtp(phoneNumber: '0812345678');
    expect(controller.state.errorMessage, 'send');
    expect(controller.canSend, isFalse);
    expect(controller.state.isOtpSent, isFalse);
  });
}
