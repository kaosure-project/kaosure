import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/features/wallet/presentation/pages/partner_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../account/presentation/pages/security/mfa_page.dart';
import '../../../account/presentation/pages/security/security_operations_page.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../business/application/providers/business_review_providers.dart';
import '../../../business/presentation/pages/review/business_review_queue_page.dart';
import '../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../../dashboard/presentation/widgets/section/menu_panel.dart';
import '../../../dashboard/presentation/widgets/section/section_body.dart';
import '../../../dashboard/presentation/widgets/security/dashboard_menu_tile.dart';
import '../../../kyc/application/providers/kyc_review_providers.dart';
import '../../../kyc/presentation/pages/review/kyc_review_page.dart';
import '../../../sso/presentation/pages/app_clients_page.dart';
import '../../application/providers/admin_pending_providers.dart';
import '../../application/providers/member_access_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../application/services/access_refresh.dart';
import '../../domain/entities/staff_tools.dart';
import '../widgets/admin/admin_scaffold.dart';
import '../widgets/admin/admin_stat_card.dart';
import '../widgets/admin/pending_badge.dart';
import 'order_issues_page.dart';
import 'owner_requests_page.dart';
import 'review_moderation_page.dart';
import 'system_contents_page.dart';
import 'topup_settings_page.dart';
import 'topups_page.dart';
import 'withdrawals_page.dart';

class AdminHubPage extends ConsumerStatefulWidget {
  const AdminHubPage({super.key});
  @override
  ConsumerState<AdminHubPage> createState() => _AdminHubPageState();
}

