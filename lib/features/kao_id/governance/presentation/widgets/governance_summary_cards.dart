import 'package:flutter/material.dart';

import '../../domain/entities/governance_access.dart';
import '../../domain/entities/governance_assignment.dart';

final class GovernanceSummaryCards extends StatelessWidget {
  const GovernanceSummaryCards({
    super.key,
    required this.access,
    required this.assignments,
  });

  final GovernanceAccess access;
  final List<GovernanceAssignment> assignments;

  @override
  Widget build(BuildContext context) {
    final activeAssignments =
        assignments.where((item) => item.isActive).length;
    final inactiveAssignments =
        assignments.length - activeAssignments;

    final cards = <_SummaryCardData>[
      _SummaryCardData(
        icon: access.isOwner
            ? Icons.workspace_premium_outlined
            : Icons.admin_panel_settings_outlined,
        label: 'สิทธิ์ปัจจุบัน',
        value: access.isOwner
            ? 'Company Owner'
            : access.isAdmin
                ? 'Administrator'
                : 'No access',
      ),
      _SummaryCardData(
        icon: Icons.verified_user_outlined,
        label: 'บทบาทของฉัน',
        value: access.roles.isEmpty
            ? (access.isOwner ? 'Owner' : '0')
            : access.roles.length.toString(),
      ),
      _SummaryCardData(
        icon: Icons.groups_2_outlined,
        label: 'ผู้ดูแลที่ Active',
        value: activeAssignments.toString(),
      ),
      _SummaryCardData(
        icon: Icons.history_outlined,
        label: 'Inactive',
        value: inactiveAssignments.toString(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 4
            : width >= 560
                ? 2
                : 1;
        const spacing = 12.0;
        final itemWidth =
            (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: _SummaryCard(data: card),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

final class _SummaryCardData {
  const _SummaryCardData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

final class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.data,
  });

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                data.icon,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
