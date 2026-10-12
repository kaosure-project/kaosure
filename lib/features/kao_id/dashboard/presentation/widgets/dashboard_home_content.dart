import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../app/routes/kao_id_routes.dart';
import '../../../../../shared/design_system/colors/app_colors.dart';
import '../../../account/domain/entities/profile.dart';
import '../../../issuance/application/providers/kao_id_issuance_provider.dart';
import '../../application/providers/dashboard_summary_providers.dart';
import 'home/category_card.dart';
import 'home/finance_panel.dart';
import 'home/profile_summary_card.dart';
import 'home/services_panel.dart';

class DashboardHomeContent extends ConsumerWidget {
  const DashboardHomeContent({super.key, required this.profile,
    required this.onProfile, required this.onIdentity, required this.onRefresh});

  final Profile profile;
  final VoidCallback onProfile;
  final VoidCallback onIdentity;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileCard = ProfileSummaryCard(profile: profile, onOpen: onProfile);
    const finance = FinancePanel();
    const services = ServicesPanel();
    final personal = CategoryCard(
      icon: Icons.person_outline,
      color: AppColors.kaoBlue,
      tint: AppColors.kaoBlueSoft,
      title: l10n.personalDetailsTitle,
      description: l10n.piRowDescription,
      onOpen: () => Navigator.of(context).pushNamed(KaoIdRoutes.personalInfo),
    );
    final security = CategoryCard(
      icon: Icons.lock_outline,
      color: AppColors.kaoGreen,
      tint: AppColors.kaoGreenSoft,
      title: l10n.dashSecurityTitle,
      description: l10n.dashSecurityDescription,
      onOpen: () => Navigator.of(context).pushNamed(KaoIdRoutes.security),
    );
    final identity = CategoryCard(
      icon: Icons.badge_outlined,
      color: AppColors.kaoTeal,
      tint: AppColors.kaoTealSoft,
      title: l10n.identityVerification,
      description: l10n.identityEntryDescription,
      onOpen: onIdentity,
    );
    final settings = CategoryCard(
      icon: Icons.tune,
      color: AppColors.kaoSlate,
      tint: AppColors.kaoSlateSoft,
      title: l10n.settings,
      description: l10n.settingsHubDescription,
      onOpen: () => Navigator.of(context).pushNamed(KaoIdRoutes.settings),
    );

    Future<void> refresh() async {
      ref.invalidate(dashboardBankProvider);
      ref.invalidate(dashboardBusinessProvider);
      ref.invalidate(currentKaoIdIdentityProvider);
      await onRefresh();
    }

    Widget stack(List<Widget> cards, double gap) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              cards[i],
            ],
          ],
        );

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 840 &&
          MediaQuery.textScalerOf(context).scale(16) <= 24;
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(wide ? 24 : 16),
          children: [
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: stack([profileCard, finance, services], 20)),
                const SizedBox(width: 20),
                Expanded(child: stack([personal, security, identity, settings], 20)),
              ])
            else
              stack([profileCard, identity, finance, services, personal, security, settings], 16),
          ],
        ),
      );
    });
  }
}
