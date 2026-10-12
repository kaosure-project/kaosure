import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/app/router.dart';
import 'package:kaosure/features/kao_id/account/application/providers/account_providers.dart';
import 'package:kaosure/features/kao_id/account/domain/entities/profile.dart';
import 'package:kaosure/features/kao_id/account/domain/repositories/profile_repository.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/password_recovery_provider.dart';
import 'package:kaosure/features/kao_id/auth/presentation/guards/auth_guard.dart';
import 'package:kaosure/features/kao_id/business/presentation/pages/business_completed_page.dart';
import 'package:kaosure/features/kao_id/business/presentation/pages/business_document_page.dart';
import 'package:kaosure/features/kao_id/business/presentation/pages/business_registration_page.dart';
import 'package:kaosure/features/kao_id/business/presentation/pages/business_review_page.dart';
import 'package:kaosure/features/kao_id/dashboard/presentation/widgets/settings/sign_out_tile.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/kyc_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/verification.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/kyc_repository.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/screens/kyc_page.dart';
import 'package:kaosure/app/routes/kao_id_routes.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'auth_localization_r2_test.dart' show TestAuthNotifier;

class LogoutAuth extends TestAuthNotifier {
  LogoutAuth(super.ref, {this.fail = false});
  final bool fail;
  int calls = 0;

  @override
  Future<void> logout() async {
    calls++;
    if (fail) throw StateError('logout-internal-error');
    state = const AsyncValue.data(null);
  }
}

class FailingProfileRepository implements ProfileRepository {
  int loads = 0;
  @override
  Future<Profile> getProfile({required String profileId}) async {
    loads++;
    throw StateError('profile-internal-error');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FailingKycRepository implements KycRepository {
  int loads = 0;
  @override
  Future<Verification> getVerification() async {
    loads++;
    throw StateError('kyc-internal-error');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget app(String language, Widget child) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  routes: {
    KaoIdRoutes.kaoIdLanding: (_) => const Scaffold(body: Text('signed-out-destination')),
  },
  home: child,
);

void main() {
  for (final language in ['th', 'en']) {
    final th = language == 'th';

    for (final result in ['cancel', 'success', 'failure']) {
      testWidgets('Sign out $result in $language', (tester) async {
        late LogoutAuth auth;
        await tester.pumpWidget(ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => auth = LogoutAuth(ref, fail: result == 'failure')),
            passwordRecoveryAuthorizedProvider.overrideWith((ref) => true),
          ],
          child: app(language, const AuthGuard(
            authenticatedChild: Scaffold(body: SignOutTile()),
          )),
        ));
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(tester.element(find.byType(SignOutTile)));
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
        if (result == 'cancel') {
          await tester.tap(find.widgetWithText(TextButton, th ? 'ยกเลิก' : 'Cancel'));
        } else {
          await tester.tap(find.widgetWithText(FilledButton, th ? 'ออกจากระบบ' : 'Sign out'));
        }
        await tester.pumpAndSettle();
        expect(auth.calls, result == 'cancel' ? 0 : 1);
        if (result == 'success') {
          expect(find.text('signed-out-destination'), findsOneWidget);
          expect(container.read(passwordRecoveryAuthorizedProvider), isFalse);
          expect(find.byType(SignOutTile), findsNothing);
        } else {
          expect(find.byType(SignOutTile), findsOneWidget);
          expect(container.read(passwordRecoveryAuthorizedProvider), isTrue);
        }
        if (result == 'failure') {
          expect(find.text(th
              ? 'ออกจากระบบไม่สำเร็จ กรุณาลองอีกครั้ง'
              : 'Could not sign out. Please try again.'), findsOneWidget);
          expect(find.textContaining('logout-internal-error'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Direct KYC loads profile and offers retry for errors in $language', (tester) async {
      final profiles = FailingProfileRepository();
      final kyc = FailingKycRepository();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
          profileRepositoryProvider.overrideWithValue(profiles),
          kycRepositoryProvider.overrideWithValue(kyc),
        ],
        child: app(language, const KycPage()),
      ));
      await tester.pumpAndSettle();
      expect(profiles.loads, 1);
      expect(kyc.loads, 1);
      expect(find.text(th
          ? 'โหลดข้อมูลการยืนยันตัวตนไม่สำเร็จ กรุณาลองอีกครั้ง'
          : 'Could not load your verification details. Please try again.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, th ? 'ลองอีกครั้ง' : 'Try again'));
      await tester.pumpAndSettle();
      expect(profiles.loads, 2);
      expect(kyc.loads, 2);
      expect(find.textContaining('internal-error'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Business argument fallbacks retain the auth guard', (tester) async {
    await tester.pumpWidget(app('en', Builder(builder: (context) {
      for (final name in [BusinessDocumentPage.routeName,
        BusinessReviewPage.routeName, BusinessCompletedPage.routeName]) {
        final route = AppRouter.onGenerateRoute(RouteSettings(name: name))
            as MaterialPageRoute<dynamic>;
        expect(route.settings.name, name);
        final guard = route.builder(context) as AuthGuard;
        expect(guard.authenticatedChild, isA<BusinessRegistrationPage>());
      }
      return const SizedBox.shrink();
    })));
    expect(tester.takeException(), isNull);
  });
}
