import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../../shared/design_system/colors/app_colors.dart';
import 'dashboard_panel.dart';

/// Account section entry: coloured icon, title, short description and link.
class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.icon, required this.color,
    required this.tint, required this.title, required this.description,
    required this.onOpen});

  final IconData icon;
  final Color color;
  final Color tint;
  final String title;
  final String description;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DashboardPanel(
      onTap: onOpen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          DecoratedBox(
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
            child: Padding(padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color, size: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
        ]),
        const SizedBox(height: 14),
        Text(description, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onOpen,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.kaoBlue,
            minimumSize: const Size(48, 40),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(AppLocalizations.of(context).dashDetails),
        ),
      ]),
    );
  }
}
