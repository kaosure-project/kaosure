import 'package:flutter/material.dart';

import '../../domain/entities/governance_assignment.dart';

final class GovernanceAssignmentsSection
    extends StatelessWidget {
  const GovernanceAssignmentsSection({
    super.key,
    required this.assignments,
    required this.canAssign,
    required this.canRevoke,
    required this.onAssign,
    required this.onRevoke,
  });

  final List<GovernanceAssignment>
      assignments;
  final bool canAssign;
  final bool canRevoke;
  final VoidCallback onAssign;
  final Future<void> Function(
    GovernanceAssignment assignment,
  ) onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'ผู้ดูแลระบบ',
                        style: theme
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'สิทธิ์ทั้งหมดผูกกับ Kao ID และตรวจสอบย้อนหลังได้',
                        style: theme
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),
                if (canAssign)
                  FilledButton.icon(
                    onPressed: onAssign,
                    icon: const Icon(
                      Icons.person_add_alt_1,
                    ),
                    label:
                        const Text('แต่งตั้ง'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (assignments.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 28,
                ),
                child: Center(
                  child: Text(
                    'ยังไม่มีรายการผู้ดูแลระบบ',
                  ),
                ),
              )
            else
              ...assignments.map(
                (assignment) =>
                    _AssignmentTile(
                  assignment: assignment,
                  canRevoke: canRevoke,
                  onRevoke: () =>
                      onRevoke(assignment),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _AssignmentTile
    extends StatelessWidget {
  const _AssignmentTile({
    required this.assignment,
    required this.canRevoke,
    required this.onRevoke,
  });

  final GovernanceAssignment assignment;
  final bool canRevoke;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(
          assignment.displayName.isEmpty
              ? '?'
              : assignment.displayName[0]
                  .toUpperCase(),
        ),
      ),
      title:
          Text(assignment.displayName),
      subtitle: Text(
        '${assignment.kaoId} • ${assignment.roleName}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            assignment.isActive
                ? Icons.check_circle
                : Icons
                    .remove_circle_outline,
            color: assignment.isActive
                ? colors.primary
                : colors
                    .onSurfaceVariant,
          ),
          if (canRevoke &&
              assignment.isActive) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'ถอนสิทธิ์',
              onPressed: onRevoke,
              icon: const Icon(
                Icons
                    .person_remove_outlined,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
