import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../domain/entities/staff_role.dart';

/// Permission switches grouped by category. Owner-only permissions are never listed.
class PermissionToggleList extends StatelessWidget {
  const PermissionToggleList({super.key, required this.catalogue, required this.enabled, this.onChanged});

  final List<StaffPermission> catalogue;
  final Set<String> enabled;

  /// Null while saving, which disables every switch.
  final void Function(StaffPermission permission, bool enabled)? onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final groups = <String, List<StaffPermission>>{};
    for (final permission in catalogue) {
      if (!permission.ownerOnly) groups.putIfAbsent(permission.category, () => []).add(permission);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(group.key, style: Theme.of(context).textTheme.titleSmall),
          ),
          for (final permission in group.value)
            SwitchListTile(
              key: ValueKey('permission-${permission.code}'),
              contentPadding: EdgeInsets.zero,
              value: enabled.contains(permission.code),
              onChanged: onChanged == null ? null : (value) => onChanged!(permission, value),
              title: Text(permission.name),
              subtitle: Text(permission.dangerous
                  ? '${permission.code} · ${l.staffPermissionDangerous}'
                  : permission.code),
              secondary: permission.dangerous
                  ? Tooltip(
                      message: l.staffPermissionDangerous,
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.kaoAmber),
                    )
                  : null,
            ),
        ],
      ],
    );
  }
}