class _AdminHubPageState extends ConsumerState<AdminHubPage> with WidgetsBindingObserver, AccessRefresh<AdminHubPage> {
  @override
  void refreshAccess() {
    ref.invalidate(memberAccessProvider);
    ref.invalidate(kycReviewerAccessProvider);
    ref.invalidate(kycPendingCountProvider);
    ref.invalidate(businessReviewQueueProvider);
    ref.invalidate(staffToolsProvider);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        refreshAccess();
      }
    });
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) refreshAccess();
  }

  Future<void> _openNamed(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) refreshAccess();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).asData?.value?.id;
    if (user == null) {
      return AdminScaffold(child: Center(child: Text(l.contactSessionChanged)));
    }
    final account = ref.watch(memberAccessProvider);
    final reviewer = ref.watch(kycReviewerAccessProvider);
    final loading = account.isLoading || reviewer.isLoading;
    final failed = account.hasError || reviewer.hasError;
    final canManage = !account.isLoading && !account.hasError && account.asData?.value == true;
    final canReview = !reviewer.isLoading && !reviewer.hasError && reviewer.asData?.value == true;
    final tools = ref.watch(staffToolsProvider).asData?.value ?? StaffTools.none;
    const none = AsyncValue<PendingCount>.loading();
    final kycCount = canReview ? ref.watch(kycPendingCountProvider) : none;
    final businessCount = canReview ? ref.watch(businessPendingCountProvider) : none;
    final secondCount = canReview ? ref.watch(businessSecondVoteCountProvider) : none;

    Widget notice(String message, {bool retry = false}) => DashboardPanel(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(retry ? Icons.error_outline : Icons.lock_outline, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          if (retry) ...[
            const SizedBox(width: 12),
            OutlinedButton(onPressed: refreshAccess, child: Text(l.authCheckAgain)),
          ],
        ],
      ),
    );

    final stats = [
      AdminStatCard(
        icon: Icons.fact_check_outlined,
        color: AppColors.kaoTeal,
        tint: AppColors.kaoTealSoft,
        label: l.adminStatKyc,
        count: kycCount,
        onTap: () => _open(const KycReviewPage()),
      ),
      AdminStatCard(
        icon: Icons.storefront_outlined,
        color: AppColors.kaoBlue,
        tint: AppColors.kaoBlueSoft,
        label: l.adminStatBusiness,
        count: businessCount,
        onTap: () => _open(const BusinessReviewQueuePage()),
      ),
      AdminStatCard(
        icon: Icons.groups_outlined,
        color: AppColors.kaoAmber,
        tint: AppColors.kaoAmberSoft,
        label: l.dualWaiting,
        count: secondCount,
        onTap: () => _open(const BusinessReviewQueuePage(onlySecondVote: true)),
      ),
    ];

    final reviews = MenuPanel(
      title: l.adminGroupReview,
      children: [
        DashboardMenuTile(
          icon: Icons.fact_check_outlined,
          color: AppColors.kaoTeal,
          tint: AppColors.kaoTealSoft,
          title: l.reviewTitle,
          subtitle: l.adminHubReviewHelp,
          trailing: PendingTrailing(count: kycCount, color: AppColors.kaoTeal),
          onTap: () => _open(const KycReviewPage()),
        ),
        DashboardMenuTile(
          icon: Icons.storefront_outlined,
          title: l.businessReviewTitle,
          subtitle: l.businessReviewHubHelp,
          showDivider: false,
          trailing: PendingTrailing(count: businessCount),
          onTap: () => _open(const BusinessReviewQueuePage()),
        ),
      ],
    );

    final people = MenuPanel(
      title: l.adminGroupPeople,
      children: [
        DashboardMenuTile(
          icon: Icons.people_outline,
          title: l.adminMembersTitle,
          subtitle: l.adminReadOnly,
          onTap: () => _openNamed('/admin/members'),
        ),
        DashboardMenuTile(
          icon: Icons.manage_accounts_outlined,
          title: l.staffTitle,
          subtitle: l.adminHubStaffHelp,
          onTap: () => _openNamed('/admin/staff'),
        ),
        DashboardMenuTile(
          icon: Icons.assignment_outlined,
          title: l.ownerRequests,
          subtitle: l.ownerRequestsHelp,
          showDivider: false,
          onTap: () => _open(const OwnerRequestsPage()),
        ),
      ],
    );

    final partners = MenuPanel(
      title: l.adminGroupPartners,
      children: [
        DashboardMenuTile(
          icon: Icons.handshake_outlined,
          color: AppColors.kaoGreen,
          tint: AppColors.kaoGreenSoft,
          title: l.partnerTitle,
          subtitle: l.partnerHelp,
          onTap: () => _open(const PartnerPage()),
        ),
        DashboardMenuTile(
          icon: Icons.local_shipping_outlined,
          color: AppColors.kaoGreen,
          tint: AppColors.kaoGreenSoft,
          title: l.carrierTitle,
          subtitle: l.partnerHelp,
          onTap: () => _open(const PartnerPage(shipping: true)),
        ),
        DashboardMenuTile(
          icon: Icons.hub_outlined,
          title: l.ssoAppsAdminTitle,
          subtitle: l.ssoAppsAdminHubHelp,
          showDivider: false,
          onTap: () => _open(const AppClientsPage()),
        ),
      ],
    );

    final finance = MenuPanel(
      title: l.adminGroupFinance,
      children: [
        if (tools.topups)
          DashboardMenuTile(
            icon: Icons.qr_code_2,
            color: AppColors.kaoGreen,
            tint: AppColors.kaoGreenSoft,
            title: l.topupsTitle,
            subtitle: l.topupsHubHelp,
            showDivider: tools.topupSettings || tools.withdrawals || tools.contents,
            trailing: PendingTrailing(
              count: AsyncData(PendingCount(tools.pendingTopups)),
              color: AppColors.kaoGreen,
            ),
            onTap: () => _open(TopupsPage(canEditSettings: tools.topupSettings)),
          ),
        if (tools.topupSettings)
          DashboardMenuTile(
            icon: Icons.tune,
            color: AppColors.kaoGreen,
            tint: AppColors.kaoGreenSoft,
            title: l.topupSettingsTitle,
            subtitle: l.topupSettingsHubHelp,
            showDivider: tools.withdrawals || tools.contents,
            onTap: () => _open(const TopupSettingsPage()),
          ),
        if (tools.withdrawals)
          DashboardMenuTile(
            icon: Icons.savings_outlined,
            color: AppColors.kaoGreen,
            tint: AppColors.kaoGreenSoft,
            title: l.withdrawalsTitle,
            subtitle: l.withdrawalsHubHelp,
            showDivider: tools.contents,
            trailing: PendingTrailing(
              count: AsyncData(PendingCount(tools.pendingWithdrawals)),
              color: AppColors.kaoGreen,
            ),
            onTap: () => _open(const WithdrawalsPage()),
          ),
        if (tools.contents)
          DashboardMenuTile(
            icon: Icons.article_outlined,
            color: AppColors.kaoAmber,
            tint: AppColors.kaoAmberSoft,
            title: l.contentsTitle,
            subtitle: l.contentsHubHelp,
            showDivider: false,
            onTap: () => _open(const SystemContentsPage()),
          ),
      ],
    );

    final marketplace = MenuPanel(
      title: l.adminGroupMarketplace,
      children: [
        if (tools.orderIssues)
          DashboardMenuTile(
            icon: Icons.report_problem_outlined,
            title: l.orderIssuesTitle,
            subtitle: l.orderIssuesHubHelp,
            showDivider: tools.reviews,
            trailing: PendingTrailing(count: AsyncData(PendingCount(tools.openOrderIssues))),
            onTap: () => _open(const OrderIssuesPage()),
          ),
        if (tools.reviews)
          DashboardMenuTile(
            icon: Icons.rate_review_outlined,
            color: AppColors.kaoTeal,
            tint: AppColors.kaoTealSoft,
            title: l.moderationTitle,
            subtitle: l.moderationHubHelp,
            showDivider: false,
            trailing: PendingTrailing(
              count: AsyncData(PendingCount(tools.pendingReviewReports)),
              color: AppColors.kaoTeal,
            ),
            onTap: () => _open(const ReviewModerationPage()),
          ),
      ],
    );

    final security = MenuPanel(
      title: l.adminGroupSecurity,
      children: [
        DashboardMenuTile(
          icon: Icons.security,
          color: AppColors.kaoSlate,
          tint: AppColors.kaoSlateSoft,
          title: l.twoFactorAuthentication,
          subtitle: l.adminMfaHelp,
          showDivider: canManage,
          onTap: () => _open(const MfaPage()),
        ),
        if (canManage)
          DashboardMenuTile(
            icon: Icons.monitor_heart_outlined,
            color: AppColors.kaoSlate,
            tint: AppColors.kaoSlateSoft,
            title: l.securityOperations,
            subtitle: l.adminSecurityOpsHelp,
            showDivider: false,
            onTap: () => _open(const SecurityOperationsPage()),
          ),
      ],
    );

    final start = [if (canReview) reviews, if (canManage) people];
    final end = [
      if (tools.finance) finance,
      if (tools.marketplace) marketplace,
      if (canManage) partners,
      security,
    ];

    return AdminScaffold(
      actions: [
        IconButton(
          tooltip: l.authCheckAgain,
          color: AppColors.kaoBlue,
          onPressed: loading ? null : refreshAccess,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: SectionBody(
        icon: Icons.admin_panel_settings_outlined,
        color: AppColors.kaoBlue,
        tint: AppColors.kaoBlueSoft,
        title: l.adminHubTitle,
        description: l.adminHubScope,
        top: [
          if (loading) const LinearProgressIndicator(),
          if (failed) notice(l.kycLoadFailed, retry: true),
          if (!loading && !failed && !canManage && !canReview && !tools.any) notice(l.adminAccessDenied),
          if (canReview)
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 640
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < stats.length; i++) ...[
                          if (i > 0) const SizedBox(width: 16),
                          Expanded(child: stats[i]),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < stats.length; i++) ...[if (i > 0) const SizedBox(height: 12), stats[i]],
                      ],
                    ),
            ),
        ],
        start: start.isEmpty ? end : start,
        end: start.isEmpty ? const [] : end,
      ),
    );
  }
}
