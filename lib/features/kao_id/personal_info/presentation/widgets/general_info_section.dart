import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../shared/design_system/colors/app_colors.dart';
import '../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../application/controllers/reveal_controller.dart';
import '../../domain/entities/personal_info.dart';
import '../../domain/entities/sensitive_field.dart';
import 'info_row.dart';
import 'masked_value.dart';
import 'verified_badge.dart';

class GeneralInfoSection extends StatelessWidget {
  const GeneralInfoSection({super.key, required this.info, required this.reveal,
    required this.onReveal, required this.onHide});

  final PersonalInfo info;
  final RevealState reveal;
  final ValueChanged<SensitiveField> onReveal;
  final ValueChanged<SensitiveField> onHide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget missing() => Text(l10n.piNotProvided, style: const TextStyle(color: AppColors.textSecondary));
    Widget? badge(VerifiedValue v, {bool kyc = false}) =>
        v.isEmpty ? null : VerifiedBadge(v.mark, kyc: kyc);

    return DashboardPanel(
      title: l10n.piGeneralTitle,
      icon: Icons.person_outline,
      child: Column(children: [
        InfoRow(
          label: l10n.piFullName,
          badge: badge(info.name, kyc: true),
          child: info.name.isEmpty ? missing() : Text(info.name.value!,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        InfoRow(
          label: l10n.authEmail,
          badge: badge(info.email),
          child: info.email.isEmpty ? missing() : Text(info.email.value!),
        ),
        InfoRow(
          label: l10n.piPhone,
          badge: badge(info.phone),
          last: true,
          child: info.phone.isEmpty ? missing() : MaskedValue(
            masked: info.phone.value!,
            revealed: reveal.revealed[SensitiveField.phone],
            loading: reveal.loading.contains(SensitiveField.phone),
            onReveal: () => onReveal(SensitiveField.phone),
            onHide: () => onHide(SensitiveField.phone),
          ),
        ),
      ]),
    );
  }
}
