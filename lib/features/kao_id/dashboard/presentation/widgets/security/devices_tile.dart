import 'package:flutter/material.dart';

import 'dashboard_menu_tile.dart';

final class DevicesTile extends StatelessWidget {
  const DevicesTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.devices_outlined,
      title: 'Devices',
      subtitle: 'Manage trusted devices',
      onTap: () {
        // TODO: Navigate to Devices Screen
      },
    );
  }
}