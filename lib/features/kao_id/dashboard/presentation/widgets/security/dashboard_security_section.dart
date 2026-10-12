import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'devices_tile.dart';
import 'login_history_tile.dart';
import 'password_tile.dart';
import 'two_factor_tile.dart';

final class DashboardSecuritySection extends StatelessWidget {
  const DashboardSecuritySection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Text(
              l10n.security,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
          ),

          const PasswordTile(),

          const DevicesTile(),

          const LoginHistoryTile(),

          const TwoFactorTile(),
        ],
      ),
    );
  }
}
