import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../account/application/providers/profile_controller_provider.dart';
import '../../../../auth/application/providers/auth_provider.dart';
import '../../../../auth/application/providers/password_recovery_provider.dart';
import '../../../../business/application/providers/business_registration_provider.dart';
import '../../../../devices/application/providers/device_controller_provider.dart';
import '../../../../governance/application/providers/governance_provider.dart';
import '../../../../identity/presentation/providers/identity_controller_provider.dart';
import '../../../../issuance/application/providers/kao_id_issuance_provider.dart';
import '../../../../kyc/application/providers/kyc_provider.dart';
import '../../../../phone_verification/application/providers/phone_verification_provider.dart';
import '../../../../../../app/routes/kao_id_routes.dart';
import '../../../../sessions/application/providers/session_controller_provider.dart';
import '../../../application/providers/dashboard_provider.dart';

Future<bool> confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.signOut),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

/// Signs out, clears account state and returns to the Kao ID landing page.
/// Throws when sign-out fails.
Future<void> signOutAndLeave(BuildContext context) async {
  // AuthGuard may remove the caller when logout completes. Keep the root
  // navigator and container so cleanup does not depend on a disposed WidgetRef.
  final navigator = Navigator.of(context, rootNavigator: true);
  final container = ProviderScope.containerOf(context, listen: false);
  await container.read(authProvider.notifier).logout();
  container.read(passwordRecoveryAuthorizedProvider.notifier).state = false;
  container.invalidate(profileControllerProvider);
  container.invalidate(dashboardControllerProvider);
  container.invalidate(kycControllerProvider);
  container.invalidate(identityControllerProvider);
  container.invalidate(phoneVerificationControllerProvider);
  container.invalidate(deviceControllerProvider);
  container.invalidate(sessionControllerProvider);
  container.invalidate(governanceAccessProvider);
  container.invalidate(governanceControllerProvider);
  container.invalidate(currentKaoIdIdentityProvider);
  container.invalidate(businessRegistrationControllerProvider);
  if (navigator.mounted) {
    navigator.pushNamedAndRemoveUntil(KaoIdRoutes.kaoIdLanding, (_) => false);
  }
}
