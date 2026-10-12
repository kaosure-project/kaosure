import 'env.dart';

abstract final class AppConfig {
  static String get baseUrl {
    final value = Env.appUrl.trim();

    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }

    return value;
  }

  static String get passwordRecoveryUrl {
    return '$baseUrl/reset-password';
  }

  const AppConfig._();
}
