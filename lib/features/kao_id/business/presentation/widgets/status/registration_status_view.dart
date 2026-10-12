import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../domain/entities/business_registration.dart';

class RegistrationStatusView extends StatelessWidget {
  const RegistrationStatusView({
    super.key,
    required this.registration,
    required this.refreshing,
    required this.onRefresh,
    required this.onStartNew,
    required this.onDone,
  });

  final BusinessRegistration registration;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onStartNew;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, color, title, body) = switch (registration.status) {
      BusinessRegistrationStatus.approved => (Icons.verified, scheme.primary,
          l10n.businessRegStatusApprovedTitle, l10n.businessRegStatusApprovedBody),
      BusinessRegistrationStatus.rejected => (Icons.cancel_outlined, scheme.error,
          l10n.businessRegStatusRejectedTitle, l10n.businessRegStatusRejectedBody),
      BusinessRegistrationStatus.requiresAction => (Icons.report_outlined, scheme.tertiary,
          l10n.businessRegStatusActionTitle, l10n.businessRegStatusActionBody),
      _ => (Icons.hourglass_top, scheme.primary,
          l10n.businessRegStatusReviewTitle, l10n.businessRegStatusReviewBody),
    };
    final pending = !registration.isApproved && !registration.isRejected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Icon(icon, size: 56, color: color),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(title, textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Text(registration.businessName, textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall),
        if (registration.isRejected && (registration.reviewReason?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.businessRegStatusReasonLabel,
                    style: theme.textTheme.labelLarge?.copyWith(color: scheme.onErrorContainer)),
                const SizedBox(height: 4),
                SelectableText(registration.reviewReason!.trim(),
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        if (registration.isRejected)
          FilledButton(onPressed: onStartNew, child: Text(l10n.businessRegStartNew))
        else if (pending)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: refreshing ? null : onRefresh,
            icon: refreshing
                ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            label: Text(l10n.businessRegRefreshStatus),
          ),
        const SizedBox(height: 12),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: onDone,
          child: Text(l10n.businessRegBackToAccount),
        ),
      ],
    );
  }
}
