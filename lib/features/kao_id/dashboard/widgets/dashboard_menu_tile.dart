import 'package:flutter/material.dart';

class DashboardMenuTile extends StatelessWidget {
  const DashboardMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.showDivider = true,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showDivider;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          enabled: enabled,
          leading: CircleAvatar(
            child: Icon(icon),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall,
                ),
          trailing: trailing ??
              const Icon(
                Icons.chevron_right,
              ),
          onTap: enabled ? onTap : null,
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}