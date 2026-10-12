import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_bank_repository.dart';
import 'bank_r8c_test.dart' show BankFixture;
import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_residence_repository.dart';
import 'residence_r8b_test.dart' show ResidenceFixture;
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_passport_repository.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;
import 'passport_r8a_test.dart' show PassportFixture;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/kyc_provider.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/bank/bank_verification_page.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/identity_card/identity_card_page.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/passport/passport_page.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/screens/residence_permit_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_national_id_repository.dart';
import 'national_id_r7a_test.dart' show IdFixture;
import 'kyc_sections_r5_test.dart' show KycFixture;

Widget app(Widget page, String language) => ProviderScope(
  overrides: [
    bankRepositoryProvider.overrideWithValue(BankFixture()),
    residenceRepositoryProvider.overrideWithValue(ResidenceFixture()),
    authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
    passportRepositoryProvider.overrideWithValue(PassportFixture()),
    kycRepositoryProvider.overrideWithValue(KycFixture()),
    nationalIdRepositoryProvider.overrideWithValue(IdFixture()),
  ],
  child: MaterialApp(
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: page,
  ),
);

void checkEnglish(WidgetTester tester) {
  final thai = RegExp(r'[\u0E00-\u0E7F]');
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    expect(thai.hasMatch(text.data ?? text.textSpan?.toPlainText() ?? ''), isFalse,
      reason: 'Unexpected Thai text in the English document page: ${text.data}');
  }
}

void main() {
  final pages = <String, Widget>{
    'id-card': const IdentityCardPage(),
    'passport': const PassportPage(),
    'bank': const BankVerificationPage(),
    'residence': const ResidencePermitPage(),
  };
  for (final language in ['en', 'th']) {
    for (final entry in pages.entries) {
      testWidgets('Document details ${entry.key} in $language', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(app(entry.value, language));
        await tester.pumpAndSettle();
        for (var step = 0; step < 7; step++) {
          expect(tester.takeException(), isNull);
          if (language == 'en') checkEnglish(tester);
          final scroll = find.byType(Scrollable);
          if (scroll.evaluate().isEmpty) break;
          await tester.drag(scroll.first, const Offset(0, -450));
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets('Residence form offers submission after a successful load', (tester) async {
    await tester.pumpWidget(app(const ResidencePermitPage(), 'en'));
    await tester.pumpAndSettle();
    final submit = find.byKey(const ValueKey('residence-submit'));
    await tester.scrollUntilVisible(submit, 200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });
}
