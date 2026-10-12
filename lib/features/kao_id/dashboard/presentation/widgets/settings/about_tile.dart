import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../security/dashboard_menu_tile.dart';

final class AboutTile extends StatelessWidget {
  const AboutTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardMenuTile(
      icon: Icons.info_outline,
      title: l10n.aboutKaoId,
      subtitle: l10n.aboutKaoIdDescription,
      showDivider: false,
      onTap: () {
        // TODO: Navigate to About
      },
    );
  }
}
