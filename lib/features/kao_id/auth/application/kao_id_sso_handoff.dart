import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes/kao_id_routes.dart';
import '../../../../core/config/env.dart';
import '../../sso/domain/usecases/oauth_consent_use_cases.dart';

/// Validates and completes a same-origin web handoff to a service app.
/// Session tokens and identity data are never placed in the return URL.
final class KaoIdSsoHandoff {
  KaoIdSsoHandoff._();

  static const String _pendingReturnKey = 'kao_id.pending_service_return_to';
  static const String _pendingConsentKey = 'kao_id.pending_oauth_authorization_id';
  // Same-navigation fallback if browser storage is unavailable or misses a read.
  static String? _pendingConsentMemoryFallback;
  static const String _serviceLaunchKey = 'kao_id.service_launch';

  /// Query flag on a service entry URL: the service must drop any account it
  /// stored and ask Kao ID who is signed in.
  static const String serviceLaunchParameter = 'kao_id_launch';
  static const Duration serviceLaunchWindow = Duration(minutes: 2);

  /// Remembers that [userId] pressed "Open" on a service, so the consent page
  /// the service's sign-in brings up can continue as that same member.
  static Future<void> markServiceLaunch(String userId) async {
    try {
      await SharedPreferencesAsync().setString(
        _serviceLaunchKey,
        jsonEncode({'uid': userId, 'at': DateTime.now().millisecondsSinceEpoch}),
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to store service launch: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// One-shot: the stored launch is cleared once read.
  static Future<bool> takeServiceLaunch(String? userId) async {
    try {
      final storage = SharedPreferencesAsync();
      final raw = await storage.getString(_serviceLaunchKey);
      if (raw == null) return false;
      await storage.remove(_serviceLaunchKey);
      return isRecentServiceLaunch(raw, userId: userId, now: DateTime.now());
    } catch (error, stackTrace) {
      debugPrint('Unable to read service launch: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static bool isRecentServiceLaunch(String raw, {required String? userId, required DateTime now}) {
    try {
      final launch = jsonDecode(raw);
      if (userId == null || launch is! Map || launch['uid'] != userId) return false;
      final at = launch['at'];
      if (at is! int) return false;
      final age = now.difference(DateTime.fromMillisecondsSinceEpoch(at));
      return !age.isNegative && age <= serviceLaunchWindow;
    } on FormatException {
      return false;
    }
  }

  /// Keeps an OAuth consent request opened before sign-in, so the member lands
  /// back on the consent screen after login or profile completion.
  static Future<void> captureConsentRequest(Uri currentUri) async {
    if (currentUri.path != KaoIdRoutes.oauthConsent) return;
    final authorizationId = currentUri.queryParameters['authorization_id'];

    if (!OAuthConsentUseCases.isValidAuthorizationId(authorizationId)) {
      _pendingConsentMemoryFallback = null;
      try {
        final cleared = await _clearPendingConsent(SharedPreferencesAsync());
        debugPrint(
          '[OAuthFlow][Consent] saved=false '
          'reason=missing_or_invalid_authorization_id '
          'source_path=${currentUri.path} stale_key_cleared=$cleared',
        );
      } catch (error, stackTrace) {
        debugPrint(
          '[OAuthFlow][Consent] capture_error '
          'error_type=${error.runtimeType} source_path=${currentUri.path}',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      return;
    }

    // Keep a per-page-lifecycle copy before writing LocalStorage. This allows
    // the same OAuth navigation to continue if a browser storage read/write fails.
    _pendingConsentMemoryFallback = authorizationId;
    try {
      await SharedPreferencesAsync().setString(_pendingConsentKey, authorizationId!);
      debugPrint(
        '[OAuthFlow][Consent] saved=true '
        'source_path=${currentUri.path} storage_key=$_pendingConsentKey '
        'memory_fallback=ready',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[OAuthFlow][Consent] save_error '
        'error_type=${error.runtimeType} source_path=${currentUri.path} '
        'memory_fallback=ready',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// One-shot: prefer the request captured for this page lifecycle, then use
  /// the persisted request when restoring a page after a reload.
  static Future<String?> takePendingConsent() async {
    final memoryFallback = _pendingConsentMemoryFallback;
    _pendingConsentMemoryFallback = null;
    final fallbackIsValid =
        OAuthConsentUseCases.isValidAuthorizationId(memoryFallback);

    try {
      final storage = SharedPreferencesAsync();
      final authorizationId = await storage.getString(_pendingConsentKey);

      if (fallbackIsValid) {
        final matchesCapturedRequest = authorizationId == memoryFallback;
        final source = matchesCapturedRequest ? 'local_storage' : 'memory_fallback';
        final storedValueState = authorizationId == null
            ? 'missing'
            : matchesCapturedRequest
            ? 'matched'
            : 'different';
        final cleared = authorizationId == null
            ? true
            : await _clearPendingConsent(storage);
        debugPrint(
          '[OAuthFlow][Consent] read=found '
          'source=$source storage_value=$storedValueState '
          'valid=true cleared=$cleared',
        );
        return memoryFallback;
      }

      if (authorizationId == null) {
        debugPrint(
          '[OAuthFlow][Consent] read=missing '
          'source=local_storage fallback_available=false',
        );
        return null;
      }

      final isValid = OAuthConsentUseCases.isValidAuthorizationId(authorizationId);
      final cleared = await _clearPendingConsent(storage);
      if (!isValid) {
        debugPrint(
          '[OAuthFlow][Consent] read=invalid '
          'source=local_storage cleared=$cleared',
        );
        return null;
      }

      debugPrint(
        '[OAuthFlow][Consent] read=found '
        'source=local_storage fallback_available=false '
        'valid=true cleared=$cleared',
      );
      return authorizationId;
    } catch (error, stackTrace) {
      if (fallbackIsValid) {
        debugPrint(
          '[OAuthFlow][Consent] read_error '
          'error_type=${error.runtimeType} fallback_used=true',
        );
        debugPrintStack(stackTrace: stackTrace);
        return memoryFallback;
      }

      debugPrint(
        '[OAuthFlow][Consent] read_error '
        'error_type=${error.runtimeType} fallback_used=false',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static Future<bool> _clearPendingConsent(
    SharedPreferencesAsync storage,
  ) async {
    try {
      await storage.remove(_pendingConsentKey);
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '[OAuthFlow][Consent] clear_error '
        'error_type=${error.runtimeType} storage_key=$_pendingConsentKey',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Uri? validateReturnTo({
    required String rawReturnTo,
    required String appUrl,
    required String allowedServicePaths,
  }) {
    final appUri = Uri.tryParse(appUrl.trim());
    final target = Uri.tryParse(rawReturnTo.trim());
    if (appUri == null ||
        target == null ||
        !_isAllowedWebUri(appUri) ||
        !_isAllowedWebUri(target) ||
        appUri.origin != target.origin ||
        target.userInfo.isNotEmpty ||
        target.hasQuery ||
        target.hasFragment ||
        target.pathSegments.any((segment) => segment == '.' || segment == '..')) {
      return null;
    }

    final allowedPrefixes = allowedServicePaths
        .split(',')
        .map((path) => path.trim())
        .where((path) => path.startsWith('/') && path != '/')
        .toList(growable: false);
    if (!allowedPrefixes.any((prefix) => target.path == prefix || target.path.startsWith('$prefix/'))) {
      return null;
    }
    return target;
  }

  /// Captures the service return target only when entering Kao ID Login.
  static Future<void> captureLoginReturnTarget(Uri currentUri) async {
    final fragment = Uri.tryParse(currentUri.fragment);
    // Secondhand's current link is /register?return_to=...#/login. Some
    // deployed builds omit the hash route, so a validated return_to on the
    // legacy /register URL must also be captured before App routes to /login.
    final hasServiceReturn =
        currentUri.queryParameters['return_to']?.trim().isNotEmpty == true ||
        fragment?.queryParameters['return_to']?.trim().isNotEmpty == true;
    final isLoginRoute =
        currentUri.path == '/login' ||
        (currentUri.path == '/register' &&
            (fragment?.path == KaoIdRoutes.login || hasServiceReturn));
    if (!isLoginRoute) return;
    const route = '/login';
    final rawReturnTo = currentUri.queryParameters['return_to'] ??
        fragment?.queryParameters['return_to'];

    try {
      final storage = SharedPreferencesAsync();
      final appUri = Uri.tryParse(Env.appUrl.trim());
      if (rawReturnTo == null || appUri == null || currentUri.origin != appUri.origin) {
        await storage.remove(_pendingReturnKey);
        final reason = rawReturnTo == null
            ? 'return_target_missing'
            : 'issuer_origin_mismatch';
        debugPrint(
          '[OAuthFlow][Handoff] captured=false '
          'reason=$reason',
        );
        return;
      }
      final target = validateReturnTo(
        rawReturnTo: rawReturnTo,
        appUrl: Env.appUrl,
        allowedServicePaths: Env.kaoIdAllowedServicePaths,
      );
      if (target == null) {
        await storage.remove(_pendingReturnKey);
        debugPrint('[OAuthFlow][Handoff] captured=false '
            'reason=return_target_rejected');
        return;
      }
      await storage.setString(_pendingReturnKey, target.toString());
      debugPrint(
        '[OAuthFlow][Handoff] captured=true route=$route '
        'target_path=${target.path}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[OAuthFlow][Handoff] captured=false '
        'reason=storage_error error_type=${error.runtimeType}',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<bool> hasPendingLoginReturn() async {
    if (!kIsWeb) return false;
    final rawReturnTo = await SharedPreferencesAsync().getString(_pendingReturnKey);
    if (rawReturnTo == null) return false;
    return validateReturnTo(
          rawReturnTo: rawReturnTo,
          appUrl: Env.appUrl,
          allowedServicePaths: Env.kaoIdAllowedServicePaths,
        ) !=
        null;
  }

  /// Returns to the service after a successful Kao ID sign-in.
  ///
  /// This is navigation only. The service still performs its own OAuth code
  /// exchange and applies its own account and row-level access checks. Requiring
  /// `account_access_r10d` here made a missing or temporarily failing RPC strand
  /// a successfully signed-in member on Kao ID, before the service could handle
  /// the session itself.
  static Future<bool> tryReturnToService() async {
    final storage = SharedPreferencesAsync();
    String? targetToRestore;
    try {
      final rawReturnTo = await storage.getString(_pendingReturnKey);
      if (rawReturnTo == null) {
        debugPrint('[OAuthFlow][Handoff] returned=false '
            'reason=no_pending_target');
        return false;
      }

      final target = validateReturnTo(
        rawReturnTo: rawReturnTo,
        appUrl: Env.appUrl,
        allowedServicePaths: Env.kaoIdAllowedServicePaths,
      );
      final appUri = Uri.tryParse(Env.appUrl.trim());
      if (target == null) {
        await storage.remove(_pendingReturnKey);
        debugPrint('[OAuthFlow][Handoff] returned=false '
            'reason=stored_target_rejected');
        return false;
      }
      targetToRestore = target.toString();
      if (!kIsWeb || appUri == null || Uri.base.origin != appUri.origin) {
        debugPrint('[OAuthFlow][Handoff] returned=false '
            'reason=deployment_origin_mismatch');
        return false;
      }

      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null || user.isAnonymous) {
        debugPrint('[OAuthFlow][Handoff] returned=false '
            'reason=no_authenticated_user');
        return false;
      }

      await markServiceLaunch(user.id);
      final launchTarget = target.replace(
        queryParameters: const {serviceLaunchParameter: '1'},
      );
      // Clear immediately before same-tab navigation. Restore the target when
      // the browser refuses to navigate so the user can retry without signing
      // in again.
      await storage.remove(_pendingReturnKey);
      final launched = await launchUrl(
        launchTarget,
        webOnlyWindowName: '_self',
      );
      if (!launched) {
        await storage.setString(_pendingReturnKey, target.toString());
        debugPrint('[OAuthFlow][Handoff] returned=false '
            'reason=browser_navigation_failed');
        return false;
      }
      debugPrint(
        '[OAuthFlow][Handoff] returned=true target_path=${target.path}',
      );
      return true;
    } catch (error, stackTrace) {
      if (targetToRestore != null) {
        try {
          await storage.setString(_pendingReturnKey, targetToRestore);
        } catch (_) {
          // Keep the original handoff error as the useful diagnostic.
        }
      }
      debugPrint(
        '[OAuthFlow][Handoff] returned=false '
        'reason=handoff_error error_type=${error.runtimeType}',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static bool _isAllowedWebUri(Uri uri) {
    if (!uri.hasAuthority || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      return false;
    }
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' && (uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1');
  }
}
