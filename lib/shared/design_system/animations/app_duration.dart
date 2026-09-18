library;

/// Animation durations used throughout the application.
abstract final class AppDuration {
  const AppDuration._();

  static const Duration instant = Duration.zero;

  static const Duration veryFast = Duration(milliseconds: 100);

  static const Duration fast = Duration(milliseconds: 200);

  static const Duration normal = Duration(milliseconds: 300);

  static const Duration slow = Duration(milliseconds: 500);

  static const Duration verySlow = Duration(milliseconds: 800);
}