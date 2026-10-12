import 'package:kaosure/features/wallet/wallet_page.dart';
import '../../../notifications/notification_center.dart';
import '../../../governance/members/member_page.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../account/domain/entities/profile.dart';
import '../../../router/kao_id_routes.dart';
import 'profile/profile_status_chip.dart';

class DashboardHomeContent extends StatelessWidget {
  const DashboardHomeContent({super.key, required this.profile,
    required this.onProfile, required this.onIdentity, required this.onRefresh});

  final Profile profile;
  final VoidCallback onProfile;
  final VoidCallback onIdentity;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = (profile.displayName ?? '').trim();
    final avatar = profile.avatarUrl;
    final profileCard = _AccountCard(
      title: l10n.personalDetailsTitle,
      icon: Icons.person_outline,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipOval(child: avatar != null && avatar.isNotEmpty
              ? Image.network(avatar, width: 56, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(width: 56, height: 56,
                    child: Icon(Icons.person_outline, size: 32)))
              : const CircleAvatar(radius: 28, child: Icon(Icons.person_outline))),
          const SizedBox(width: 16),
          Expanded(child: Text(name.isEmpty ? l10n.kaoIdUser : name,
            style: theme.textTheme.titleMedium)),
        ]),
        const SizedBox(height: 12),
        ProfileStatusChip(profile: profile),
        const SizedBox(height: 16),
        Text(l10n.personalDetailsDescription),
        const SizedBox(height: 20),
        OutlinedButton.icon(onPressed: onProfile,
          icon: const Icon(Icons.person_outline), label: Text(l10n.viewProfile)),
      ],
    );
    final identityCard = _AccountCard(
      title: l10n.identityVerification, icon: Icons.badge_outlined,
      children: [
        Text(l10n.identityEntryDescription),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: onIdentity,
          icon: const Icon(Icons.badge_outlined), label: Text(l10n.viewIdentityStatus)),
      ],
    );
    Widget category(IconData icon, String title, String description, String route) =>
        _AccountCard(title: title, icon: icon, children: [
          Text(description), const SizedBox(height: 20),
          TextButton.icon(onPressed: () => Navigator.of(context).pushNamed(route),
            icon: const Icon(Icons.arrow_forward), label: Text(l10n.openSectionLabel)),
        ]);
    final securityCard = category(Icons.lock_outline, l10n.security,
      l10n.securityHubDescription, KaoIdRoutes.security);
    final settingsCard = category(Icons.settings_outlined, l10n.settings,
      l10n.settingsHubDescription, KaoIdRoutes.settings);

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 840 &&
          MediaQuery.textScalerOf(context).scale(16) <= 24;
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(wide ? 24 : 16),
          children: [
            const NotificationBell(), const MemberAdminEntry(),
            Text(l10n.accountTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.accountHubIntroduction),
            const SizedBox(height: 24),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(children: [
                  profileCard, const SizedBox(height: 20), identityCard,
                ])),
                const SizedBox(width: 20),
                Expanded(child: Column(children: [
                  securityCard, const SizedBox(height: 20), settingsCard,
                ])),
              ])
            else ...[
              profileCard, const SizedBox(height: 16),
              securityCard, const SizedBox(height: 16),
              identityCard, const SizedBox(height: 16), settingsCard,
            ],
            const SizedBox(height: 24),
            ListTile(leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(l10n.walletTitle), trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WalletPage()))),
          ],
        ),
      );
    });
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero, elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: theme.colorScheme.primary), const SizedBox(width: 12),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 24),
          ...children,
        ]),
      ),
    );
  }
}
