import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/localization/locale_controller.dart';
import '../features/kao_id/auth/application/providers/auth_provider.dart';
import '../features/kao_id/auth/data/datasources/browser_session_events.dart';
import '../features/kao_id/dashboard/presentation/widgets/settings/sign_out_action.dart';
import 'routes/kao_id_routes.dart';
import '../l10n/app_localizations.dart';
import '../features/kao_id/account/presentation/widgets/account_access_gate.dart';
import 'router.dart';
import 'theme.dart';

final class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  final _restrictedNavigatorKey = GlobalKey<NavigatorState>();

  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<void>? _signedOutElsewhere;

  bool _passwordRecoveryPending = false;

  @override
  void initState() {
    super.initState();

    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
    );
    _signedOutElsewhere = kaoIdSignedOutElsewhere(Uri.parse(SupabaseConfig.url))
        .listen((_) => unawaited(_followSignOut()));
  }

  /// Single sign-out: another tab (Kao ID itself, or Secondhand through
  /// /logout) signed out, so this tab leaves the account too.
  Future<void> _followSignOut() async {
    if (ref.read(authProvider).value == null) return;
    try {
      await ref.read(authProvider.notifier).logout();
    } catch (_) {
      // The session is already gone; the screens follow the cleared state.
    }
    await leaveAfterSignOut(_navigatorKey.currentState ?? _restrictedNavigatorKey.currentState);
  }

  void _handleAuthStateChange(AuthState state) {
    if (state.event != AuthChangeEvent.passwordRecovery) {
      return;
    }

    if (state.session == null) {
      return;
    }

    _passwordRecoveryPending = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openPasswordRecovery(),
    );
  }

  void _openPasswordRecovery() {
    if (!_passwordRecoveryPending || !mounted) {
      return;
    }

    final navigator = _navigatorKey.currentState ?? _restrictedNavigatorKey.currentState;

    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openPasswordRecovery(),
      );
      return;
    }

    _passwordRecoveryPending = false;

    navigator.pushNamedAndRemoveUntil(
      KaoIdRoutes.resetPassword,
      (route) => false,
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _signedOutElsewhere?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);

    final uri = Uri.base;
    final fragmentPath = Uri.tryParse(uri.fragment)?.path;
    final fragmentUri = uri.hasFragment ? Uri.tryParse(uri.fragment) : null;
    
    // ตรวจสอบการส่ง return_to จากทั้ง query parameters และ fragment อย่างอิสระ
    final hasReturnTo =
        uri.queryParameters['return_to']?.trim().isNotEmpty == true ||
        fragmentUri?.queryParameters['return_to']?.trim().isNotEmpty == true;

    // หากมี return_to หรือเปิดมาที่ลิงก์ล็อกอิน ให้บังคับเปิดหน้า Login ทันที
    final isLoginOrHasReturnTo =
        uri.path == KaoIdRoutes.login ||
        hasReturnTo ||
        (uri.path == KaoIdRoutes.register &&
            (fragmentPath == KaoIdRoutes.login || hasReturnTo));

    final initialRoute = isLoginOrHasReturnTo
        ? KaoIdRoutes.login
        : uri.path.isEmpty
        ? AppRouter.initialRoute
        : uri.path;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Kao ID',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates:
          AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Flutter's default deep-link handling can first add `/` and then the
      // requested path. Build only the requested route so `/login` opens the
      // email/password page directly without briefly stacking the landing page.
      onGenerateInitialRoutes: (routeName) => <Route<dynamic>>[
        AppRouter.onGenerateRoute(RouteSettings(name: routeName)),
      ],
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) => AccountAccessGate(
        navigatorKey: _restrictedNavigatorKey, child: child ?? const SizedBox.shrink()),
    );
  }
}