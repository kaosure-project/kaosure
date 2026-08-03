import 'package:flutter/material.dart';

import '../../domain/entities/verification.dart';
import '../screens/verification_history_screen.dart';

final class VerificationHistoryRoute {
  const VerificationHistoryRoute._();

  static Future<T?> push<T>(
    BuildContext context, {
    required Verification verification,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => VerificationHistoryScreen(
          verification: verification,
        ),
      ),
    );
  }

  static Future<T?> pushReplacement<T>(
    BuildContext context, {
    required Verification verification,
  }) {
    return Navigator.of(context).pushReplacement<T, void>(
      MaterialPageRoute<T>(
        builder: (_) => VerificationHistoryScreen(
          verification: verification,
        ),
      ),
    );
  }

  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context, {
    required Verification verification,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(
        builder: (_) => VerificationHistoryScreen(
          verification: verification,
        ),
      ),
      (_) => false,
    );
  }

  static void pop<T>(
    BuildContext context, [
    T? result,
  ]) {
    Navigator.of(context).pop<T>(result);
  }
}