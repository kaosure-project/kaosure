import '../../../account/presentation/pages/security/security_operations_page.dart';
import '../../../account/presentation/pages/security/mfa_page.dart';
import '../../application/services/access_refresh.dart';
import 'package:kaosure/features/wallet/partners/partner_page.dart';
import 'owner_requests_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../kyc/review/kyc_review_page.dart';
import '../../../kyc/review/kyc_review_repository.dart';
import '../../application/providers/member_access_provider.dart';

class AdminHubPage extends ConsumerStatefulWidget {
  const AdminHubPage({super.key});
  @override
  ConsumerState<AdminHubPage> createState() => _AdminHubPageState();
}
class _AdminHubPageState extends ConsumerState<AdminHubPage>
    with WidgetsBindingObserver, AccessRefresh<AdminHubPage> {
  @override
  void refreshAccess() {
    ref.invalidate(memberAccessProvider);
    ref.invalidate(kycReviewerAccessProvider);
  }
  @override
  void initState() {
    super.initState();
    Future.microtask(() { if (mounted) { refreshAccess(); } });
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).asData?.value?.id;
    if (user == null) {
      return Scaffold(appBar: AppBar(title: Text(l.adminHubTitle)),
        body: Center(child: Text(l.contactSessionChanged)));
    }
    final account = ref.watch(memberAccessProvider);
    final reviewer = ref.watch(kycReviewerAccessProvider);
    final canManage = !account.isLoading && !account.hasError && account.asData?.value == true;
    final canReview = !reviewer.isLoading && !reviewer.hasError && reviewer.asData?.value == true;
    void refresh() {
      ref.invalidate(memberAccessProvider);
      ref.invalidate(kycReviewerAccessProvider);
    }
    Widget entry(IconData icon, String title, String help, Future<dynamic> Function() open) =>
      Card(margin: const EdgeInsets.symmetric(vertical: 8), child: ListTile(contentPadding: const EdgeInsets.all(20),leading: CircleAvatar(child: Icon(icon)), title: Text(title),
        subtitle: Text(help), trailing: const Icon(Icons.chevron_right), onTap: () async {
          await open();
          if (mounted) { refreshAccess(); }
        }));
    return Scaffold(appBar: AppBar(title: Text(l.adminHubTitle), actions: [
        IconButton(tooltip: l.twoFactorAuthentication, icon: const Icon(Icons.security),
          onPressed: () async { await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MfaPage())); if (mounted) { refreshAccess(); } }),
        if (canManage) IconButton(tooltip: l.securityOperations, icon: const Icon(Icons.monitor_heart_outlined),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SecurityOperationsPage()))),
      ]),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.adminHubScope),
          OutlinedButton(onPressed: refresh, child: Text(l.authCheckAgain)),
          if (account.isLoading || reviewer.isLoading) const LinearProgressIndicator(),
          if (account.hasError || reviewer.hasError) Text(l.kycLoadFailed),
          if (!account.isLoading && !reviewer.isLoading &&
              !account.hasError && !reviewer.hasError && !canManage && !canReview)
            Text(l.adminAccessDenied),
          if (canManage) entry(Icons.people_outline, l.adminMembersTitle, l.adminReadOnly,
            () => Navigator.of(context).pushNamed('/admin/members')),
          if (canManage) entry(Icons.manage_accounts, l.staffTitle, l.adminHubStaffHelp,
            () => Navigator.of(context).pushNamed('/admin/staff')),
          if (canManage) entry(Icons.assignment_outlined, l.ownerRequests, l.ownerRequestsHelp,
            () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OwnerRequestsPage()))),
          if (canReview) entry(Icons.fact_check_outlined, l.reviewTitle, l.adminHubReviewHelp,
            () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const KycReviewPage()))),
          if (canManage) entry(Icons.handshake_outlined, l.partnerTitle, l.partnerHelp,
            () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PartnerPage()))),
          if (canManage) entry(Icons.local_shipping_outlined, l.carrierTitle, l.partnerHelp,
            () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PartnerPage(shipping:true)))),
        ]))));
  }
}
