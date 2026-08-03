import 'package:flutter/material.dart';

import '../features/kao_id/auth/presentation/guards/auth_guard.dart';
import '../features/kao_id/auth/presentation/screens/forgot_password_screen.dart';
import '../features/kao_id/auth/presentation/screens/login_screen.dart';
import '../features/kao_id/auth/presentation/screens/register_screen.dart';
import '../features/kao_id/auth/presentation/screens/verify_email_screen.dart';
import '../features/kao_id/dashboard/screens/dashboard_screen.dart';
import '../features/kao_id/bootstrap/screens/kao_id_bootstrap_screen.dart';
import '../features/kao_id/account/presentation/screens/complete_profile_screen.dart';
import '../features/secondhand/presentation/screens/landing_screen.dart';
import '../features/secondhand/presentation/screens/secondhand_home_screen.dart';

final class AppRouter {
  const AppRouter._();

  static const String initialRoute = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LandingScreen(),
        );

      case '/login':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );

      case '/register':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );

      case '/verify-email':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VerifyEmailScreen(),
        );

      case '/forgot-password':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ForgotPasswordScreen(),
        );

      case '/bootstrap':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const KaoIdBootstrapScreen(),
        );

      case '/complete-profile':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: CompleteProfileScreen(),
          ),
        );

      case '/dashboard':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: DashboardScreen(),
          ),
        );

      case '/home':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: SecondhandHomeScreen(),
          ),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LandingScreen(),
        );
    }
  }
}