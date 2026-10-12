import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../shared/design_system/colors/app_colors.dart';
import '../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../domain/entities/personal_info.dart';
import 'verified_badge.dart';

class IdAddressCard extends StatelessWidget {
  const IdAddressCard({super.key, required this.address, required this.onVerify});

  final IdAddress? address;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final value = address;
    if (value == null) {
      return DashboardPanel(
        title: l10n.piAddressTitle,
        icon: Icons.home_outlined,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.piNoAddress, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onVerify,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(l10n.identityVerification),
          ),
        ]),
      );
    }

    final parts = <(String, String?)>[
      (l10n.piSubdistrict, value.subdistrict),
      (l10n.piDistrict, value.district),
      (l10n.piProvince, value.province),
      (l10n.piPostalCode, value.postalCode),
    ].where((p) => p.$2 != null);

    return DashboardPanel(
      title: l10n.piAddressTitle,
      icon: Icons.home_outlined,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kaoBlueSoft.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.kaoBlueSoft),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.location_on_outlined, color: AppColors.kaoBlue),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 12, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(l10n.piAddressLine, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
              VerifiedBadge(value.mark, kyc: true),
            ]),
            const SizedBox(height: 4),
            SelectableText(value.line, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Wrap(spacing: 24, runSpacing: 12, children: [
              for (final (label, part) in parts)
                SizedBox(
                  width: 150,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    SelectableText(part!, style: text.bodyLarge?.copyWith(color: AppColors.textPrimary)),
                  ]),
                ),
            ]),
          ])),
        ]),
      ),
    );
  }
}
