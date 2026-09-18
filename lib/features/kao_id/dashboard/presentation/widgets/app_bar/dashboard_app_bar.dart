import 'package:flutter/material.dart';

class DashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
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
    return AppBar(
      automaticallyImplyLeading: true,
      centerTitle: false,
      elevation: 0,
      title: const Text(
        'เก๋าไอดี',
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(
            Icons.notifications_outlined,
          ),
          onPressed: onNotificationPressed,
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(
            Icons.settings_outlined,
          ),
          onPressed: onSettingsPressed,
        ),
      ],
    );
  }
}