import '../features/kao_id/governance/presentation/pages/admin_hub_page.dart';
import '../features/kao_id/governance/presentation/pages/staff_page.dart';
import '../features/kao_id/governance/presentation/pages/member_page.dart';
import 'package:flutter/material.dart';

import '../features/kao_id/account/domain/entities/profile.dart';
import '../features/kao_id/account/presentation/pages/edit_profile_page.dart';
import 'routes/kao_id_routes.dart';

import '../features/kao_id/account/presentation/pages/complete_profile_page.dart';
import '../features/kao_id/auth/presentation/guards/auth_guard.dart';
import '../features/kao_id/auth/presentation/pages/change_password_page.dart';
import '../features/kao_id/auth/presentation/pages/forgot_password_page.dart';
import '../features/kao_id/auth/presentation/pages/login_page.dart';
import '../features/kao_id/auth/presentation/pages/landing_page.dart';
import '../features/kao_id/auth/presentation/pages/register_page.dart';
import '../features/kao_id/auth/presentation/pages/reset_password_page.dart';
import '../features/kao_id/auth/presentation/pages/verify_email_page.dart';
import '../features/kao_id/bootstrap/presentation/screens/kao_id_bootstrap_screen.dart';
import '../features/kao_id/business/presentation/pages/business_registration_page.dart';
import '../features/kao_id/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/kao_id/kyc/presentation/screens/kyc_page.dart';
import '../features/kao_id/personal_info/presentation/pages/personal_info_page.dart';

final class AppRouter {
  const AppRouter._();

  static const String initialRoute = '/';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case '/admin':
        return MaterialPageRoute(settings: settings, builder: (_) => const AuthGuard(authenticatedChild: AdminHubPage()));
      // -----------------------------------------------------------------------
      // Entry Point
      // -----------------------------------------------------------------------
      case initialRoute:
      case KaoIdRoutes.kaoIdLanding:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LandingPage(),
        );

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

      case ResetPasswordPage.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ResetPasswordPage(),
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
      case KaoIdRoutes.profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: DashboardScreen(initialSection: 1),
          ),
        );

      case KaoIdRoutes.security:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: DashboardScreen(initialSection: 2),
          ),
        );

      case KaoIdRoutes.settings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: DashboardScreen(initialSection: 3),
          ),
        );

      case KaoIdRoutes.personalInfo:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(authenticatedChild: PersonalInfoPage()),
        );

      case KaoIdRoutes.editProfile:
        final profileArgument = settings.arguments;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthGuard(
            authenticatedChild: profileArgument is Profile
                ? EditProfilePage(profile: profileArgument)
                : const DashboardScreen(initialSection: 1),
          ),
        );

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
      // Kao ID Security
      // -----------------------------------------------------------------------
      case ChangePasswordPage.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: ChangePasswordPage(),
          ),
        );

      // -----------------------------------------------------------------------
      // Kao ID Business Registration
      // -----------------------------------------------------------------------
      // The stepper resumes from the server draft, so every legacy step URL
      // lands on the same page.
      case KaoIdRoutes.businessRegistration:
      case KaoIdRoutes.businessInformation:
      case KaoIdRoutes.businessDocument:
      case KaoIdRoutes.businessReview:
      case KaoIdRoutes.businessCompleted:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: BusinessRegistrationPage(),
          ),
        );

      // -----------------------------------------------------------------------
      // Kao ID Governance
      // -----------------------------------------------------------------------
      case '/admin/staff':
        return MaterialPageRoute(settings: settings, builder: (_) => const AuthGuard(authenticatedChild: StaffPage()));
      case '/admin/members':
        return MaterialPageRoute(settings: settings, builder: (_) => const AuthGuard(
          authenticatedChild: MemberPage()));

      case '/governance':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: StaffPage(),
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
      // Unknown Route
      // -----------------------------------------------------------------------
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LandingPage(),
        );
    }
  }
}
