import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/notifications/notice_target_page.dart';
import 'package:kaosure/features/kao_id/notifications/notification_center.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;
import 'notifications_r10a_test.dart' show NoticeFixture;

class TargetFixture implements NoticeTargetRepository {
  TargetFixture(this.data, {this.fail = false});
  final Map<String, dynamic> data;
  final bool fail;
  @override
  Future<Map<String, dynamic>> open(String id) async {
    if (fail) { throw StateError('private backend detail'); }
    return data;
  }
}
void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    Future<void> mount(WidgetTester tester, TargetFixture repo) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        noticeTargetRepositoryProvider.overrideWithValue(repo),
      ], child: MaterialApp(locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NoticeTargetPage(noticeId: 'notice'))));
      await tester.pumpAndSettle();
    }
    testWidgets('Notice result uses current server status and reason: $locale', (tester) async {
      await mount(tester, TargetFixture({'kind': 'result', 'status': 'rejected', 'reason': 'Evidence unclear'}));
      final l = AppLocalizations.of(tester.element(find.byType(NoticeTargetPage)));
      expect(find.text(l.kycRejected), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is SelectableText && w.data == 'Evidence unclear'), findsOneWidget);
      expect(noticeLabel(l, 'review_second'), l.noticeReviewSecond);
      expect(noticeLabel(l, 'role_revoked'), l.noticeRoleRevoked);
    });
    testWidgets('Completed notice has no review action: $locale', (tester) async {
      await mount(tester, TargetFixture({'kind': 'unavailable'}));
      final l = AppLocalizations.of(tester.element(find.byType(NoticeTargetPage)));
      expect(find.text(l.noticeTargetUnavailable), findsOneWidget);
    });
    testWidgets('Notice access failure does not expose backend or evidence: $locale', (tester) async {
      await mount(tester, TargetFixture({}, fail: true));
      final l = AppLocalizations.of(tester.element(find.byType(NoticeTargetPage)));
      expect(find.text(l.noticeAccessFailed), findsOneWidget);
      expect(find.textContaining('private backend'), findsNothing);
      expect(find.text(l.authCheckAgain), findsOneWidget);
    });
  }
  testWidgets('Open related item marks read and loads current target', (tester) async {
    final inbox = NoticeFixture();
    await tester.pumpWidget(ProviderScope(overrides: [
      authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
      noticeRepositoryProvider.overrideWithValue(inbox),
      noticeTargetRepositoryProvider.overrideWithValue(TargetFixture({'kind': 'result', 'status': 'rejected', 'reason': 'Current reason'})),
    ], child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales, home: const NotificationCenter())));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.open_in_new));
    await tester.pumpAndSettle();
    expect(inbox.readFlag, isTrue);
    expect(find.byType(NoticeTargetPage), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is SelectableText && w.data == 'Current reason'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.drafts_outlined), findsOneWidget);
  });

}
