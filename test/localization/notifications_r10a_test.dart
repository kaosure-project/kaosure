import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/notifications/domain/repositories/notice_repository.dart';
import 'package:kaosure/features/kao_id/notifications/data/repositories/supabase_notice_repository.dart';
import 'package:kaosure/features/kao_id/notifications/presentation/widgets/notification_bell.dart';
import 'package:kaosure/features/kao_id/notifications/presentation/pages/notification_center_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;
class NoticeFixture implements NoticeRepository {
  bool readFlag = false;
  @override
  Future<Map<String, dynamic>> inbox() async => {'unread': readFlag ? 0 : 1, 'items': [
    {'id': 'notice-test', 'message': 'approved', 'is_read': readFlag, 'created_at': '2026-09-29T00:00:00Z'}]};
  @override
  Future<void> read(String id) async { readFlag = true; }
}
void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('Notice uses localized event and acknowledges it: $locale', (tester) async {
      final repo = NoticeFixture();
      await tester.pumpWidget(ProviderScope(overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        noticeRepositoryProvider.overrideWithValue(repo),
      ], child: MaterialApp(locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const NotificationCenter())));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(NotificationCenter)));
      expect(find.text(l.noticeApproved), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
      await tester.tap(find.text(l.noticeApproved));
      await tester.pumpAndSettle();
      expect(repo.readFlag, isTrue);
      expect(find.byIcon(Icons.drafts_outlined), findsOneWidget);
      expect(noticeLabel(l, 'untrusted backend detail'), l.noticeUpdated);
    });
  }
  testWidgets('Bell displays unread count and disposes refresh timer', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
      noticeRepositoryProvider.overrideWithValue(NoticeFixture()),
    ], child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: NotificationBell()))));
    await tester.pumpAndSettle();
    expect(find.textContaining('(1)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
