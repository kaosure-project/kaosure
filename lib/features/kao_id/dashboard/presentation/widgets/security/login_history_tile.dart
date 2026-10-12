import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'dashboard_menu_tile.dart';

final class LoginHistoryTile extends StatelessWidget {
  const LoginHistoryTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardMenuTile(
      icon: Icons.history,
      title: l10n.loginHistory,
      subtitle: l10n.loginHistoryDescription,
      onTap: () {
        // TODO: Navigate to Login History Screen
      },
    );
  }
}
