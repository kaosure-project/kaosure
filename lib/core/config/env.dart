abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static void validate() {
    final missing = <String>[];

    if (supabaseUrl.trim().isEmpty) {
      missing.add('SUPABASE_URL');
    }

    if (supabasePublishableKey.trim().isEmpty) {
      missing.add('SUPABASE_PUBLISHABLE_KEY');
    }

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required environment configuration: ${missing.join(', ')}',
      );
    }
  }

  const Env._();
}
