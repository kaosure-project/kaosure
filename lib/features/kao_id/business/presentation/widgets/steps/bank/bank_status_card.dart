import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../domain/entities/payout_bank_account.dart';

class BankStatusCard extends StatelessWidget {
  const BankStatusCard({super.key, required this.bank});

  final PayoutBankAccount bank;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (label, icon, color) = switch (bank.status) {
      PayoutBankStatus.approved => (l10n.businessRegBankApproved, Icons.verified, scheme.primary),
      PayoutBankStatus.pending => (l10n.businessRegBankPending, Icons.schedule, scheme.tertiary),
      PayoutBankStatus.rejected => (l10n.businessRegBankRejected, Icons.error_outline, scheme.error),
      PayoutBankStatus.missing => (l10n.businessRegBankMissing, Icons.account_balance_outlined,
          scheme.onSurfaceVariant),
    };
    final hasAccount = bank.status != PayoutBankStatus.missing;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bank.isApproved ? scheme.primary : scheme.outlineVariant),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: scheme.surfaceContainerHighest,
          child: Icon(Icons.account_balance, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAccount) ...[
              Text(bank.bankName ?? '', style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(bank.maskedNumber ?? '', style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()], letterSpacing: 1)),
              const SizedBox(height: 8),
            ],
            Semantics(liveRegion: true, child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: color))),
            ])),
          ],
        )),
      ]),
    );
  }
}
