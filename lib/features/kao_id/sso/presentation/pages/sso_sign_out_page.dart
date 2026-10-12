import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../../../app/routes/kao_id_routes.dart';
import '../../../dashboard/presentation/widgets/kao_id_scaffold.dart';
import '../../../dashboard/presentation/widgets/settings/sign_out_action.dart';
import '../../application/providers/sso_providers.dart';
import '../../domain/failures/sso_failure.dart';
import '../utils/sso_texts.dart';
import '../widgets/consent_card.dart';

/// `/logout?return_to=`: signing out of a sub-app ends the Kao ID session on
/// this browser too, then the member goes back to the app, or to the Kao ID
/// home page when [returnTo] is not a page of an active registered app.
class SsoSignOutPage extends ConsumerStatefulWidget {
  const SsoSignOutPage({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<SsoSignOutPage> createState() => _SsoSignOutPageState();
}

class _SsoSignOutPageState extends ConsumerState<SsoSignOutPage> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_signOut()));
  }

  Future<void> _signOut() async {
    if (!mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final navigator = Navigator.of(context, rootNavigator: true);
    final useCases = ref.read(oauthConsentUseCasesProvider);
    final redirect = ref.read(ssoRedirectProvider);
    setState(() => _failed = false);
    final target = await useCases.signOutReturn(widget.returnTo);
    try {
      if (useCases.currentUserId() != null) await clearKaoIdSession(container);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (target != null && await redirect(target)) return;
    if (navigator.mounted) navigator.pushNamedAndRemoveUntil(KaoIdRoutes.kaoIdLanding, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.kaoPage,
      body: SafeArea(
        child: Column(
          children: [
            const BrandStripe(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _failed
                      ? ConsentMessage(
                          icon: Icons.error_outline,
                          message: l10n.ssoFailureMessage(SsoFailureCode.unknown),
                          action: OutlinedButton(onPressed: () => unawaited(_signOut()), child: Text(l10n.retry)),
                        )
                      : ConsentMessage(icon: Icons.logout, message: l10n.ssoSigningOut, busy: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
