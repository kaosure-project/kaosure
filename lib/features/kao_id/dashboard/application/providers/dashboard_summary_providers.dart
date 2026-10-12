import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/env.dart';
import '../../../auth/application/kao_id_sso_handoff.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../business/application/providers/business_registration_provider.dart';
import '../../../business/domain/entities/business_registration.dart';
import '../../../business/domain/entities/payout_bank_account.dart';
import '../../../governance/application/providers/member_access_provider.dart';
import '../../../kyc/application/providers/kyc_review_providers.dart';

/// True when the account may open the admin hub as a member admin or reviewer.
final dashboardAdminAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  Future<bool> granted(Future<bool> access) async {
    try {
      return await access;
    } catch (_) {
      return false;
    }
  }

  final results = await Future.wait([
    granted(ref.watch(memberAccessProvider.future)),
    granted(ref.watch(kycReviewerAccessProvider.future)),
  ]);
  return results.contains(true);
});

final dashboardBankProvider = FutureProvider.autoDispose<PayoutBankAccount>((ref) {
  ref.watch(authProvider.select((s) => s.asData?.value?.id));
  return ref.watch(payoutBankReaderProvider)();
});

final dashboardBusinessProvider =
    FutureProvider.autoDispose<BusinessRegistration?>((ref) async {
  final userId = ref.watch(authProvider.select((s) => s.asData?.value?.id));
  if (userId == null) return null;
  return ref.watch(businessRegistrationUseCasesProvider).getCurrent(userId);
});

typedef ServiceLauncher = Future<bool> Function(Uri target);

/// Service apps share the Kao ID origin, so they open in the same tab to reuse
/// the session.
final serviceLauncherProvider = Provider<ServiceLauncher>(
  (ref) => (target) => launchUrl(target, webOnlyWindowName: '_self'),
);

/// Secondhand entry point, or null when the deployment does not allow it.
final secondhandEntryProvider = Provider<Uri?>((ref) {
  final appUrl = Env.appUrl.trim();
  if (appUrl.isEmpty) return null;
  final base = appUrl.endsWith('/') ? appUrl.substring(0, appUrl.length - 1) : appUrl;
  return KaoIdSsoHandoff.validateReturnTo(
    rawReturnTo: '$base/secondhand/',
    appUrl: appUrl,
    allowedServicePaths: Env.kaoIdAllowedServicePaths,
  );
});
