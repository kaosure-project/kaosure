import 'package:flutter/material.dart';

import 'dashboard_menu_tile.dart';

final class PasswordTile extends StatelessWidget {
  const PasswordTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.lock_outline,
      title: 'Password',
      subtitle: 'Change your password',
      onTap: () {
        // TODO: Navigate to Password Screen
      },
    );
  }
}