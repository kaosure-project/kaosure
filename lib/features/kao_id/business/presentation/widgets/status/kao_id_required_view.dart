import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

/// Shown instead of the form until the applicant holds an active personal Kao ID.
class KaoIdRequiredView extends StatelessWidget {
  const KaoIdRequiredView({super.key, required this.checking, required this.onVerify, required this.onCheckAgain});

  final bool checking;
  final VoidCallback onVerify;
  final VoidCallback onCheckAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Icon(Icons.badge_outlined, size: 56, color: scheme.primary),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            l10n.businessRegKaoIdRequiredTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.businessRegKaoIdRequiredBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: checking ? null : onVerify,
          icon: const Icon(Icons.verified_user_outlined),
          label: Text(l10n.businessRegKaoIdVerifyAction),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: checking ? null : onCheckAgain,
          icon: checking
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh),
          label: Text(l10n.businessRegKaoIdCheckAgain),
        ),
      ],
    );
  }
}
