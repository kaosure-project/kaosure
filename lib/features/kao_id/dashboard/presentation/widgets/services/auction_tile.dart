import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../security/dashboard_menu_tile.dart';

final class AuctionTile extends StatelessWidget {
  const AuctionTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardMenuTile(
      enabled: false,
      trailing: const SizedBox.shrink(),
      icon: Icons.gavel_outlined,
      title: l10n.auction,
      subtitle: '${l10n.auctionDescription} · ${l10n.serviceUnavailable}',
      onTap: () {
        // TODO: Navigate to Auction
      },
    );
  }
}
