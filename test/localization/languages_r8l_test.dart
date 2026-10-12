import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/core/localization/app_languages.dart';
import 'package:kaosure/core/localization/locale_controller.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/widgets/settings/general_settings_tile.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class LanguageFixture extends LocaleController {
  @override
  Locale? build() => const Locale('th');
  @override
  Future<void> setLocale(Locale? locale) async { state = locale; }
}

Map<String, dynamic> arb(String tag) =>
    jsonDecode(File('lib/l10n/app_$tag.arb').readAsStringSync()) as Map<String, dynamic>;
Set<String> keys(Map<String, dynamic> data) => data.keys.where((k) => !k.startsWith('@')).toSet();
Set<String> placeholders(String text) => RegExp(r'\{([a-zA-Z]\w*)\}')
    .allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  const tags = ['ja', 'zh-Hans', 'my', 'lo', 'vi'];
  for (final tag in tags) {
    test('All source keys and placeholders translated: $tag', () {
      final source = arb('en');
      final translated = arb(tag.replaceAll('-', '_'));
      expect(keys(translated), keys(source));
      for (final key in keys(source)) {
        final text = translated[key] as String;
        expect(text.trim(), isNotEmpty, reason: key);
        expect(placeholders(text), placeholders(source[key] as String), reason: key);
        expect(text.contains('\uFFFD'), isFalse, reason: key);
        if (!['appName', 'kaoId', 'kaoCode', 'kaoPay', 'dashSecondhandName', 'authEmail', 'kycEmailTitle', 'kycEmail'].contains(key)) {
          expect(text, isNot(source[key]), reason: 'Untranslated: $tag / $key');
        }
      }
    });
    testWidgets('Language menu switches messages and date picker at 320px: $tag', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 740);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(ProviderScope(overrides: [
        localeControllerProvider.overrideWith(LanguageFixture.new),
      ], child: Consumer(builder: (context, ref, child) => MaterialApp(
        locale: ref.watch(localeControllerProvider),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(builder: (context) {
          final l = AppLocalizations.of(context);
          return Scaffold(body: SafeArea(child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GeneralSettingsTile(),
              Text(l.bankSubmitReview, key: const ValueKey('bank-label')),
              Text(l.authEmailVerified),
              Text(l.idFileHelp),
              Text(l.accountCompletion(50)),
              TextButton(key: const ValueKey('open-date'), onPressed: () {
                showDatePicker(context: context, initialDate: DateTime(2026, 9, 27),
                  firstDate: DateTime(2020), lastDate: DateTime(2030));
              }, child: Text(l.kycSelectDate)),
            ],
          ))));
        }),
      ))));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(GeneralSettingsTile));
      await tester.pumpAndSettle();
      final option = find.text(appLanguageNames[tag]!);
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      final expected = arb(tag.replaceAll('-', '_'));
      expect(tester.widget<Text>(find.byKey(const ValueKey('bank-label'))).data, expected['bankSubmitReview']);
      expect(find.text(expected['authEmailVerified'] as String), findsOneWidget);
      expect(find.text(appLanguageNames[tag]!), findsOneWidget);
      expect(findSupportedLocale(tag), isNotNull);
      final date = find.byKey(const ValueKey('open-date'));
      await tester.ensureVisible(date);
      await tester.tap(date);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(Localizations.localeOf(tester.element(find.byType(DatePickerDialog))).languageCode,
        tag.split('-').first);
      expect(tester.takeException(), isNull);
    });
  }
  test('All menu tags resolve; generic Chinese stays Simplified Chinese', () {
    for (final tag in appLanguageNames.keys) { expect(findSupportedLocale(tag), isNotNull); }
    final zh = arb('zh'), hans = arb('zh_Hans');
    expect(keys(zh), keys(hans));
    for (final key in keys(hans)) { expect(zh[key], hans[key]); }
    expect(appLanguageName(const Locale('zh'), ''), '简体中文');
  });
}
