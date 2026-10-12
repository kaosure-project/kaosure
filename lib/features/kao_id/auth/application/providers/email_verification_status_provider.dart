import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// Shared display status for the current Auth email.
/// Null means unknown/loading/signed out, never an unverified assertion.
/// This is NOT a purchase-permission or proof-of-ownership policy.
final emailVerificationStatusProvider = Provider<bool?>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.isLoading || auth.hasError) {
    return null;
  }
  final user = auth.asData?.value;
  if (user == null || user.email.trim().isEmpty) {
    return null;
  }
  return user.emailConfirmed;
});
