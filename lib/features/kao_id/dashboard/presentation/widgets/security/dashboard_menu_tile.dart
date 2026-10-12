import 'package:flutter/material.dart';

import '../../../../../../shared/design_system/colors/app_colors.dart';

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
    this.color = AppColors.kaoBlue,
    this.tint = AppColors.kaoBlueSoft,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;
  final bool enabled;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hint = subtitle;

    return Column(
      children: [
        ListTile(
          enabled: enabled,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minVerticalPadding: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: hint == null
              ? null
              : Text(
                  hint,
                  style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
          trailing: trailing ??
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
          onTap: enabled ? onTap : null,
        ),
        if (showDivider) const Divider(height: 1, indent: 68),
      ],
    );
  }
}
