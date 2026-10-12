import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../../application/providers/admin_pending_providers.dart';

/// Tappable summary of one review queue: icon, waiting count and label.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({super.key, required this.icon, required this.color, required this.tint,
    required this.label, required this.count, required this.onTap});

  final IconData icon;
  final Color color;
  final Color tint;
  final String label;
  final AsyncValue<PendingCount> count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final value = count.asData?.value;
    return DashboardPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (count.isLoading && value == null)
            const SizedBox(
              height: 32,
              child: Align(alignment: Alignment.centerLeft, child: SizedBox.square(
                dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            Text(value?.label ?? '–', style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: (value?.value ?? 0) > 0 ? color : AppColors.textSecondary)),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        ])),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ]),
    );
  }
}
