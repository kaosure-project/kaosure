import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../../dashboard/presentation/widgets/kao_id_subpage_scaffold.dart';
import '../../../dashboard/presentation/widgets/section/section_body.dart';
import '../../application/providers/sso_providers.dart';
import '../../domain/entities/connected_app.dart';
import '../utils/sso_texts.dart';
import '../widgets/connected_app_tile.dart';

/// Apps the member allowed to use their Kao ID, with disconnect.
class ConnectedAppsPage extends ConsumerStatefulWidget {
  const ConnectedAppsPage({super.key});

  @override
  ConsumerState<ConnectedAppsPage> createState() => _ConnectedAppsPageState();
}

class _ConnectedAppsPageState extends ConsumerState<ConnectedAppsPage> {
  final Set<String> _revoking = {};

  Future<void> _disconnect(ConnectedApp app) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
      title: Text(l10n.ssoDisconnect),
      content: Text(l10n.ssoDisconnectConfirm(app.displayName)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(dialog, true), child: Text(l10n.ssoDisconnect)),
      ],
    ));
    if (confirmed != true || !mounted) return;
    setState(() => _revoking.add(app.clientId));
    String notice;
    try {
      await ref.read(oauthConsentUseCasesProvider).revoke(app.clientId);
      notice = l10n.ssoDisconnected;
    } catch (error) {
      notice = l10n.ssoFailureMessage(ssoFailureCodeOf(error));
    }
    if (!mounted) return;
    setState(() => _revoking.remove(app.clientId));
    ref.invalidate(connectedAppsProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apps = ref.watch(connectedAppsProvider);

    return KaoIdSubpageScaffold(
      badgeIcon: Icons.lock_outline,
      badgeLabel: l10n.dashSecurityTitle,
      actions: [
        IconButton(
          tooltip: l10n.authCheckAgain,
          color: AppColors.kaoBlue,
          onPressed: apps.isLoading ? null : () => ref.invalidate(connectedAppsProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: SectionBody(
        icon: Icons.apps_outlined,
        color: AppColors.kaoGreen,
        tint: AppColors.kaoGreenSoft,
        title: l10n.ssoConnectedAppsTitle,
        description: l10n.ssoConnectedAppsHelp,
        start: [
          apps.when(
            loading: () => const DashboardPanel(child: Center(child: CircularProgressIndicator())),
            error: (error, _) => DashboardPanel(child: _Message(
              icon: Icons.error_outline,
              message: l10n.ssoFailureMessage(ssoFailureCodeOf(error)),
              action: OutlinedButton(
                onPressed: () => ref.invalidate(connectedAppsProvider),
                child: Text(l10n.retry)),
            )),
            data: (items) => items.isEmpty
                ? DashboardPanel(child: _Message(icon: Icons.apps_outlined,
                    message: l10n.ssoConnectedAppsEmpty))
                : DashboardPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(children: [
                      for (var i = 0; i < items.length; i++)
                        ConnectedAppTile(
                          app: items[i],
                          busy: _revoking.contains(items[i].clientId),
                          showDivider: i < items.length - 1,
                          onDisconnect: () => _disconnect(items[i]),
                        ),
                    ]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Icon(icon, size: 44, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          if (action case final action?) ...[const SizedBox(height: 12), action],
        ]),
      );
}
