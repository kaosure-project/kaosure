import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../security/dashboard_menu_tile.dart';

final class MarketplaceTile extends StatelessWidget {
  const MarketplaceTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardMenuTile(
      enabled: false,
      trailing: const SizedBox.shrink(),
      icon: Icons.storefront_outlined,
      title: l10n.marketplace,
      subtitle: '${l10n.marketplaceDescription} · ${l10n.serviceUnavailable}',
      onTap: () {
        // TODO: Navigate to Marketplace
      },
    );
  }
}
