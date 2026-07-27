import 'package:flutter/material.dart';

import '../features/kao_id/presentation/auth/guards/auth_guard.dart';
import '../features/kao_id/presentation/auth/screens/forgot_password_screen.dart';
import '../features/kao_id/presentation/auth/screens/login_screen.dart';
import '../features/kao_id/presentation/auth/screens/register_screen.dart';
import '../features/kao_id/presentation/auth/screens/verify_email_screen.dart';
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

      case '/home':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGuard(
            authenticatedChild: SecondhandHomeScreen(),
          ),
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

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LandingScreen(),
        );
    }
  }
}