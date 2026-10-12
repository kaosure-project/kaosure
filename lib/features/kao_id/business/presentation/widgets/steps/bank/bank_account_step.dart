import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../domain/entities/payout_bank_account.dart';
import '../../common/step_actions.dart';
import '../../common/step_header.dart';
import 'bank_status_card.dart';

class BankAccountStep extends StatelessWidget {
  const BankAccountStep({
    super.key,
    required this.bank,
    required this.checking,
    required this.onVerify,
    required this.onCheckAgain,
    required this.onBack,
    required this.onContinue,
  });

  final PayoutBankAccount? bank;
  final bool checking;
  final VoidCallback onVerify;
  final VoidCallback onCheckAgain;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final account = bank ?? PayoutBankAccount.none;
    final canVerify = account.status == PayoutBankStatus.missing ||
        account.status == PayoutBankStatus.rejected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeader(title: l10n.businessRegBankHeading,
            description: l10n.businessRegBankDescription),
        BankStatusCard(bank: account),
        if (!account.isApproved) ...[
          const SizedBox(height: 12),
          Text(l10n.businessRegBankRequiredHelp, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 8, children: [
            if (canVerify)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: checking ? null : onVerify,
                icon: const Icon(Icons.add_card_outlined),
                label: Text(l10n.businessRegBankVerifyAction),
              ),
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: checking ? null : onCheckAgain,
              icon: checking
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              label: Text(l10n.businessRegBankCheckAgain),
            ),
          ]),
        ],
        StepActions(
          primaryLabel: l10n.businessRegContinue,
          onPrimary: account.isApproved ? onContinue : null,
          onBack: onBack,
        ),
      ],
    );
  }
}
