import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../domain/entities/staff_grant_request.dart';
import '../admin_display.dart';

/// One role request. Cancel is for the Owner; approve and reject only show when the
/// signed-in person is allowed to be the second approver.
class GrantRequestCard extends StatelessWidget {
  const GrantRequestCard({super.key, required this.grant, this.onCancel, this.onDecide});

  final StaffGrantRequest grant;
  final VoidCallback? onCancel;
  final void Function(bool approve)? onDecide;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final status = switch (grant.status) {
      StaffGrantStatus.pending =>
        grant.mode == StaffGrantMode.coolingOff ? l.staffGrantCoolingOff : l.staffGrantWaitingSecond,
      StaffGrantStatus.activated => l.staffGrantActivated,
      StaffGrantStatus.rejected => l.staffGrantRejected,
      StaffGrantStatus.cancelled => l.staffGrantCancelled,
      StaffGrantStatus.expired => l.staffGrantExpired,
    };
    final canDecide = grant.pending && grant.canDecide && onDecide != null;
    return Card(
      key: ValueKey('grant-${grant.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(realValue(grant.targetName), style: Theme.of(context).textTheme.titleMedium),
            AdminValue(label: l.adminAccountCode, value: grant.targetCode, copyable: true),
            Text(staffRoleLabel(l, grant.roleCode, grant.roleName)),
            Text(status),
            if (grant.requesterName != null || grant.requesterCode != null)
              AdminValue(
                label: l.staffGrantRequester,
                value: '${realValue(grant.requesterName)}\n${realValue(grant.requesterCode)}',
              ),
            if (grant.permissions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l.staffPermissions, style: Theme.of(context).textTheme.labelMedium),
              for (final permission in grant.permissions.entries)
                Text(permission.value ? '${permission.key} · ${l.staffPermissionDangerous}' : permission.key),
            ],
            if (grant.pending && grant.mode == StaffGrantMode.coolingOff && grant.activateAt != null)
              AdminValue(label: l.staffStartsAt, value: adminDate(context, grant.activateAt)),
            if (grant.pending && grant.mode == StaffGrantMode.twoPerson && grant.decideBefore != null)
              AdminValue(label: l.staffGrantDecideBefore, value: adminDate(context, grant.decideBefore)),
            if (grant.decisionReason != null) AdminValue(label: l.staffGrantReason, value: grant.decisionReason),
            if (grant.pending && (onCancel != null || canDecide))
              Wrap(
                spacing: 8,
                children: [
                  if (onCancel != null)
                    TextButton(
                      key: ValueKey('grant-cancel-${grant.id}'),
                      onPressed: onCancel,
                      child: Text(l.staffGrantCancel),
                    ),
                  if (canDecide) ...[
                    OutlinedButton(
                      key: ValueKey('grant-reject-${grant.id}'),
                      onPressed: () => onDecide!(false),
                      child: Text(l.staffGrantReject),
                    ),
                    FilledButton(
                      key: ValueKey('grant-approve-${grant.id}'),
                      onPressed: () => onDecide!(true),
                      child: Text(l.staffGrantApprove),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
