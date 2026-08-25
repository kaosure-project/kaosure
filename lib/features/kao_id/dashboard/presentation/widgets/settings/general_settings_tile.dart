import 'package:flutter/material.dart';

import '../security/dashboard_menu_tile.dart';

final class GeneralSettingsTile extends StatelessWidget {
  const GeneralSettingsTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.settings_outlined,
      title: 'General Settings',
      subtitle: 'Language, theme and preferences',
      onTap: () {
        // TODO: Navigate to General Settings
      },
    );
  }
}