import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/app/router.dart';
import 'package:kaosure/app/routes/kao_id_routes.dart';
import 'package:kaosure/features/kao_id/auth/presentation/guards/auth_guard.dart';
import 'package:kaosure/features/kao_id/auth/presentation/pages/login_page.dart';
import 'package:kaosure/features/kao_id/sso/presentation/pages/oauth_consent_page.dart';

void main() {
  testWidgets('browser initial routes keep their query and still match', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final consent =
                AppRouter.onGenerateRoute(
                      RouteSettings(
                        name: '${KaoIdRoutes.oauthConsent}?authorization_id=abc',
                      ),
                    )
                    as MaterialPageRoute<dynamic>;
            final guard = consent.builder(context) as AuthGuard;
            expect(guard.authenticatedChild, isA<OAuthConsentPage>());

            final login =
                AppRouter.onGenerateRoute(
                      const RouteSettings(name: '/login?return_to=x'),
                    )
                    as MaterialPageRoute<dynamic>;
            expect(login.builder(context), isA<LoginPage>());
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
