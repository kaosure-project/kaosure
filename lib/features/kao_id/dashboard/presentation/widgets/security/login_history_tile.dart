import 'package:flutter/material.dart';

import 'dashboard_menu_tile.dart';

final class LoginHistoryTile extends StatelessWidget {
  const LoginHistoryTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.history,
      title: 'Login History',
      subtitle: 'Recent sign-in activity',
      onTap: () {
        // TODO: Navigate to Login History Screen
      },
    );
  }
}