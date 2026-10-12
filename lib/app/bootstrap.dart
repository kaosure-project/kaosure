import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/localization/locale_controller.dart';
import '../features/kao_id/auth/application/kao_id_sso_handoff.dart';
import '../features/kao_id/auth/application/providers/password_recovery_provider.dart';
import 'routes/kao_id_routes.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  SupabaseConfig.validate();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    authOptions: FlutterAuthClientOptions(
      detectSessionInUri: !kIsWeb,
    ),
  );

  await KaoIdSsoHandoff.captureLoginReturnTarget(Uri.base);

  final didRestorePasswordRecovery =
      await _restoreInitialPasswordRecoverySession();

  final localePreferences = SharedPreferencesAsync();
  Locale? savedLocale;

  try {
    final savedLanguageTag = await localePreferences.getString(
      appLocaleStorageKey,
    );

    savedLocale = findSupportedLocale(savedLanguageTag);
  } catch (error, stackTrace) {
    debugPrint(
      'Unable to load saved locale; using device language: $error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(
    ProviderScope(
      overrides: [
        passwordRecoveryAuthorizedProvider.overrideWith(
          (ref) => didRestorePasswordRecovery,
        ),
        localePreferencesProvider.overrideWithValue(
          localePreferences,
        ),
        initialLocaleProvider.overrideWithValue(
          savedLocale,
        ),
      ],
      child: const App(),
    ),
  );

  if (didRestorePasswordRecovery) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _cleanPasswordRecoveryUrl(),
    );
  }
}

Future<bool> _restoreInitialPasswordRecoverySession() async {
  if (!kIsWeb) {
    return false;
  }

  final uri = Uri.base;

  if (uri.path != KaoIdRoutes.resetPassword) {
    return false;
  }

  final code = uri.queryParameters['code'];

  if (code == null || code.trim().isEmpty) {
    return false;
  }

  try {
    await Supabase.instance.client.auth.exchangeCodeForSession(
      code,
    );

    final hasSession =
        Supabase.instance.client.auth.currentSession != null;

    debugPrint(
      'Password recovery session restored: $hasSession',
    );

    return hasSession;
  } on AuthException catch (error) {
    debugPrint(
      'Password recovery session exchange failed: ${error.message}',
    );

    return false;
  } catch (error, stackTrace) {
    debugPrint(
      'Unexpected password recovery session error: $error',
    );
    debugPrintStack(
      stackTrace: stackTrace,
    );

    return false;
  }
}

void _cleanPasswordRecoveryUrl() {
  if (!kIsWeb) {
    return;
  }

  SystemNavigator.routeInformationUpdated(
    uri: Uri(
      path: '/',
      fragment: KaoIdRoutes.resetPassword,
    ),
    replace: true,
  );
}
