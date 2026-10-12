import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../app/routes/kao_id_routes.dart';
import '../../../../../shared/design_system/colors/app_colors.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../../dashboard/presentation/widgets/home/status_row.dart';
import '../../../dashboard/presentation/widgets/profile/profile_status_chip.dart';
import '../../../dashboard/presentation/widgets/section/menu_panel.dart';
import '../../../dashboard/presentation/widgets/section/section_body.dart';
import '../../../dashboard/presentation/widgets/security/dashboard_menu_tile.dart';
import '../../../issuance/application/providers/kao_id_issuance_provider.dart';
import '../../domain/entities/profile.dart';

/// "My account" tab: profile summary, account details and a shortcut to verification.
class AccountOverview extends ConsumerWidget {
  const AccountOverview({super.key, required this.profile, required this.onEdit, this.onRefresh});

  final Profile profile;
  final VoidCallback onEdit;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider).asData?.value;
    final identity = ref.watch(currentKaoIdIdentityProvider).asData?.value;
    final kaoId = identity != null && identity.isActive ? identity.kaoId : null;
    final name = (profile.displayName ?? '').trim();
    final username = (profile.username ?? '').trim();
    final email = user?.email ?? '';

    return SectionBody(
      icon: Icons.person_outline,
      color: AppColors.kaoBlue,
      tint: AppColors.kaoBlueSoft,
      title: l10n.accountTitle,
      description: l10n.personalDetailsDescription,
      onRefresh: onRefresh,
      start: [
        _ProfilePanel(profile: profile, name: name.isEmpty ? l10n.kaoIdUser : name,
          kaoId: kaoId, onEdit: onEdit),
        MenuPanel(children: [
          DashboardMenuTile(
            icon: Icons.contact_page_outlined,
            title: l10n.personalDetailsTitle,
            subtitle: l10n.piRowDescription,
            onTap: () => Navigator.of(context).pushNamed(KaoIdRoutes.personalInfo),
          ),
          DashboardMenuTile(
            icon: Icons.badge_outlined,
            title: l10n.identityVerification,
            subtitle: l10n.identityEntryDescription,
            color: AppColors.kaoTeal,
            tint: AppColors.kaoTealSoft,
            showDivider: false,
            onTap: () => Navigator.of(context).pushNamed(KaoIdRoutes.kyc),
          ),
        ]),
      ],
      end: [
        DashboardPanel(
          title: l10n.accDetailsTitle,
          child: Column(children: [
            _DetailRow(label: l10n.displayName, value: Text(name.isEmpty ? '-' : name)),
            _DetailRow(label: l10n.accUsernameLabel, value: username.isEmpty
                ? Text(l10n.usernameNotSet, style: const TextStyle(color: AppColors.textSecondary))
                : Text('@$username')),
            _DetailRow(label: l10n.authEmail, value: Wrap(spacing: 12, runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(email.isEmpty ? '-' : email),
                if (user != null)
                  user.emailConfirmed
                      ? StatusLabel(l10n.accEmailVerified, tone: StatusTone.positive)
                      : StatusLabel(l10n.accEmailUnverified, tone: StatusTone.pending),
              ])),
            _DetailRow(label: l10n.kaoId, value: kaoId == null
                ? Text(l10n.dashKaoIdPending, style: const TextStyle(color: AppColors.textSecondary))
                : Text(kaoId, style: const TextStyle(
                    color: AppColors.kaoBlue, fontWeight: FontWeight.w700))),
            _DetailRow(label: l10n.accMemberSince, last: true,
              value: Text(DateFormat.yMMMd(l10n.localeName).format(profile.createdAt.toLocal()))),
          ]),
        ),
      ],
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.profile, required this.name, required this.kaoId,
    required this.onEdit});

  final Profile profile;
  final String name;
  final String? kaoId;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final avatar = profile.avatarUrl;
    const placeholder = CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.kaoBlueSoft,
      foregroundColor: AppColors.kaoBlue,
      child: Icon(Icons.person_outline, size: 36),
    );
    final id = kaoId;

    return DashboardPanel(
      title: l10n.accProfileTitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          avatar != null && avatar.isNotEmpty
              ? ClipOval(child: Image.network(avatar, width: 72, height: 72, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder))
              : placeholder,
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 12, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ProfileStatusChip(profile: profile),
                if (id != null)
                  Text(l10n.dashKaoIdLine(id), style: text.bodyMedium?.copyWith(
                    color: AppColors.kaoBlue, fontWeight: FontWeight.w600)),
              ]),
          ])),
        ]),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l10n.editProfile),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kaoBlue,
              side: const BorderSide(color: AppColors.kaoBlue),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.last = false});

  final String label;
  final Widget value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final labelText = Text(label, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary));
    final valueText = DefaultTextStyle.merge(
      style: text.bodyLarge?.copyWith(color: AppColors.textPrimary),
      child: value,
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(builder: (context, constraints) => constraints.maxWidth >= 380
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 140, child: labelText),
                const SizedBox(width: 12),
                Expanded(child: valueText),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                labelText,
                const SizedBox(height: 4),
                valueText,
              ])),
      ),
      if (!last) const Divider(height: 1),
    ]);
  }
}
