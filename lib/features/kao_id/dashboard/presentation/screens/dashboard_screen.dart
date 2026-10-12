import '../../../account/security/mfa_page.dart';
import '../../../account/security/sessions_page.dart';
import '../../../kyc/maintenance/document_health_page.dart';
import '../../../account/lifecycle/lifecycle_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../account/presentation/pages/account_page.dart';
import '../../../governance/presentation/widgets/governance_dashboard_tile.dart';
import '../../../router/kao_id_routes.dart';
import '../../application/providers/dashboard_provider.dart';
import '../widgets/dashboard_home_content.dart';
import '../widgets/kao_id_scaffold.dart';
import '../widgets/security/password_tile.dart';
import '../widgets/settings/general_settings_tile.dart';
import '../widgets/settings/sign_out_tile.dart';

final class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.initialSection = 0});

  final int initialSection;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

final class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _routes = [KaoIdRoutes.dashboard, KaoIdRoutes.profile,
    KaoIdRoutes.security, KaoIdRoutes.settings];

  @override
  void initState() {
    super.initState();
    if (widget.initialSection == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(dashboardControllerProvider.notifier).loadDashboard();
      });
    }
  }

  void _select(int index) {
    if (index == widget.initialSection) return;
    Navigator.of(context).pushReplacementNamed(_routes[index]);
  }

  Future<void> _refresh() =>
      ref.read(dashboardControllerProvider.notifier).loadDashboard();

  Future<void> _openIdentity() async {
    await Navigator.of(context).pushNamed(KaoIdRoutes.kyc);
    if (mounted) await _refresh();
  }

  Widget _section(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.initialSection == 1) return const AccountPage(embedded: true);
    if (widget.initialSection == 2) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.security, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Card(child: PasswordTile()),
          Card(child: ListTile(leading: const Icon(Icons.security), title: Text(l10n.twoFactorAuthentication),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MfaPage())))),
          Card(child: ListTile(leading: const Icon(Icons.devices_outlined), title: Text(l10n.sessionTitle),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SessionsPage())))),
          Card(child: ListTile(leading: const Icon(Icons.badge_outlined), title: Text(l10n.documentHealthTitle),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DocumentHealthPage())))),
        ],
      );
    }
    if (widget.initialSection == 3) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.settings, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Card(child: GeneralSettingsTile()),
          Card(child: ListTile(title: Text(l10n.lifeTitle), leading: const Icon(Icons.manage_accounts_outlined),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LifecyclePage())))),
          const GovernanceDashboardTile(),
          const SizedBox(height: 16),
          const Card(child: SignOutTile()),
        ],
      );
    }
    final state = ref.watch(dashboardControllerProvider);
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.hasError || !state.hasProfile) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.hasError ? l10n.dashboardLoadFailed : l10n.profileNotFound,
                textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _refresh, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }
    return DashboardHomeContent(
      profile: state.profile!,
      onProfile: () => _select(1),
      onIdentity: _openIdentity,
      onRefresh: _refresh,
    );
  }

  @override
  Widget build(BuildContext context) => KaoIdScaffold(
    selectedIndex: widget.initialSection,
    onSelected: _select,
    child: _section(context),
  );
}
