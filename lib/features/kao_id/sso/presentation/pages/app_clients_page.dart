import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../account/presentation/pages/security/mfa_page.dart';
import '../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../../dashboard/presentation/widgets/section/section_body.dart';
import '../../../governance/presentation/widgets/admin/admin_scaffold.dart';
import '../../application/providers/sso_providers.dart';
import '../../domain/entities/app_client.dart';
import '../../domain/failures/sso_failure.dart';
import '../utils/sso_texts.dart';
import '../widgets/app_client_card.dart';
import '../widgets/app_client_form_dialog.dart';

/// Company-owner registry of sub-apps that sign members in with Kao ID.
class AppClientsPage extends ConsumerStatefulWidget {
  const AppClientsPage({super.key});

  @override
  ConsumerState<AppClientsPage> createState() => _AppClientsPageState();
}

class _AppClientsPageState extends ConsumerState<AppClientsPage> {
  final Set<String> _busy = {};

  void _reload() => ref.invalidate(appClientsProvider);

  Future<void> _openMfa() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MfaPage()));
    if (mounted) _reload();
  }

  Future<void> _edit([AppClient? client]) async {
    final l10n = AppLocalizations.of(context);
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppClientFormDialog(
        initial: client,
        onSave: ref.read(appClientRegistryUseCasesProvider).save,
      ),
    );
    if (saved != true || !mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.ssoAppSaved)));
  }

  Future<void> _toggle(AppClient client) async {
    final l10n = AppLocalizations.of(context);
    if (client.active) {
      final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
        title: Text(l10n.ssoAppSuspend),
        content: Text(l10n.ssoAppSuspendConfirm(client.displayName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.ssoAppSuspend)),
        ],
      ));
      if (confirmed != true || !mounted) return;
    }
    setState(() => _busy.add(client.appCode));
    String? failure;
    try {
      await ref.read(appClientRegistryUseCasesProvider).setActive(client.appCode, active: !client.active);
    } catch (error) {
      failure = l10n.ssoFailureMessage(ssoFailureCodeOf(error));
    }
    if (!mounted) return;
    setState(() => _busy.remove(client.appCode));
    _reload();
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clients = ref.watch(appClientsProvider);
    final items = clients.asData?.value;

    return AdminScaffold(
      actions: [
        IconButton(
          tooltip: l10n.authCheckAgain,
          color: AppColors.kaoBlue,
          onPressed: clients.isLoading ? null : _reload,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: l10n.twoFactorAuthentication,
          color: AppColors.kaoBlue,
          onPressed: _openMfa,
          icon: const Icon(Icons.security),
        ),
      ],
      child: SectionBody(
        icon: Icons.hub_outlined,
        color: AppColors.kaoBlue,
        tint: AppColors.kaoBlueSoft,
        title: l10n.ssoAppsAdminTitle,
        description: l10n.ssoAppsAdminHelp,
        top: [
          if (items != null)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const Key('sso-app-register'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: Text(l10n.ssoAppRegister),
              ),
            ),
        ],
        start: clients.when(
          loading: () => [const DashboardPanel(child: Center(child: CircularProgressIndicator()))],
          error: (error, _) {
            final code = ssoFailureCodeOf(error);
            return [
              DashboardPanel(child: Column(children: [
                const Icon(Icons.lock_outline, size: 44, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(l10n.ssoFailureMessage(code), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                  OutlinedButton(onPressed: _reload, child: Text(l10n.authCheckAgain)),
                  if (code == SsoFailureCode.mfaRequired)
                    TextButton(onPressed: _openMfa, child: Text(l10n.twoFactorAuthentication)),
                ]),
              ])),
            ];
          },
          data: (items) => items.isEmpty
              ? [DashboardPanel(child: Text(l10n.ssoAppsEmpty, textAlign: TextAlign.center))]
              : [
                  for (final client in items)
                    AppClientCard(
                      client: client,
                      busy: _busy.contains(client.appCode),
                      onEdit: () => _edit(client),
                      onToggle: () => _toggle(client),
                    ),
                ],
        ),
      ),
    );
  }
}
