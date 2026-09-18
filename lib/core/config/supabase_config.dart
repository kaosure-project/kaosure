import 'env.dart';

abstract final class SupabaseConfig {
  static String get url => Env.supabaseUrl;

  static String get publishableKey => Env.supabasePublishableKey;

  static void validate() {
    Env.validate();
  }

  const SupabaseConfig._();
}
