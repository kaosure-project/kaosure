import 'package:flutter/material.dart';

import '../features/kao_id/account/presentation/pages/complete_profile_page.dart';
import '../features/kao_id/auth/presentation/guards/auth_guard.dart';
import '../features/kao_id/auth/presentation/pages/forgot_password_page.dart';
import '../features/kao_id/auth/presentation/pages/login_page.dart';
import '../features/kao_id/auth/presentation/pages/register_page.dart';
import '../features/kao_id/auth/presentation/pages/verify_email_page.dart';
import '../features/kao_id/bootstrap/screens/kao_id_bootstrap_screen.dart';
import '../features/kao_id/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/kao_id/kyc/presentation/screens/kyc_page.dart';
import '../features/kao_id/governance/presentation/pages/governance_page.dart';

import '../features/kao_id/business/presentation/pages/business_registration_page.dart';
import '../features/kao_id/business/presentation/pages/business_information_page.dart';
import '../features/kao_id/business/presentation/pages/business_document_page.dart';
import '../features/kao_id/business/presentation/pages/business_review_page.dart';
import '../features/kao_id/business/presentation/pages/business_completed_page.dart';

import '../features/pudtan/presentation/screens/pudtan_chat_screen.dart';
import '../features/secondhand/presentation/screens/landing_screen.dart';
import '../features/secondhand/presentation/screens/secondhand_home_screen.dart';

final class AppRouter {
  const AppRouter._();

  static const String initialRoute = '/';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      // -----------------------------------------------------------------------
      // Entry Point
      // -----------------------------------------------------------------------
      case initialRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LandingScreen(),
        );

      // -----------------------------------------------------------------------
      // Kao ID Authentication
      // -----------------------------------------------------------------------
      case '/login':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginPage(),
        );

      case '/register':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterPage(),
        );

      case '/verify-email':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VerifyEmailPage(),
        );

      case '/forgot-password':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ForgotPasswordPage(),
        );

      // -----------------------------------------------------------------------
      // Kao ID Bootstrap
      // -----------------------------------------------------------------------
      case '/bootstrap':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const KaoIdBootstrapScreen(),
        );

      // -----------------------------------------------------------------------
      // Kao ID Account
      // -----------------------------------------------------------------------
      case '/complete-profile':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: CompleteProfilePage(),
          ),
        );

      // -----------------------------------------------------------------------
      // Kao ID Identity / KYC
      // -----------------------------------------------------------------------
      case '/identity/verification':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: KycPage(),
          ),
        );

      // -----------------------------------------------------------------------
      // Kao ID Business Registration
      // -----------------------------------------------------------------------
      case BusinessRegistrationPage.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: BusinessRegistrationPage(),
          ),
        );

      case BusinessInformationPage.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: BusinessInformationPage(),
          ),
        );

      case BusinessDocumentPage.routeName:
        final arguments = settings.arguments;

        if (arguments is! Map<String, dynamic>) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const BusinessRegistrationPage(),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthGuard(
            authenticatedChild: BusinessDocumentPage(
              businessInformation: arguments,
            ),
          ),
        );

      case BusinessReviewPage.routeName:
        final arguments = settings.arguments;

        if (arguments is! Map<String, dynamic>) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const BusinessRegistrationPage(),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthGuard(
            authenticatedChild: BusinessReviewPage(
              businessInformation: arguments,
            ),
          ),
        );

      case BusinessCompletedPage.routeName:
        final arguments = settings.arguments;

        if (arguments is! Map<String, dynamic>) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const BusinessRegistrationPage(),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthGuard(
            authenticatedChild: BusinessCompletedPage(
              businessInformation: arguments,
            ),
          ),
        );

      // -----------------------------------------------------------------------
      // Kao ID Governance
      // -----------------------------------------------------------------------
      case '/governance':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: GovernancePage(),
          ),
        );

      // -----------------------------------------------------------------------
      // Kao ID Dashboard
      // -----------------------------------------------------------------------
      case '/dashboard':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: DashboardScreen(),
          ),
        );

      // -----------------------------------------------------------------------
      // KaoSure Secondhand Marketplace
      // -----------------------------------------------------------------------
      case '/home':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: SecondhandHomeScreen(),
          ),
        );

      // -----------------------------------------------------------------------
      // Pudtan
      // -----------------------------------------------------------------------
      case '/pudtan':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PudtanChatScreen(),
        );

      // -----------------------------------------------------------------------
      // Unknown Route
      // -----------------------------------------------------------------------
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LandingScreen(),
        );
    }
  }
}