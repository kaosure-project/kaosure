import 'package:flutter/material.dart';

import '../security/dashboard_menu_tile.dart';

final class MarketplaceTile extends StatelessWidget {
  const MarketplaceTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.storefront_outlined,
      title: 'Marketplace',
      subtitle: 'เข้าสู่ตลาดซื้อขายเก๋าชัวร์',
      onTap: () {
        // TODO: Navigate to Marketplace
      },
    );
  }
}