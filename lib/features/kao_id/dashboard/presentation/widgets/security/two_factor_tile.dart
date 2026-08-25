import 'package:flutter/material.dart';

import 'dashboard_menu_tile.dart';

final class TwoFactorTile extends StatelessWidget {
  const TwoFactorTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.security_outlined,
      title: 'Two-Factor Authentication',
      subtitle: 'Protect your account',
      showDivider: false,
      onTap: () {
        // TODO: Navigate to Two-Factor Screen
      },
    );
  }
}