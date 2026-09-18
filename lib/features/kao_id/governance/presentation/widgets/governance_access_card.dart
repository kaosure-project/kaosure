import 'package:flutter/material.dart';

import '../../domain/entities/governance_access.dart';

final class GovernanceAccessCard
    extends StatelessWidget {
  const GovernanceAccessCard({
    super.key,
    required this.access,
  });

  final GovernanceAccess access;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  access.isOwner
                      ? Icons.workspace_premium_outlined
                      : Icons.admin_panel_settings_outlined,
                  color: colors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    access.isOwner
                        ? 'Company Owner'
                        : 'ผู้ดูแลระบบ',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(
                  label: access.canAccessAdmin
                      ? 'มีสิทธิ์'
                      : 'ไม่มีสิทธิ์',
                  enabled: access.canAccessAdmin,
                ),
              ],
            ),
            if (access.roles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: access.roles
                    .map(
                      (role) => Chip(
                        label: Text(role),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.enabled,
  });

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;
    final color = enabled
        ? colors.primary
        : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius:
            BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
