import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../router/kao_id_routes.dart';
import 'dashboard_menu_tile.dart';

final class PasswordTile extends StatelessWidget {
  const PasswordTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardMenuTile(
      icon: Icons.lock_outline,
      title: l10n.password,
      subtitle: l10n.passwordChangeDescription,
      onTap: () {
        Navigator.of(context).pushNamed(
          KaoIdRoutes.changePassword,
        );
      },
    );
  }
}
