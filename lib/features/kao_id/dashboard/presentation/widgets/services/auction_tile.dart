import 'package:flutter/material.dart';

import '../security/dashboard_menu_tile.dart';

final class AuctionTile extends StatelessWidget {
  const AuctionTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.gavel_outlined,
      title: 'Auction',
      subtitle: 'ระบบประมูลสินค้า',
      onTap: () {
        // TODO: Navigate to Auction
      },
    );
  }
}
