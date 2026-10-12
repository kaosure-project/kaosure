import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/admin_hub_page.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/member_access_provider.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/kyc_review_providers.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;

void main() {
  for (final language in ['th', 'en']) {
    for (final role in ['owner', 'reviewer', 'member']) {
      testWidgets('Admin hub shows only available duties: $role $language', (tester) async {
        await tester.pumpWidget(ProviderScope(overrides: [
          authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
          memberAccessProvider.overrideWith((ref) async => role == 'owner'),
          kycReviewerAccessProvider.overrideWith((ref) async => role != 'member'),
        ], child: MaterialApp(locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const AdminHubPage())));
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(tester.element(find.byType(AdminHubPage)));
        expect(find.text(l.adminMembersTitle), role == 'owner' ? findsOneWidget : findsNothing);
        expect(find.text(l.staffTitle), role == 'owner' ? findsOneWidget : findsNothing);
        expect(find.text(l.reviewTitle), role == 'member' ? findsNothing : findsOneWidget);
        if (role == 'member') { expect(find.text(l.adminAccessDenied), findsOneWidget); }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
