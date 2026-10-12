import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/governance_provider.dart';
import '../../../dashboard/presentation/widgets/security/dashboard_menu_tile.dart';
import '../../../router/kao_id_routes.dart';

final class GovernanceDashboardTile
    extends ConsumerWidget {
  const GovernanceDashboardTile({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final access = ref.watch(
      governanceAccessProvider,
    );

    return access.maybeWhen(
      data: (value) {
        if (!value.canAccessAdmin) {
          return const SizedBox.shrink();
        }

        return DashboardMenuTile(
          icon: Icons
              .admin_panel_settings_outlined,
          title: AppLocalizations.of(context).governanceLabel,
          subtitle:
              AppLocalizations.of(context).governanceDescription,
          onTap: () {
            Navigator.of(context).pushNamed(
              KaoIdRoutes.governance,
            );
          },
        );
      },
      orElse: () =>
          const SizedBox.shrink(),
    );
  }
}
