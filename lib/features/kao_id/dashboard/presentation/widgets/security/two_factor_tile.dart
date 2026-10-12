import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'dashboard_menu_tile.dart';

final class TwoFactorTile extends StatelessWidget {
  const TwoFactorTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardMenuTile(
      icon: Icons.security_outlined,
      title: l10n.twoFactorAuthentication,
      subtitle: l10n.twoFactorDescription,
      showDivider: false,
      onTap: () {
        // TODO: Navigate to Two-Factor Screen
      },
    );
  }
}
