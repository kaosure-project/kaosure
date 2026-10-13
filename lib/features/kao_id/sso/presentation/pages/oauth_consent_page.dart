import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../../../app/routes/kao_id_routes.dart';
import '../../../auth/application/kao_id_sso_handoff.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/kao_id_scaffold.dart';
import '../../../dashboard/presentation/widgets/settings/sign_out_action.dart';
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
  late final Future<bool> _openedFromKaoId;
  var _launchHandled = false;

  @override
  void initState() {
    super.initState();
    // The request is on screen now; a stale copy must not reopen after a later login.
    unawaited(KaoIdSsoHandoff.takePendingConsent());
    _openedFromKaoId = ref.read(serviceLaunchCheckProvider)(ref.read(oauthConsentUseCasesProvider).currentUserId());
    ref.listenManual(authorizationRequestProvider(widget.authorizationId), (_, next) {
      if (next.asData?.value case final ConsentAlreadyGiven request) unawaited(_continueLaunch(request));
    }, fireImmediately: true);
  }

  /// The member pressed "Open" in Kao ID as this same account moments ago, so
  /// the account was already chosen.
  Future<void> _continueLaunch(ConsentAlreadyGiven request) async {
    if (_launchHandled) return;
    _launchHandled = true;
    if (!await _openedFromKaoId || !mounted) return;
    unawaited(ref.read(consentControllerProvider(widget.authorizationId).notifier).continueApproved(request));
  }

  void _goToKaoId() => Navigator.of(context).pushNamedAndRemoveUntil(KaoIdRoutes.dashboard, (_) => false);

  void _switchAccount(AuthorizationRequest request) {
    final container = ProviderScope.containerOf(context, listen: false);
    unawaited(
      ref
          .read(consentControllerProvider(widget.authorizationId).notifier)
          .switchAccount(request, signOut: () => clearKaoIdSession(container)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.authorizationId;
    final request = ref.watch(authorizationRequestProvider(id));
    final consent = ref.watch(consentControllerProvider(id));
    final controller = ref.read(consentControllerProvider(id).notifier);
    final account = ref.watch(authProvider.select((s) => s.asData?.value?.email)) ?? '';

    Widget message(SsoFailureCode code) => ConsentMessage(
      icon: Icons.lock_outline,
      message: l10n.ssoFailureMessage(code),
      action: OutlinedButton(onPressed: _goToKaoId, child: Text(l10n.ssoBackToKaoId)),
    );

    final Widget body = switch (consent.phase) {
      ConsentPhase.redirecting => ConsentMessage(
        icon: Icons.open_in_new,
        message: l10n.ssoConsentRedirecting,
        busy: true,
      ),
      ConsentPhase.switching => ConsentMessage(icon: Icons.logout, message: l10n.ssoSigningOut, busy: true),
      _ => request.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => message(ssoFailureCodeOf(error)),
        data: (value) => switch (value) {
          ConsentAlreadyGiven() => ConsentAccountChooser(
            account: account,
            state: consent,
            onContinue: () => controller.continueApproved(value),
            onSwitchAccount: () => _switchAccount(value),
          ),
          ConsentRequest() => ConsentCard(
            request: value,
            account: account,
            state: consent,
            onAllow: () => controller.approve(value),
            onDeny: () => controller.deny(value),
            onSwitchAccount: () => _switchAccount(value),
          ),
        },
      ),
    };

    return Scaffold(
      backgroundColor: AppColors.kaoPage,
      body: SafeArea(
        child: Column(
          children: [
            const BrandStripe(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
