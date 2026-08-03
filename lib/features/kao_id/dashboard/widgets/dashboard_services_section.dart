import 'package:flutter/material.dart';

import 'dashboard_menu_tile.dart';
class DashboardServicesSection extends StatelessWidget {
  const DashboardServicesSection({
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
              'Services',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          DashboardMenuTile(
            icon: Icons.storefront_outlined,
            title: 'KaoSure Marketplace',
            subtitle: 'Buy & sell with confidence',
            onTap: () {},
          ),
          DashboardMenuTile(
            icon: Icons.gavel_outlined,
            title: 'Auction',
            subtitle: 'Coming soon',
            onTap: () {},
          ),
          DashboardMenuTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'KaoPay',
            subtitle: 'Wallet & payments',
            onTap: () {},
          ),
          DashboardMenuTile(
            icon: Icons.apps_outlined,
            title: 'More Services',
            subtitle: 'Future applications',
            showDivider: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}