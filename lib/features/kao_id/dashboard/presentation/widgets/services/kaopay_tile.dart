import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../security/dashboard_menu_tile.dart';

final class KaoPayTile extends StatelessWidget {
  const KaoPayTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardMenuTile(
      enabled: false,
      trailing: const SizedBox.shrink(),
      icon: Icons.account_balance_wallet_outlined,
      title: l10n.kaoPay,
      subtitle: '${l10n.kaoPayDescription} · ${l10n.serviceUnavailable}',
      onTap: () {
        // TODO: Navigate to KaoPay
      },
    );
  }
}
