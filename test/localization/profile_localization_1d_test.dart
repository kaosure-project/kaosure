import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/account/domain/entities/profile.dart';
import 'package:kaosure/features/kao_id/account/presentation/pages/edit_profile_page.dart';
import 'package:kaosure/features/kao_id/account/presentation/widgets/kao_id_profile/header/description.dart';
import 'package:kaosure/features/kao_id/account/presentation/widgets/kao_id_profile/header/title.dart';
import 'package:kaosure/l10n/app_localizations.dart';

final profile = Profile(
  id: 'localization-test',
  displayName: 'Example Name',
  avatarUrl: null,
  bio: null,
  accountLevel: 'registered',
  accountStatus: 'active',
  role: 'user',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Widget app(String language, Widget home) => ProviderScope(
  child: MaterialApp(
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

Future<void> tapSave(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
 tester.testTextInput.hide();
  await tester.pumpAndSettle();

  final button = find.byType(FilledButton);
  await Scrollable.ensureVisible(
    tester.element(button),
    alignment: 0.5,
  );
  await tester.pumpAndSettle();
  expect(button.hitTestable(), findsOneWidget);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['en', 'th']) {
    testWidgets('Profile header follows $language', (tester) async {
      await tester.pumpWidget(app(language, const Scaffold(
        body: Column(children: [HeaderTitle(), ProfileDescription()]),
      )));
      await tester.pumpAndSettle();
      expect(find.text(language == 'th'
          ? 'แก้ไขโปรไฟล์ของคุณ' : 'Edit your profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edit profile labels and short-name validation in $language',
        (tester) async {
      await tester.pumpWidget(app(language, EditProfilePage(profile: profile)));
      await tester.pumpAndSettle();
      expect(find.text(language == 'th' ? 'แก้ไขโปรไฟล์' : 'Edit profile'),
          findsOneWidget);
      expect(find.text(language == 'th' ? 'ชื่อที่แสดง' : 'Display name'),
          findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'ab');
      await tapSave(tester);
      expect(find.text(language == 'th' ? 'ชื่อต้องมีอย่างน้อย 3 ตัวอักษร'
          : 'Name must contain at least 3 characters'), findsOneWidget);
      expect(find.byType(EditProfilePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edit profile rejects long names in $language', (tester) async {
      await tester.pumpWidget(app(language, EditProfilePage(profile: profile)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), List.filled(31, 'a').join());
      await tapSave(tester);
      expect(find.text(language == 'th' ? 'ชื่อต้องไม่เกิน 30 ตัวอักษร'
          : 'Name must contain no more than 30 characters'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Open edit form follows locale change and keeps entered name',
      (tester) async {
    await tester.pumpWidget(app('en', EditProfilePage(profile: profile)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'My changed name');
    await tester.pumpWidget(app('th', EditProfilePage(profile: profile)));
    await tester.pumpAndSettle();
    expect(find.text('แก้ไขโปรไฟล์'), findsOneWidget);
    expect(find.text('My changed name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
