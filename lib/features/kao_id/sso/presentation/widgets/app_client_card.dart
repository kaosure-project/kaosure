import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../domain/entities/app_client.dart';
import 'sso_app_avatar.dart';

class AppClientCard extends StatelessWidget {
  const AppClientCard({
    super.key,
    required this.client,
    required this.busy,
    required this.onEdit,
    required this.onToggle,
  });

  final AppClient client;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final label = text.labelMedium?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600);
    final claims = [...client.claims]..sort((a, b) => a.index.compareTo(b.index));

    Widget section(String title, Widget body) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: label),
            const SizedBox(height: 6),
            body,
          ]),
        );

    Widget names(List<String> values) => values.isEmpty
        ? Text(l10n.ssoAppNone, style: text.bodySmall?.copyWith(color: AppColors.textSecondary))
        : Wrap(spacing: 6, runSpacing: 6, children: [
            for (final value in values)
              _Badge(label: value, color: AppColors.kaoSlate, tint: AppColors.kaoSlateSoft),
          ]);

    return DashboardPanel(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SsoAppAvatar(name: client.displayName),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(client.displayName, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            SelectableText(client.appCode, style: text.bodySmall?.copyWith(
              color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              client.active
                  ? _Badge(label: l10n.ssoAppActive, color: AppColors.kaoGreen, tint: AppColors.kaoGreenSoft)
                  : _Badge(label: l10n.ssoAppSuspended, color: AppColors.kaoAmber, tint: AppColors.kaoAmberSoft),
              if (client.firstParty)
                _Badge(label: l10n.ssoFirstParty, color: AppColors.kaoBlue, tint: AppColors.kaoBlueSoft),
              _Badge(label: l10n.ssoAppMembers(client.members), color: AppColors.kaoSlate,
                tint: AppColors.kaoSlateSoft),
            ]),
          ])),
        ]),
        section(l10n.ssoAppClientId, SelectableText(client.clientId, style: text.bodySmall)),
        if (!client.oauthRegistered)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.kaoAmber),
              const SizedBox(width: 6),
              Expanded(child: Text(l10n.ssoAppOauthMissing,
                style: text.bodySmall?.copyWith(color: AppColors.kaoAmber))),
            ]),
          ),
        section(l10n.ssoAppRedirects, names(client.redirectUris)),
        section(l10n.ssoAppClaims, claims.isEmpty
            ? names(const [])
            : Wrap(spacing: 6, runSpacing: 6, children: [
                for (final claim in claims)
                  _Badge(label: claim.name, color: AppColors.kaoBlue, tint: AppColors.kaoBlueSoft),
              ])),
        section(l10n.ssoAppAllowedRpcs, names(client.rpcs)),
        section(l10n.ssoAppAllowedTables, names(client.tables)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
          OutlinedButton.icon(
            key: Key('sso-app-edit-${client.appCode}'),
            onPressed: busy ? null : onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.ssoAppEdit),
          ),
          client.active
              ? OutlinedButton.icon(
                  key: Key('sso-app-toggle-${client.appCode}'),
                  onPressed: busy ? null : onToggle,
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  icon: const Icon(Icons.pause_circle_outline),
                  label: Text(l10n.ssoAppSuspend),
                )
              : FilledButton.icon(
                  key: Key('sso-app-toggle-${client.appCode}'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: busy ? null : onToggle,
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(l10n.ssoAppActivate),
                ),
        ]),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.tint});

  final String label;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color, fontWeight: FontWeight.w600)),
      );
}
