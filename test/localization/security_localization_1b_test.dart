import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/widgets/security/dashboard_security_section.dart';
import 'package:kaosure/features/kao_id/router/kao_id_routes.dart';
import 'package:kaosure/l10n/app_localizations.dart';

Widget _testApp(Locale locale, {double textScale = 1}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    routes: {
      // A test-only route probe: no authentication or network calls.
      KaoIdRoutes.changePassword: (_) => const Scaffold(
        body: Text('password-route-probe'),
      ),
    },
    home: const Scaffold(
      body: SingleChildScrollView(
        child: DashboardSecuritySection(),
      ),
    ),
  );
}

const _expected = <String, List<String>>{
  'en': [
    'Security',
    'Password',
    'Change your password',
    'Devices',
    'Manage trusted devices',
    'Login History',
    'Recent sign-in activity',
    'Two-Factor Authentication',
    'Protect your account',
  ],
  'th': [
    'ความปลอดภัย',
    'รหัสผ่าน',
    'เปลี่ยนรหัสผ่านของคุณ',
    'อุปกรณ์',
    'จัดการอุปกรณ์ที่เชื่อถือได้',
    'ประวัติการเข้าสู่ระบบ',
    'กิจกรรมการเข้าสู่ระบบล่าสุด',
    'การยืนยันตัวตนสองขั้นตอน',
    'ปกป้องบัญชีของคุณ',
  ],
};

void main() {
  for (final language in _expected.keys) {
    testWidgets('Security renders all nine labels in $language', (tester) async {
      await tester.pumpWidget(_testApp(Locale(language)));
      await tester.pumpAndSettle();

      for (final text in _expected[language]!) {
        expect(find.text(text), findsOneWidget);
      }
      for (final icon in [
        Icons.lock_outline,
        Icons.devices_outlined,
        Icons.history,
        Icons.security_outlined,
      ]) {
        expect(find.byIcon(icon), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Security supports 320px width and large text in $language',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_testApp(Locale(language), textScale: 2));
      await tester.pumpAndSettle();

      for (final text in _expected[language]!) {
        expect(find.text(text), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Password keeps its existing route in $language', (tester) async {
      await tester.pumpWidget(_testApp(Locale(language)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_expected[language]![1]));
      await tester.pumpAndSettle();

      expect(find.text('password-route-probe'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Existing Security widgets update when locale changes',
      (tester) async {
    await tester.pumpWidget(_testApp(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Security'), findsOneWidget);

    await tester.pumpWidget(_testApp(const Locale('th')));
    await tester.pumpAndSettle();
    expect(find.text('Security'), findsNothing);
    for (final text in _expected['th']!) {
      expect(find.text(text), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
