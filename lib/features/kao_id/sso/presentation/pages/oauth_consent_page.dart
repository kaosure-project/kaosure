import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../../../app/routes/kao_id_routes.dart';
import '../../../auth/application/kao_id_sso_handoff.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/kao_id_scaffold.dart';
import '../../application/providers/sso_providers.dart';
import '../../application/states/consent_state.dart';
import '../../domain/entities/authorization_request.dart';
import '../../domain/failures/sso_failure.dart';
import '../utils/sso_texts.dart';
import '../widgets/consent_card.dart';

/// Where Supabase Auth's OAuth server sends a member to approve a sub-app.
class OAuthConsentPage extends ConsumerStatefulWidget {
  const OAuthConsentPage({super.key, required this.authorizationId});

  final String authorizationId;

  @override
  ConsumerState<OAuthConsentPage> createState() => _OAuthConsentPageState();
}

class _OAuthConsentPageState extends ConsumerState<OAuthConsentPage> {
  @override
  void initState() {
    super.initState();
    // The request is on screen now; a stale copy must not reopen after a later login.
    unawaited(KaoIdSsoHandoff.takePendingConsent());
  }

  void _goToKaoId() => Navigator.of(context)
      .pushNamedAndRemoveUntil(KaoIdRoutes.dashboard, (_) => false);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.authorizationId;
    final request = ref.watch(authorizationRequestProvider(id));
    final consent = ref.watch(consentControllerProvider(id));
    final controller = ref.read(consentControllerProvider(id).notifier);
    ref.listen(authorizationRequestProvider(id), (_, next) {
      if (next.valueOrNull case final ConsentAlreadyGiven given) {
        unawaited(controller.continueApproved(given));
      }
    });

    Widget message(SsoFailureCode code) => ConsentMessage(
          icon: Icons.lock_outline,
          message: l10n.ssoFailureMessage(code),
          action: OutlinedButton(onPressed: _goToKaoId, child: Text(l10n.ssoBackToKaoId)),
        );

    final Widget body = consent.phase == ConsentPhase.redirecting
        ? ConsentMessage(icon: Icons.open_in_new, message: l10n.ssoConsentRedirecting, busy: true)
        : request.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => message(ssoFailureCodeOf(error)),
            data: (value) => switch (value) {
              ConsentAlreadyGiven() => consent.failure == null
                  ? ConsentMessage(icon: Icons.open_in_new, message: l10n.ssoConsentRedirecting, busy: true)
                  : message(consent.failure!),
              ConsentRequest() => ConsentCard(
                  request: value,
                  account: ref.watch(authProvider.select((s) => s.asData?.value?.email)) ?? '',
                  state: consent,
                  onAllow: () => controller.approve(value),
                  onDeny: () => controller.deny(value),
                ),
            },
          );

    return Scaffold(
      backgroundColor: AppColors.kaoPage,
      body: SafeArea(
        child: Column(children: [
          const BrandStripe(),
          Expanded(child: Center(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                elevation: 1,
                shadowColor: const Color(0x14000000),
                child: Padding(padding: const EdgeInsets.all(28), child: body),
              ),
            ),
          ))),
        ]),
      ),
    );
  }
}
