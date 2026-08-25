import 'package:flutter/material.dart';

import '../security/dashboard_menu_tile.dart';

final class AboutTile extends StatelessWidget {
  const AboutTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardMenuTile(
      icon: Icons.info_outline,
      title: 'About Kao ID',
      subtitle: 'Version, licenses and legal',
      showDivider: false,
      onTap: () {
        // TODO: Navigate to About
      },
    );
  }
}