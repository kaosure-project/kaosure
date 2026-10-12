import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../../shared/design_system/colors/app_colors.dart';
import '../../../../account/presentation/pages/lifecycle/lifecycle_page.dart';
import '../../../../governance/presentation/widgets/governance_dashboard_tile.dart';
import '../section/menu_panel.dart';
import '../section/section_body.dart';
import '../security/dashboard_menu_tile.dart';
import 'general_settings_tile.dart';
import 'sign_out_tile.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SectionBody(
      icon: Icons.tune,
      color: AppColors.kaoSlate,
      tint: AppColors.kaoSlateSoft,
      title: l10n.settings,
      description: l10n.settingsHubDescription,
      start: [
        MenuPanel(title: l10n.setGeneralTitle, children: const [GeneralSettingsTile()]),
        MenuPanel(title: l10n.signOut, children: const [SignOutTile()]),
      ],
      end: [
        MenuPanel(title: l10n.setAccountTitle, children: [
          const GovernanceDashboardTile(),
          DashboardMenuTile(
            icon: Icons.manage_accounts_outlined,
            title: l10n.lifeTitle,
            subtitle: l10n.setLifecycleDescription,
            color: AppColors.kaoSlate,
            tint: AppColors.kaoSlateSoft,
            showDivider: false,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const LifecyclePage())),
          ),
        ]),
      ],
    );
  }
}
