import 'package:flutter/material.dart';

import '../security/dashboard_menu_tile.dart';

final class NotificationsTile extends StatelessWidget {
  const NotificationsTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.notifications_none_outlined,
      title: 'Notifications',
      subtitle: 'Manage notification preferences',
      onTap: () {
        // TODO: Navigate to Notifications
      },
    );
  }
}