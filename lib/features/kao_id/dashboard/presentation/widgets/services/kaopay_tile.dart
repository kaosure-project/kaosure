import 'package:flutter/material.dart';

import '../security/dashboard_menu_tile.dart';

final class KaoPayTile extends StatelessWidget {
  const KaoPayTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.account_balance_wallet_outlined,
      title: 'KaoPay',
      subtitle: 'กระเป๋าเงินดิจิทัล',
      onTap: () {
        // TODO: Navigate to KaoPay
      },
    );
  }
}
