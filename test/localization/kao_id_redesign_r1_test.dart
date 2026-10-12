import 'package:kaosure/features/kao_id/notifications/application/providers/notice_inbox_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/member_access_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/app/router.dart';
import 'package:kaosure/features/kao_id/account/domain/entities/profile.dart';
import 'package:kaosure/features/kao_id/account/presentation/pages/edit_profile_page.dart';
import 'package:kaosure/features/kao_id/auth/presentation/guards/auth_guard.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/widgets/dashboard_home_content.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/widgets/kao_id_scaffold.dart';
import 'package:kaosure/app/routes/kao_id_routes.dart';
import 'package:kaosure/l10n/app_localizations.dart';

final sampleProfile = Profile(
  id: 'ui-test', displayName: 'Example User', avatarUrl: null, bio: null,
  accountLevel: 'registered', accountStatus: 'active', role: 'user',
  createdAt: DateTime(2026), updatedAt: DateTime(2026),
);

Widget testApp(String language, Widget child, {double scale = 1}) => ProviderScope(
  overrides: [
    memberAccessProvider.overrideWith((ref) async => false),
    noticeInboxProvider.overrideWith((ref) async => <String, dynamic>{'unread': 0, 'items': <Map<String, dynamic>>[]}),
  ],
  child: MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
));

void main() {
  for (final language in ['th', 'en']) {
    for (final width in [320.0, 1100.0]) {
      testWidgets('Navigation fits $width px in $language', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var selected = -1;
        await tester.pumpWidget(testApp(language, KaoIdScaffold(
          selectedIndex: 0,
          onSelected: (index) => selected = index,
          child: const Center(child: Text('content')),
        ), scale: width == 320 ? 2 : 1));
        await tester.pumpAndSettle();
        final labels = language == 'th'
            ? ['หน้าหลัก', 'บัญชีของฉัน', 'ความปลอดภัย', 'การตั้งค่า']
            : ['Home', 'My account', 'Security', 'Settings'];
        for (var i = 0; i < labels.length; i++) {
          final target = find.text(labels[i]);
          expect(target.hitTestable(), findsOneWidget);
          await tester.tap(target);
          expect(selected, i);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Home shows only connected actions in $language', (tester) async {
      var profileTaps = 0;
      var identityTaps = 0;
      await tester.pumpWidget(testApp(language, Scaffold(
        body: DashboardHomeContent(
          profile: sampleProfile,
          onProfile: () => profileTaps++,
          onIdentity: () => identityTaps++,
          onRefresh: () async {},
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Example User'), findsOneWidget);
      for (final hidden in ['KaoPay', 'Marketplace', 'Auction', 'Kao Code']) {
        expect(find.text(hidden), findsNothing);
      }
      final l = AppLocalizations.of(tester.element(find.byType(DashboardHomeContent)));
      final profileButton = find.widgetWithText(OutlinedButton, l.viewProfile);
      expect(profileButton, findsOneWidget);
      await tester.ensureVisible(profileButton);
      await tester.tap(profileButton);
      final identity = find.byType(FilledButton);
      await tester.scrollUntilVisible(identity, 180, scrollable: find.byType(Scrollable).first);
      await Scrollable.ensureVisible(tester.element(identity), alignment: 0.5);
      await tester.pumpAndSettle();
      expect(identity.hitTestable(), findsOneWidget);
      await tester.tap(identity);
      expect(profileTaps, 1);
      expect(identityTaps, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets('New destinations preserve route names and use the existing guard',
      (tester) async {
    await tester.pumpWidget(testApp('en', Builder(builder: (context) {
      final destinations = {
        KaoIdRoutes.profile: 1,
        KaoIdRoutes.security: 2,
        KaoIdRoutes.settings: 3,
      };
      for (final entry in destinations.entries) {
        final route = AppRouter.onGenerateRoute(RouteSettings(name: entry.key))
            as MaterialPageRoute<dynamic>;
        expect(route.settings.name, entry.key);
        final guard = route.builder(context) as AuthGuard;
        expect((guard.authenticatedChild as DashboardScreen).initialSection, entry.value);
      }
      for (final argument in [sampleProfile, null]) {
        final route = AppRouter.onGenerateRoute(RouteSettings(
          name: KaoIdRoutes.editProfile, arguments: argument,
        )) as MaterialPageRoute<dynamic>;
        final guard = route.builder(context) as AuthGuard;
        if (argument == null) {
          expect((guard.authenticatedChild as DashboardScreen).initialSection, 1);
        } else {
          expect((guard.authenticatedChild as EditProfilePage).profile, same(sampleProfile));
        }
      }
      return const SizedBox.shrink();
    })));
    expect(tester.takeException(), isNull);
  });
}
