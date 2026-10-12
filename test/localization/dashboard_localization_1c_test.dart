import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/widgets/app_bar/dashboard_app_bar.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/widgets/quick_actions/kao_code_action.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/widgets/quick_actions/quick_action_card.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/widgets/quick_actions/quick_actions_layout.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/widgets/services/dashboard_services_section.dart';
import 'package:kaosure/l10n/app_localizations.dart';

Widget testApp(String language, Widget child, {double textScale = 1}) {
  return MaterialApp(
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: child,
  );
}

void main() {
  for (final language in ['en', 'th']) {
    testWidgets('Services show localized unavailable state in $language',
        (tester) async {
      await tester.pumpWidget(testApp(
        language,
        const Scaffold(body: SingleChildScrollView(
          child: DashboardServicesSection(),
        )),
      ));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(DashboardServicesSection)),
      );
      for (final label in [l10n.services, l10n.marketplace, l10n.auction,
        l10n.kaoPay, l10n.moreServices]) {
        expect(find.text(label), findsOneWidget);
      }
      for (final description in [l10n.marketplaceDescription,
        l10n.auctionDescription, l10n.kaoPayDescription,
        l10n.moreServicesDescription]) {
        expect(find.text('$description · ${l10n.serviceUnavailable}'),
            findsOneWidget);
      }
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(tiles.length, 4);
      for (final tile in tiles) {
        expect(tile.enabled, isFalse);
        expect(tile.onTap, isNull);
      }
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('App bar hides missing actions and supports callbacks in $language',
        (tester) async {
      await tester.pumpWidget(testApp(language,
        const Scaffold(appBar: DashboardAppBar())));
      await tester.pumpAndSettle();
      expect(find.byType(IconButton), findsNothing);
      var notifications = 0;
      var settings = 0;
      await tester.pumpWidget(testApp(language, Scaffold(
        appBar: DashboardAppBar(
          onNotificationPressed: () => notifications++,
          onSettingsPressed: () => settings++,
        ),
      )));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(DashboardAppBar)),
      );
      expect(find.text(l10n.kaoId), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.notifications));
      await tester.tap(find.byTooltip(l10n.settings));
      expect(notifications, 1);
      expect(settings, 1);
      expect(tester.takeException(), isNull);
    });

    for (final width in [320.0, 1100.0]) {
      testWidgets('Cards and services fit $width px with large text in $language',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(testApp(language, Scaffold(
          body: SingleChildScrollView(child: Builder(builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Column(children: [
              QuickActionsLayout(children: [
                QuickActionCard(icon: Icons.person_outline,
                  title: l10n.profile, onTap: () {}),
                QuickActionCard(icon: Icons.verified_user_outlined,
                  title: l10n.verifyIdentity, onTap: () {}),
                const KaoCodeAction(),
              ]),
              const DashboardServicesSection(),
            ]);
          })),
        ), textScale: 2));
        await tester.pumpAndSettle();
        expect(find.byType(QuickActionCard), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Disabled quick action does not invoke its callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(testApp('en', Scaffold(body: QuickActionCard(
      icon: Icons.qr_code_scanner, title: 'Kao Code',
      subtitle: 'Not available yet', enabled: false, onTap: () => taps++,
    ))));
    await tester.tap(find.text('Kao Code'));
    expect(taps, 0);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });

  testWidgets('Empty quick actions layout has no layout exception', (tester) async {
    await tester.pumpWidget(testApp('en', const Scaffold(
      body: QuickActionsLayout(children: []),
    )));
    expect(find.byType(Wrap), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
