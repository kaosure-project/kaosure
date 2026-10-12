import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../shared/design_system/colors/app_colors.dart';
import '../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../../kyc/presentation/pages/review/kyc_review_page.dart' show reviewTypeLabel;
import '../../application/controllers/reveal_controller.dart';
import '../../domain/entities/personal_info.dart';
import '../../domain/entities/sensitive_field.dart';
import 'info_row.dart';
import 'masked_value.dart';
import 'verified_badge.dart';

class IdentityDocumentSection extends StatelessWidget {
  const IdentityDocumentSection({super.key, required this.document, required this.reveal,
    required this.onReveal, required this.onHide, required this.onVerify});

  final IdentityDocumentSummary? document;
  final RevealState reveal;
  final ValueChanged<SensitiveField> onReveal;
  final ValueChanged<SensitiveField> onHide;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final doc = document;
    if (doc == null) {
      return DashboardPanel(
        title: l10n.secDocumentsTitle,
        icon: Icons.badge_outlined,
        iconColor: AppColors.kaoTeal,
        child: _EmptyState(message: l10n.piNoDocument, action: l10n.identityVerification, onAction: onVerify),
      );
    }
    String date(DateTime value) => DateFormat.yMMMd(l10n.localeName).format(value);
    final number = doc.maskedNumber;
    return DashboardPanel(
      title: l10n.secDocumentsTitle,
      icon: Icons.badge_outlined,
      iconColor: AppColors.kaoTeal,
      child: Column(children: [
        InfoRow(
          label: l10n.piDocumentType,
          badge: VerifiedBadge(doc.mark, kyc: true),
          child: Text(reviewTypeLabel(l10n, doc.type)),
        ),
        InfoRow(
          label: l10n.piDocumentNumber,
          child: number == null ? Text(l10n.piNotProvided) : MaskedValue(
            masked: number,
            revealed: reveal.revealed[SensitiveField.idNumber],
            loading: reveal.loading.contains(SensitiveField.idNumber),
            onReveal: () => onReveal(SensitiveField.idNumber),
            onHide: () => onHide(SensitiveField.idNumber),
          ),
        ),
        if (doc.issuedDate case final issued?)
          InfoRow(label: l10n.kycIssueDate, child: Text(date(issued))),
        InfoRow(
          label: l10n.kycExpiryDate,
          last: true,
          child: Text(switch (doc.expiryDate) {
            final expiry? => date(expiry),
            null => l10n.piNoExpiry,
          }),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.action, required this.onAction});

  final String message;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.badge_outlined, size: 18),
          label: Text(action),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.kaoTeal,
            side: const BorderSide(color: AppColors.kaoTeal),
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]);
}
