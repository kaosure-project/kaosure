import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../security/dashboard_menu_tile.dart';

final class NotificationsTile extends StatelessWidget {
  const NotificationsTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardMenuTile(
      icon: Icons.notifications_none_outlined,
      title: l10n.notifications,
      subtitle: l10n.notificationPreferencesDescription,
      onTap: () {
        // TODO: Navigate to Notifications
      },
    );
  }
}
