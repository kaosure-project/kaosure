import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../security/dashboard_menu_tile.dart';

final class MoreServicesTile extends StatelessWidget {
  const MoreServicesTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardMenuTile(
      enabled: false,
      trailing: const SizedBox.shrink(),
      icon: Icons.apps_outlined,
      title: l10n.moreServices,
      subtitle: '${l10n.moreServicesDescription} · ${l10n.serviceUnavailable}',
      showDivider: false,
      onTap: () {
        // TODO: Navigate to All Services
      },
    );
  }
}
