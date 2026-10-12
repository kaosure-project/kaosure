import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    this.onNotificationPressed,
    this.onSettingsPressed,
  });

  final VoidCallback? onNotificationPressed;
  final VoidCallback? onSettingsPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      automaticallyImplyLeading: true,
      centerTitle: false,
      elevation: 0,
      title: Text(l10n.kaoId),
      actions: [
        if (onNotificationPressed != null)
          IconButton(
            tooltip: l10n.notifications,
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onNotificationPressed,
          ),
        if (onSettingsPressed != null)
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettingsPressed,
          ),
      ],
    );
  }
}
