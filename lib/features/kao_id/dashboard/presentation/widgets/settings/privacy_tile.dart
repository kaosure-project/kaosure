import 'package:flutter/material.dart';

import '../security/dashboard_menu_tile.dart';

final class PrivacyTile extends StatelessWidget {
  const PrivacyTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.privacy_tip_outlined,
      title: 'Privacy',
      subtitle: 'Privacy & permissions',
      onTap: () {
        // TODO: Navigate to Privacy
      },
    );
  }
}