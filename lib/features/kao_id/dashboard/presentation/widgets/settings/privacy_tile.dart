import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../security/dashboard_menu_tile.dart';

final class PrivacyTile extends StatelessWidget {
  const PrivacyTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardMenuTile(
      icon: Icons.privacy_tip_outlined,
      title: l10n.privacy,
      subtitle: l10n.privacyPermissionsDescription,
      onTap: () {
        // TODO: Navigate to Privacy
      },
    );
  }
}
