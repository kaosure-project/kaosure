import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../dashboard/presentation/widgets/kao_id_subpage_scaffold.dart';

/// Kao ID page frame for the admin center, marked with the admin badge.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({super.key, required this.child, this.actions = const []});

  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => KaoIdSubpageScaffold(
        badgeIcon: Icons.admin_panel_settings_outlined,
        badgeLabel: AppLocalizations.of(context).dashAdminCenter,
        actions: actions,
        child: child,
      );
}
