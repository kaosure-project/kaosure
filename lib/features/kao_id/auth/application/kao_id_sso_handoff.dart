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
    try {
      final storage = SharedPreferencesAsync();
      if (!OAuthConsentUseCases.isValidAuthorizationId(authorizationId)) {
        await storage.remove(_pendingConsentKey);
        debugPrint(
          '[OAuthFlow][Consent] saved=false '
          'reason=missing_or_invalid_authorization_id '
          'source_path=${currentUri.path} storage_key=$_pendingConsentKey',
        );
        return;
      }
      await storage.setString(_pendingConsentKey, authorizationId!);
      debugPrint(
        '[OAuthFlow][Consent] saved=true '
        'source_path=${currentUri.path} storage_key=$_pendingConsentKey',
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to store OAuth consent request: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// One-shot: the stored request is cleared once read.
  static Future<String?> takePendingConsent() async {
    try {
      final storage = SharedPreferencesAsync();
      final authorizationId = await storage.getString(_pendingConsentKey);
      if (authorizationId == null) return null;
      await storage.remove(_pendingConsentKey);
      return OAuthConsentUseCases.isValidAuthorizationId(authorizationId) ? authorizationId : null;
    } catch (error, stackTrace) {
      debugPrint('Unable to read OAuth consent request: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
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
    if (currentUri.path != '/login') return;
    final rawReturnTo = currentUri.queryParameters['return_to'];

    try {
      final storage = SharedPreferencesAsync();
      final appUri = Uri.tryParse(Env.appUrl.trim());
      if (rawReturnTo == null || appUri == null || currentUri.origin != appUri.origin) {
        await storage.remove(_pendingReturnKey);
        return;
      }
      final target = validateReturnTo(
        rawReturnTo: rawReturnTo,
        appUrl: Env.appUrl,
        allowedServicePaths: Env.kaoIdAllowedServicePaths,
      );
      if (target == null) {
        await storage.remove(_pendingReturnKey);
        return;
      }
      await storage.setString(_pendingReturnKey, target.toString());
    } catch (error, stackTrace) {
      debugPrint('Unable to store Kao ID service return target: $error');
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

  /// Returns only after Supabase confirms the current account is active.
  /// The stored URL is one-shot to prevent replay after refresh or back.
  static Future<bool> tryReturnToService() async {
    try {
      final storage = SharedPreferencesAsync();
      final rawReturnTo = await storage.getString(_pendingReturnKey);
      if (rawReturnTo == null) return false;
      await storage.remove(_pendingReturnKey);

      final target = validateReturnTo(
        rawReturnTo: rawReturnTo,
        appUrl: Env.appUrl,
        allowedServicePaths: Env.kaoIdAllowedServicePaths,
      );
      final appUri = Uri.tryParse(Env.appUrl.trim());
      if (!kIsWeb || target == null || appUri == null || Uri.base.origin != appUri.origin) {
        return false;
      }

      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null || user.isAnonymous) return false;

      final access = await client.rpc('account_access_r10d');
      if (access is! Map || access['state'] != 'active') return false;

      return launchUrl(target, webOnlyWindowName: '_self');
    } catch (error, stackTrace) {
      debugPrint('Kao ID service handoff failed: $error');
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
