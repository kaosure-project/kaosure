import 'package:flutter/material.dart';

import '../../../../../../shared/design_system/colors/app_colors.dart';

/// White dashboard card on the grey page background.
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({super.key, required this.child, this.title, this.icon,
    this.iconColor = AppColors.kaoBlue, this.onTap, this.padding = const EdgeInsets.all(24)});

  final Widget child;
  final String? title;
  final IconData? icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final heading = title;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      shadowColor: const Color(0x14000000),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (heading != null) ...[
                Row(children: [
                  if (icon != null) ...[
                    Icon(icon, color: iconColor),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: Text(heading, style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                ]),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
