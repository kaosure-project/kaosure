import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/notifiers/auth_notifier.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/password_recovery_provider.dart';
import 'package:kaosure/features/kao_id/auth/domain/entities/user_entity.dart';
import 'package:kaosure/features/kao_id/auth/presentation/pages/change_password_page.dart';
import 'package:kaosure/features/kao_id/auth/presentation/pages/forgot_password_page.dart';
import 'package:kaosure/features/kao_id/auth/presentation/pages/landing_page.dart';
import 'package:kaosure/features/kao_id/auth/presentation/pages/login_page.dart';
import 'package:kaosure/features/kao_id/auth/presentation/pages/register_page.dart';
import 'package:kaosure/features/kao_id/auth/presentation/pages/reset_password_page.dart';
import 'package:kaosure/features/kao_id/auth/presentation/pages/verify_email_page.dart';
import 'package:kaosure/features/kao_id/auth/presentation/widgets/password_requirements.dart';
import 'package:kaosure/features/kao_id/bootstrap/presentation/screens/kao_id_bootstrap_screen.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/widgets/buttons/primary_button.dart';

// No real auth client, email, or network request is used by these tests.
class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(super.ref, {this.failLoading = false});
  final bool failLoading;

  static const user = UserEntity(
    id: 'test-user', email: 'example@example.com', emailConfirmed: false,
  );

  @override
  Future<void> loadCurrentUser() async {
    state = failLoading
        ? AsyncValue.error(StateError('test-auth-load-failed'), StackTrace.current)
        : const AsyncValue.data(user);
  }

  @override
  Future<void> login({required String email, required String password}) async {
    throw StateError('internal-error-must-not-appear');
  }

  @override
  Future<void> reauthenticate() async {}

  @override
  Future<UserEntity?> refreshCurrentUser() async => user;
}

