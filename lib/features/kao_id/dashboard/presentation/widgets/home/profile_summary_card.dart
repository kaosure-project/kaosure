import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../../shared/design_system/colors/app_colors.dart';
import '../../../../account/domain/entities/profile.dart';
import '../../../../issuance/application/providers/kao_id_issuance_provider.dart';
import '../profile/profile_status_chip.dart';
import 'dashboard_panel.dart';

class ProfileSummaryCard extends ConsumerWidget {
  const ProfileSummaryCard({super.key, required this.profile, required this.onOpen});

  final Profile profile;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final name = (profile.displayName ?? '').trim();
    final avatar = profile.avatarUrl;
    final identity = ref.watch(currentKaoIdIdentityProvider).asData;
    const placeholder = CircleAvatar(
      radius: 32,
      backgroundColor: AppColors.kaoBlueSoft,
      foregroundColor: AppColors.kaoBlue,
      child: Icon(Icons.person_outline, size: 32),
    );
    return DashboardPanel(
      onTap: onOpen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          avatar != null && avatar.isNotEmpty
              ? ClipOval(child: Image.network(avatar, width: 64, height: 64, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder))
              : placeholder,
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.dashDisplayNameLabel,
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
            Text(name.isEmpty ? l10n.kaoIdUser : name,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ProfileStatusChip(profile: profile),
                if (identity != null)
                  identity.value?.isActive == true
                      ? Text(l10n.dashKaoIdLine(identity.value!.kaoId),
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.kaoBlue, fontWeight: FontWeight.w600))
                      : Text(l10n.dashKaoIdPending,
                          style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ]),
        const SizedBox(height: 16),
        Text(l10n.personalDetailsDescription,
          style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}
