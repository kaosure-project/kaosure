import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../../shared/design_system/colors/app_colors.dart';
import '../../../../account/presentation/pages/security/mfa_page.dart';
import '../../../../account/presentation/pages/security/sessions_page.dart';
import '../../../../kyc/presentation/pages/document_health_page.dart';
import '../../../../sso/presentation/pages/connected_apps_page.dart';
import '../section/menu_panel.dart';
import '../section/section_body.dart';
import 'dashboard_menu_tile.dart';
import 'password_tile.dart';

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

    return SectionBody(
      icon: Icons.lock_outline,
      color: AppColors.kaoGreen,
      tint: AppColors.kaoGreenSoft,
      title: l10n.dashSecurityTitle,
      description: l10n.dashSecurityDescription,
      start: [
        MenuPanel(title: l10n.secSignInTitle, children: [
          const PasswordTile(),
          DashboardMenuTile(
            icon: Icons.security,
            title: l10n.twoFactorAuthentication,
            subtitle: l10n.twoFactorDescription,
            color: AppColors.kaoGreen,
            tint: AppColors.kaoGreenSoft,
            showDivider: false,
            onTap: () => open(const MfaPage()),
          ),
        ]),
      ],
      end: [
        MenuPanel(title: l10n.secDevicesTitle, children: [
          DashboardMenuTile(
            icon: Icons.devices_outlined,
            title: l10n.sessionTitle,
            subtitle: l10n.accountSessionsDescription,
            onTap: () => open(const SessionsPage()),
          ),
          DashboardMenuTile(
            icon: Icons.apps_outlined,
            title: l10n.ssoConnectedAppsTitle,
            subtitle: l10n.ssoConnectedAppsDescription,
            color: AppColors.kaoGreen,
            tint: AppColors.kaoGreenSoft,
            showDivider: false,
            onTap: () => open(const ConnectedAppsPage()),
          ),
        ]),
        MenuPanel(title: l10n.secDocumentsTitle, children: [
          DashboardMenuTile(
            icon: Icons.badge_outlined,
            title: l10n.documentHealthTitle,
            subtitle: l10n.secDocumentHealthDescription,
            color: AppColors.kaoTeal,
            tint: AppColors.kaoTealSoft,
            showDivider: false,
            onTap: () => open(const DocumentHealthPage()),
          ),
        ]),
      ],
    );
  }
}
