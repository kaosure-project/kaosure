import 'package:flutter/material.dart';

import '../security/dashboard_menu_tile.dart';

final class MoreServicesTile extends StatelessWidget {
  const MoreServicesTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.apps_outlined,
      title: 'บริการอื่น ๆ',
      subtitle: 'บริการทั้งหมดของ Kao Ecosystem',
      showDivider: false,
      onTap: () {
        // TODO: Navigate to All Services
      },
    );
  }
}