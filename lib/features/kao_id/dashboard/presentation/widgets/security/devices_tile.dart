import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'dashboard_menu_tile.dart';

final class DevicesTile extends StatelessWidget {
  const DevicesTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardMenuTile(
      icon: Icons.devices_outlined,
      title: l10n.devices,
      subtitle: l10n.trustedDevicesDescription,
      onTap: () {
        // TODO: Navigate to Devices Screen
      },
    );
  }
}