Widget testApp(String language, Widget page, {
  bool recovery = false,
  bool authLoadingError = false,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => TestAuthNotifier(ref, failLoading: authLoadingError)),
      passwordRecoveryAuthorizedProvider.overrideWith((ref) => recovery),
    ],
    child: MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: page,
    ),
  );
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['th', 'en']) {
    final th = language == 'th';

    testWidgets('Bootstrap failure offers retry instead of endless loading in $language', (tester) async {
      await tester.pumpWidget(testApp(language,
        const KaoIdBootstrapScreen(), authLoadingError: true,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(th
          ? 'เปิดบัญชีของคุณไม่สำเร็จ กรุณาลองอีกครั้ง'
          : 'Could not open your account. Please try again.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, th ? 'ลองอีกครั้ง' : 'Try again'));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Login validates and hides raw failures in $language', (tester) async {
      await tester.pumpWidget(testApp(language, const LoginPage()));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byType(FilledButton));
      expect(find.text(th ? 'กรุณากรอกอีเมล' : 'Enter your email'), findsWidgets);
      expect(find.text(th ? 'กรุณากรอกรหัสผ่าน' : 'Enter your password'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).at(0), 'example@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Example123!');
      await tapVisible(tester, find.byType(FilledButton));
      expect(find.text(th
          ? 'เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบข้อมูลและลองอีกครั้ง'
          : 'Could not sign in. Check your details and try again.'), findsOneWidget);
      expect(find.textContaining('internal-error-must-not-appear'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Registration validates confirmation in $language', (tester) async {
      await tester.pumpWidget(testApp(language, const RegisterPage()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'example@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Example123!');
      await tester.enterText(find.byType(TextFormField).at(2), 'Different123!');
      await tapVisible(tester, find.byType(FilledButton));
      expect(find.text(th ? 'รหัสผ่านไม่ตรงกัน' : 'Passwords do not match'), findsOneWidget);
      expect(find.byIcon(Icons.business_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Forgot password rejects malformed email in $language', (tester) async {
      await tester.pumpWidget(testApp(language, const ForgotPasswordPage()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'invalid');
      await tapVisible(tester, find.byType(FilledButton));
      expect(find.text(th ? 'รูปแบบอีเมลไม่ถูกต้อง' : 'Enter a valid email address'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Reset without authorization has no password form in $language', (tester) async {
      await tester.pumpWidget(testApp(language, const ResetPasswordPage()));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text(th
          ? 'ลิงก์ตั้งรหัสผ่านไม่ถูกต้องหรือหมดอายุ'
          : 'This password reset link is invalid or has expired'), findsOneWidget);
      expect(find.text(th ? 'ขอลิงก์ใหม่' : 'Request a new link'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Authorized reset validates the new password in $language', (tester) async {
      await tester.pumpWidget(testApp(language, const ResetPasswordPage(), recovery: true));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byType(FilledButton));
      expect(find.text(th ? 'กรุณากรอกรหัสผ่านใหม่' : 'Enter a new password'), findsWidgets);
      expect(find.text(th ? 'กรุณายืนยันรหัสผ่านใหม่' : 'Confirm your new password'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Change password requires the verification code in $language', (tester) async {
      await tester.pumpWidget(testApp(language, const ChangePasswordPage()));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      await tapVisible(tester, find.byType(FilledButton));
      expect(find.byType(TextFormField), findsNWidgets(4));
      await tapVisible(tester, find.byType(FilledButton));
      expect(find.text(th ? 'กรุณากรอกรหัสยืนยัน' : 'Enter the verification code'), findsOneWidget);
      expect(find.text(th ? 'กรุณากรอกรหัสผ่านปัจจุบัน' : 'Enter your current password'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Email check reports unverified without claiming success in $language', (tester) async {
      await tester.pumpWidget(testApp(language, const VerifyEmailPage()));
      await tester.pumpAndSettle();
      expect(find.text('example@example.com'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(FilledButton, th ? 'ตรวจสอบอีกครั้ง' : 'Check again'));
      expect(find.text(th ? 'ยังไม่ได้ยืนยันอีเมล' : 'Email has not been verified yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Primary action wraps at 320px with large text in $language', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var tapped = false;
      await tester.pumpWidget(testApp(language, Scaffold(
        body: Builder(builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: Center(child: SizedBox(
            width: 200,
            child: PrimaryButton(
              text: AppLocalizations.of(context).authResendVerificationEmail,
              icon: Icons.send,
              onPressed: () => tapped = true,
            ),
          )),
        )),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Requirements match existing number and special rules in $language', (tester) async {
      await tester.pumpWidget(testApp(language, const Scaffold(
        body: PasswordRequirements(password: '1234567!'),
      )));
      await tester.pumpAndSettle();
      expect(find.text(th ? '✓ 8 ตัวขึ้นไป' : '✓ 8 or more characters'), findsOneWidget);
      expect(find.text(th ? '✓ ตัวเลข' : '✓ A number'), findsOneWidget);
      expect(find.text(th ? '✓ อักขระพิเศษ' : '✓ A special character'), findsOneWidget);
      expect(find.textContaining('○'), findsNothing);
    });

    testWidgets('Kao ID landing has localized entry actions in $language', (tester) async {
      await tester.pumpWidget(testApp(language, const LandingPage()));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, th ? 'เข้าสู่ระบบ' : 'Sign in'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, th ? 'สมัครสมาชิก' : 'Sign up'), findsOneWidget);
      expect(find.byType(FlutterLogo), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Password visibility tooltip follows locale without losing input', (tester) async {
    await tester.pumpWidget(testApp('th', const LoginPage()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Example123!');
    await tapVisible(tester, find.byTooltip('แสดงรหัสผ่าน'));
    expect(find.byTooltip('ซ่อนรหัสผ่าน'), findsOneWidget);
    await tester.pumpWidget(testApp('en', const LoginPage()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hide password'), findsOneWidget);
    final password = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(password.controller!.text, 'Example123!');
    expect(password.obscureText, isFalse);
    expect(tester.takeException(), isNull);
  });
}
