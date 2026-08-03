import 'package:flutter/material.dart';

import 'dashboard_menu_tile.dart';
class DashboardSecuritySection extends StatelessWidget {
  const DashboardSecuritySection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Security',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          DashboardMenuTile(
            icon: Icons.lock_outline,
            title: 'Password',
            subtitle: 'Change your password',
            onTap: () {},
          ),
          DashboardMenuTile(
            icon: Icons.devices_outlined,
            title: 'Devices',
            subtitle: 'Manage trusted devices',
            onTap: () {},
          ),
          DashboardMenuTile(
            icon: Icons.history,
            title: 'Login History',
            subtitle: 'Recent sign-in activity',
            onTap: () {},
          ),
          DashboardMenuTile(
            icon: Icons.security_outlined,
            title: 'Two-Factor Authentication',
            subtitle: 'Protect your account',
            showDivider: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}