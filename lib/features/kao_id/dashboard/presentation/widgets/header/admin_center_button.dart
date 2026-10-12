import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../application/providers/dashboard_summary_providers.dart';
import 'header_action_button.dart';

/// Opens the admin hub; hidden unless the account is an admin or reviewer.
class AdminCenterButton extends ConsumerWidget {
  const AdminCenterButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(dashboardAdminAccessProvider).asData?.value == true;
    if (!allowed) return const SizedBox.shrink();
    return HeaderActionButton(
      icon: Icons.admin_panel_settings_outlined,
      label: AppLocalizations.of(context).dashAdminCenter,
      compact: compact,
      onPressed: () async {
        await Navigator.of(context).pushNamed('/admin');
        if (context.mounted) ref.invalidate(dashboardAdminAccessProvider);
      },
    );
  }
}
