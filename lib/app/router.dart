import 'package:flutter/material.dart';

import '../features/kao_id/account/presentation/pages/complete_profile_page.dart';
import '../features/kao_id/auth/presentation/guards/auth_guard.dart';
import '../features/kao_id/auth/presentation/pages/forgot_password_page.dart';
import '../features/kao_id/auth/presentation/pages/login_page.dart';
import '../features/kao_id/auth/presentation/pages/register_page.dart';
import '../features/kao_id/auth/presentation/pages/verify_email_page.dart';
import '../features/kao_id/bootstrap/screens/kao_id_bootstrap_screen.dart';
import '../features/kao_id/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/pudtan/presentation/screens/pudtan_chat_screen.dart';
import '../features/secondhand/presentation/screens/landing_screen.dart';
import '../features/secondhand/presentation/screens/secondhand_home_screen.dart';

final class AppRouter {
  const AppRouter._();

  static const String initialRoute = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // -----------------------------------------------------------------------
      // Temporary entry point
      //
      // Secondhand Landing เป็นทางเข้าชั่วคราวของระบบในปัจจุบัน
      // ผู้ใช้สามารถเข้าสู่ Kao ID ผ่าน Login / Register จากหน้านี้
      // -----------------------------------------------------------------------
      case '/':
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
          builder: (_) =>
              const AuthGuard(authenticatedChild: CompleteProfilePage()),
        );

      // -----------------------------------------------------------------------
      // Kao ID Dashboard
      // -----------------------------------------------------------------------
      case '/dashboard':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const AuthGuard(authenticatedChild: DashboardScreen()),
        );

      // -----------------------------------------------------------------------
      // KaoSure Secondhand Marketplace
      // -----------------------------------------------------------------------
      case '/home':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const AuthGuard(authenticatedChild: SecondhandHomeScreen()),
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
      // Unknown route
      // -----------------------------------------------------------------------
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LandingScreen(),
        );
    }
  }
}
