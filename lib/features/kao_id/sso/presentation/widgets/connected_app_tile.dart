import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../domain/entities/connected_app.dart';
import '../utils/sso_texts.dart';
import 'sso_app_avatar.dart';

class ConnectedAppTile extends StatelessWidget {
  const ConnectedAppTile({
    super.key,
    required this.app,
    required this.busy,
    required this.onDisconnect,
    this.showDivider = true,
  });

  final ConnectedApp app;
  final bool busy;
  final VoidCallback onDisconnect;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final registry = app.app;
    final lastSeen = registry?.lastSeenAt;
    final host = app.clientUri?.host ?? '';
    final claims = [...?registry?.claims]..sort((a, b) => a.index.compareTo(b.index));
    final secondary = text.bodySmall?.copyWith(color: AppColors.textSecondary);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SsoAppAvatar(name: app.displayName),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(app.displayName, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (registry?.firstParty == true)
                _Tag(icon: Icons.verified_outlined, label: l10n.ssoFirstParty,
                  color: AppColors.kaoGreen, tint: AppColors.kaoGreenSoft),
            ]),
            if (host.isNotEmpty) Text(host, style: secondary),
            const SizedBox(height: 4),
            Text(l10n.ssoGrantedAt(ssoDate(context, app.grantedAt)), style: secondary),
            if (lastSeen != null) Text(l10n.ssoLastUsed(ssoDate(context, lastSeen)), style: secondary),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final scope in app.scopes)
                _Tag(icon: ssoScopeIcon(scope), label: l10n.ssoScopeLabel(scope)),
              for (final claim in claims)
                _Tag(icon: ssoClaimIcon(claim), label: l10n.ssoClaimLabel(claim)),
            ]),
            const SizedBox(height: 10),
            busy
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : OutlinedButton.icon(
                    key: Key('sso-disconnect-${app.clientId}'),
                    onPressed: onDisconnect,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    icon: const Icon(Icons.link_off, size: 18),
                    label: Text(l10n.ssoDisconnect),
                  ),
          ])),
        ]),
      ),
      if (showDivider) const Divider(height: 1, indent: 58),
    ]);
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label,
    this.color = AppColors.kaoSlate, this.tint = AppColors.kaoSlateSoft});

  final IconData icon;
  final String label;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(child: Text(label, style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: color))),
        ]),
      );
}
