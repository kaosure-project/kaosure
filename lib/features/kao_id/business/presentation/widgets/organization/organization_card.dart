import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../domain/entities/business_organization.dart';
import '../../../domain/entities/payout_bank_account.dart';
import '../../utils/business_organization_texts.dart';
import '../steps/bank/bank_status_card.dart';
import '../steps/review/review_section.dart';

/// One company: legal identity, business Kao ID and its bank accounts.
class OrganizationCard extends StatelessWidget {
  const OrganizationCard({super.key, required this.organization, required this.busy, required this.onAddBank});

  final BusinessOrganization organization;
  final bool busy;

  /// Null hides the action (no permission, no business Kao ID, or a review is pending).
  final VoidCallback? onAddBank;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final org = organization;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.business, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.legalName ?? org.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    l10n.businessOrgRoleLabel(org.role),
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        ReviewSection(
          title: l10n.businessOrgIdentityTitle,
          rows: [
            (l10n.businessOrgBusinessKaoId, org.hasBusinessKaoId ? org.businessKaoId! : l10n.businessOrgKaoIdPending),
            if (org.legalNameEn != null) (l10n.businessRegNameEnLabel, org.legalNameEn!),
            if (org.registrationNumber != null) (l10n.businessRegNumberLabel, org.registrationNumber!),
            if (org.shopName != null) (l10n.businessOrgShop, org.shopName!),
          ],
        ),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Text(l10n.businessOrgBankTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (org.banks.isEmpty)
          const BankStatusCard(bank: PayoutBankAccount.none)
        else
          for (final bank in org.banks) ...[
            BankStatusCard(
              bank: PayoutBankAccount(
                status: switch (bank.status) {
                  OrganizationBankStatus.approved => PayoutBankStatus.approved,
                  OrganizationBankStatus.pending => PayoutBankStatus.pending,
                  OrganizationBankStatus.rejected => PayoutBankStatus.rejected,
                },
                bankName: '${bank.bankName} · ${bank.accountName}',
                maskedNumber: '•••• ${bank.last4}',
              ),
            ),
            if (bank.status == OrganizationBankStatus.rejected && bank.reason != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SelectableText(bank.reason!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
              ),
            const SizedBox(height: 8),
          ],
        if (org.hasPendingBank)
          Text(l10n.bankPendingHelp, style: theme.textTheme.bodySmall)
        else if (!org.hasBusinessKaoId)
          Text(l10n.businessOrgErrorBusinessKaoId, style: theme.textTheme.bodySmall)
        else if (!org.canManageBank)
          Text(l10n.businessOrgErrorRole, style: theme.textTheme.bodySmall),
        if (onAddBank != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            key: ValueKey('org-add-bank-${org.organizationId}'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: busy ? null : onAddBank,
            icon: const Icon(Icons.add_card_outlined),
            label: Text(org.bankVerified ? l10n.businessOrgBankReplace : l10n.businessOrgBankAdd),
          ),
        ],
      ],
    );
  }
}
