import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../shared/design_system/colors/app_colors.dart';
import '../../domain/entities/personal_info.dart';

/// Pill showing how a value was verified; [kyc] marks values proven by an identity document.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge(this.mark, {super.key, this.kyc = false});

  final VerificationMark mark;
  final bool kyc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const pending = Color(0xFFB26A00);
    final (Color fg, Color bg, IconData icon, String label) = switch (mark) {
      VerificationMark.verified => (AppColors.kaoGreen, AppColors.kaoGreenSoft, Icons.verified,
          kyc ? l10n.piBadgeKycVerified : l10n.piBadgeVerified),
      VerificationMark.pending => (pending, const Color(0xFFFFF4E0), Icons.schedule, l10n.piBadgePending),
      VerificationMark.expired => (AppColors.error, AppColors.kaoDangerSoft, Icons.event_busy, l10n.piBadgeExpired),
      VerificationMark.rejected => (AppColors.error, AppColors.kaoDangerSoft, Icons.error_outline, l10n.piBadgeRejected),
      VerificationMark.revoked => (AppColors.error, AppColors.kaoDangerSoft, Icons.block, l10n.piBadgeRevoked),
      VerificationMark.unverified || VerificationMark.none =>
        (AppColors.textSecondary, AppColors.kaoSlateSoft, Icons.info_outline, l10n.piBadgeUnverified),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
