import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../account/domain/entities/profile.dart';
import 'kao_code_action.dart';
import 'profile_action.dart';
import 'quick_actions_layout.dart';
import 'verify_action.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.quickActions, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        const QuickActionsLayout(
          children: [
            ProfileAction(),
            VerifyAction(),
            KaoCodeAction(),
          ],
        ),
      ],
    );
  }
}
