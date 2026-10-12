abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const String appUrl = String.fromEnvironment(
    'APP_URL',
  );

  /// Comma-separated same-origin service path prefixes allowed for SSO return.
  static const String kaoIdAllowedServicePaths = String.fromEnvironment(
    'KAO_ID_ALLOWED_SERVICE_PATHS',
    defaultValue: '/secondhand',
  );

  static void validate() {
    final missing = <String>[];

    if (supabaseUrl.trim().isEmpty) {
      missing.add('SUPABASE_URL');
    }

    if (supabasePublishableKey.trim().isEmpty) {
      missing.add('SUPABASE_PUBLISHABLE_KEY');
    }

    if (appUrl.trim().isEmpty) {
      missing.add('APP_URL');
    }

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required environment configuration: ${missing.join(', ')}',
      );
    }
  }

  const Env._();
}
