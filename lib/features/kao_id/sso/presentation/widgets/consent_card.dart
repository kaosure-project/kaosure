import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../application/states/consent_state.dart';
import '../../domain/entities/authorization_request.dart';
import '../../domain/entities/sso_app.dart';
import '../utils/sso_texts.dart';
import 'sso_app_avatar.dart';

/// What the requesting app will receive, with allow and deny.
class ConsentCard extends StatelessWidget {
  const ConsentCard({
    super.key,
    required this.request,
    required this.account,
    required this.state,
    required this.onAllow,
    required this.onDeny,
  });

  final ConsentRequest request;
  final String account;
  final ConsentState state;
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final app = request.app;
    final host = request.clientUri?.host ?? '';
    final claims = [...?app?.claims]..sort((a, b) => a.index.compareTo(b.index));
    final failure = state.failure;

    Widget spinnerOr(ConsentPhase phase, String label) => state.phase == phase
        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(label);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Image.asset('assets/images/kaosure_logo.png', height: 28, semanticLabel: 'KaoSure',
          errorBuilder: (_, _, _) => const SizedBox.shrink()),
        const SizedBox(width: 8),
        Text(l10n.kaoId, style: text.titleMedium?.copyWith(
          color: AppColors.kaoBlue, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 24),
      Center(child: SsoAppAvatar(name: request.displayName, size: 64)),
      const SizedBox(height: 16),
      Text(l10n.ssoConsentTitle(request.displayName), textAlign: TextAlign.center,
        style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
        if (app?.firstParty == true)
          _Pill(icon: Icons.verified_outlined, label: l10n.ssoFirstParty,
            color: AppColors.kaoGreen, tint: AppColors.kaoGreenSoft),
        if (host.isNotEmpty)
          _Pill(icon: Icons.language, label: host,
            color: AppColors.kaoSlate, tint: AppColors.kaoSlateSoft),
      ]),
      if (account.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(l10n.ssoConsentSignedInAs(account), textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
      ],
      const SizedBox(height: 20),
      const Divider(height: 1, color: AppColors.divider),
      const SizedBox(height: 16),
      Text(l10n.ssoConsentReceives, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      for (final scope in request.scopes)
        _PermissionRow(icon: ssoScopeIcon(scope), label: l10n.ssoScopeLabel(scope)),
      for (final SsoClaim claim in claims)
        _PermissionRow(icon: ssoClaimIcon(claim), label: l10n.ssoClaimLabel(claim)),
      const SizedBox(height: 12),
      _Notice(icon: Icons.lock_outline, message: l10n.ssoConsentNeverShared,
        color: AppColors.kaoBlue, tint: AppColors.kaoBlueSoft),
      if (!request.appAllowed) ...[
        const SizedBox(height: 12),
        _Notice(icon: Icons.block, message: l10n.ssoAppBlocked,
          color: AppColors.error, tint: AppColors.kaoDangerSoft),
      ],
      if (failure != null) ...[
        const SizedBox(height: 12),
        _Notice(icon: Icons.error_outline, message: l10n.ssoFailureMessage(failure),
          color: AppColors.error, tint: AppColors.kaoDangerSoft),
      ],
      const SizedBox(height: 20),
      Text(l10n.ssoConsentReturnTo(request.redirectUri.host.isEmpty
          ? request.redirectUri.scheme : request.redirectUri.host),
        style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton(
          key: const Key('sso-consent-deny'),
          onPressed: state.busy ? null : onDeny,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: spinnerOr(ConsentPhase.denying, l10n.ssoConsentDeny),
        )),
        const SizedBox(width: 12),
        Expanded(child: FilledButton(
          key: const Key('sso-consent-allow'),
          onPressed: state.busy || !request.appAllowed ? null : onAllow,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48),
            backgroundColor: AppColors.kaoBlue),
          child: spinnerOr(ConsentPhase.approving, l10n.ssoConsentAllow),
        )),
      ]),
      const SizedBox(height: 16),
      Text(l10n.ssoConsentManageHint, textAlign: TextAlign.center,
        style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
    ]);
  }
}

/// Centred status for loading, redirecting and errors on the consent page.
class ConsentMessage extends StatelessWidget {
  const ConsentMessage({super.key, required this.icon, required this.message,
    this.action, this.busy = false});

  final IconData icon;
  final String message;
  final Widget? action;
  final bool busy;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          busy
              ? const CircularProgressIndicator()
              : Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          if (action case final action?) ...[const SizedBox(height: 16), action],
        ]),
      );
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.kaoBlueSoft, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppColors.kaoBlue),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          )),
        ]),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message, required this.color, required this.tint});

  final IconData icon;
  final String message;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.textPrimary))),
        ]),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color, required this.tint});

  final IconData icon;
  final String label;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color, fontWeight: FontWeight.w600))),
        ]),
      );
}
