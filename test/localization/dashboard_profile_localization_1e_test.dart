import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/account/domain/entities/profile.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/widgets/profile/profile_status_chip.dart';
import 'package:kaosure/l10n/app_localizations.dart';

Profile profile({String level = 'registered', String? name, bool complete = false}) {
  return Profile(
    id: 'localization-test',
    displayName: complete ? 'Test Name' : name,
    username: complete ? 'test_user' : null,
    firstName: complete ? 'Test' : null,
    lastName: complete ? 'User' : null,
    avatarUrl: null,
    bio: null,
    accountLevel: level,
    accountStatus: 'active',
    role: 'user',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

Widget app(String language, Widget child) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  for (final language in ['th', 'en']) {
    testWidgets('Dashboard account levels follow $language', (tester) async {
      final labels = language == 'th'
          ? ['ยืนยันตัวตนแล้ว', 'บัญชีธุรกิจ', 'บัญชีองค์กร', 'ลงทะเบียนแล้ว', 'บัญชีมาตรฐาน']
          : ['Identity verified', 'Business account', 'Organization account', 'Registered', 'Standard account'];
      final levels = ['verified', 'business', 'organization', 'registered', 'unknown'];
      for (var i = 0; i < levels.length; i++) {
        await tester.pumpWidget(app(language,
          ProfileStatusChip(profile: profile(level: levels[i]))));
        await tester.pumpAndSettle();
        expect(find.text(labels[i]), findsOneWidget);
        expect(find.byIcon(i < 3 ? Icons.verified : Icons.info_outline), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
