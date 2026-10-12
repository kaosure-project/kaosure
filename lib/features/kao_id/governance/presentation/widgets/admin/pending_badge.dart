import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../application/providers/admin_pending_providers.dart';

/// Rounded count of waiting items; hidden while loading, on error, or at zero.
class PendingBadge extends StatelessWidget {
  const PendingBadge({super.key, required this.count, this.color = AppColors.kaoBlue});

  final AsyncValue<PendingCount> count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = count.asData?.value;
    if (value == null || value.value == 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(value.label, textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.white, fontWeight: FontWeight.w700)),
    );
  }
}

/// [PendingBadge] followed by the menu chevron, for a menu tile trailing slot.
class PendingTrailing extends StatelessWidget {
  const PendingTrailing({super.key, required this.count, this.color = AppColors.kaoBlue});

  final AsyncValue<PendingCount> count;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        PendingBadge(count: count, color: color),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ]);
}
