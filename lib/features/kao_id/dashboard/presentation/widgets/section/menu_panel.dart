import 'package:flutter/material.dart';

import '../../../../../../shared/design_system/colors/app_colors.dart';
import '../home/dashboard_panel.dart';

/// White panel holding [DashboardMenuTile] rows, with an optional heading.
class MenuPanel extends StatelessWidget {
  const MenuPanel({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final heading = title;
    return DashboardPanel(
      padding: EdgeInsets.fromLTRB(16, heading == null ? 8 : 20, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (heading != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(heading, style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
        ...children,
      ]),
    );
  }
}
