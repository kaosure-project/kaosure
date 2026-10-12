import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/features/wallet/presentation/pages/wallet_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../../shared/design_system/colors/app_colors.dart';
import '../../../../business/domain/entities/payout_bank_account.dart';
import '../../../../kyc/presentation/bank/bank_verification_page.dart';
import '../../../application/providers/dashboard_summary_providers.dart';
import 'dashboard_panel.dart';
import 'status_row.dart';

class FinancePanel extends ConsumerWidget {
  const FinancePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bank = ref.watch(dashboardBankProvider);
    final bankStatus = bank.when(
      loading: () => const SizedBox(width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, _) => StatusLabel(l10n.dashLoadFailedShort, tone: StatusTone.negative),
      data: (account) => switch (account.status) {
        PayoutBankStatus.approved => StatusLabel(l10n.kycVerifiedLabel, tone: StatusTone.positive),
        PayoutBankStatus.pending => StatusLabel(l10n.kycUnderReview, tone: StatusTone.pending),
        PayoutBankStatus.rejected => StatusLabel(l10n.kycNotVerified, tone: StatusTone.negative),
        PayoutBankStatus.missing => StatusLabel(l10n.dashNotAdded, tone: StatusTone.neutral),
      },
    );
    return DashboardPanel(
      title: l10n.dashFinanceTitle,
      icon: Icons.savings_outlined,
      iconColor: AppColors.kaoGreen,
      child: Column(children: [
        StatusRow(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.kaoGreen,
          title: l10n.walletTitle,
          actionLabel: l10n.dashDetails,
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const WalletPage())),
        ),
        const Divider(height: 1, color: AppColors.divider),
        StatusRow(
          icon: Icons.account_balance_outlined,
          iconColor: AppColors.kaoGreen,
          title: l10n.bankAccounts,
          subtitle: l10n.bankAccountsDescription,
          status: bankStatus,
          actionLabel: l10n.dashDetails,
          onAction: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BankVerificationPage()));
            if (context.mounted) ref.invalidate(dashboardBankProvider);
          },
        ),
      ]),
    );
  }
}
