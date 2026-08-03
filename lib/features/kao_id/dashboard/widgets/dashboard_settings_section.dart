import 'package:flutter/material.dart';

import 'dashboard_menu_tile.dart';
class DashboardSettingsSection extends StatelessWidget {
  const DashboardSettingsSection({
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
              'Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          DashboardMenuTile(
            icon: Icons.settings_outlined,
            title: 'General Settings',
            subtitle: 'Language, theme and preferences',
            onTap: () {},
          ),
          DashboardMenuTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {},
          ),
          DashboardMenuTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            subtitle: 'Privacy & permissions',
            onTap: () {},
          ),
          DashboardMenuTile(
            icon: Icons.info_outline,
            title: 'About Kao ID',
            subtitle: 'Version, licenses and legal',
            showDivider: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}