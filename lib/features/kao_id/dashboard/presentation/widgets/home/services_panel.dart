import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../../app/routes/kao_id_routes.dart';
import '../../../../../../shared/design_system/colors/app_colors.dart';
import '../../../../business/domain/entities/business_registration.dart';
import '../../../application/providers/dashboard_summary_providers.dart';
import 'dashboard_panel.dart';
import 'status_row.dart';

class ServicesPanel extends ConsumerWidget {
  const ServicesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final secondhand = ref.watch(secondhandEntryProvider);
    final business = ref.watch(dashboardBusinessProvider);
    final registration = business.asData?.value;
    final businessStatus = business.when(
      loading: () => const SizedBox(width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, _) => StatusLabel(l10n.dashLoadFailedShort, tone: StatusTone.negative),
      data: (value) => switch (value?.status) {
        null => StatusLabel(l10n.dashNotRegistered, tone: StatusTone.neutral),
        BusinessRegistrationStatus.draft => StatusLabel(l10n.dashDraft, tone: StatusTone.neutral),
        BusinessRegistrationStatus.submitted ||
        BusinessRegistrationStatus.underReview =>
          StatusLabel(l10n.kycUnderReview, tone: StatusTone.pending),
        BusinessRegistrationStatus.requiresAction =>
          StatusLabel(l10n.businessRegStatusActionTitle, tone: StatusTone.pending),
        BusinessRegistrationStatus.approved =>
          StatusLabel(l10n.kycVerifiedLabel, tone: StatusTone.positive),
        BusinessRegistrationStatus.rejected =>
          StatusLabel(l10n.dashNotApproved, tone: StatusTone.negative),
      },
    );
    final canStart = business.hasValue &&
        (registration == null || registration.isRejected);
    return DashboardPanel(
      title: l10n.dashServicesTitle,
      icon: Icons.apps_outlined,
      child: Column(children: [
        StatusRow(
          icon: Icons.storefront_outlined,
          title: l10n.dashSecondhandName,
          subtitle: l10n.marketplaceDescription,
          status: StatusLabel(l10n.dashServiceAvailable, tone: StatusTone.positive),
          actionLabel: l10n.dashServiceOpen,
          onAction: secondhand == null
              ? null
              : () => ref.read(serviceLauncherProvider)(secondhand),
        ),
        const Divider(height: 1, color: AppColors.divider),
        StatusRow(
          icon: Icons.business_center_outlined,
          title: l10n.dashBusinessName,
          subtitle: l10n.businessRegHubDescription,
          status: businessStatus,
          actionLabel: canStart ? l10n.dashBusinessRegister : l10n.dashDetails,
          onAction: () async {
            await Navigator.of(context).pushNamed(KaoIdRoutes.businessRegistration);
            if (context.mounted) ref.invalidate(dashboardBusinessProvider);
          },
        ),
      ]),
    );
  }
}
