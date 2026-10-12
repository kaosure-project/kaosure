import '../../application/providers/kyc_review_providers.dart';
import '../pages/review/kyc_review_page.dart';
import '../widgets/review/kao_id_issuance_card.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/providers/email_verification_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../dashboard/application/providers/dashboard_provider.dart';
import '../../../phone_verification/presentation/pages/phone_verification_page.dart';
import '../../application/providers/kyc_provider.dart';
import '../../application/states/kyc_state.dart';
import '../bank/bank_verification_page.dart';
import '../email/email_verification_page.dart';
import '../identity_card/identity_card_page.dart';
import '../passport/passport_page.dart';
import '../widgets/kyc_status_label.dart';
import '../widgets/document_status_label.dart';
import 'residence_permit_page.dart';
import 'verification_history_page.dart';

final class KycPage extends ConsumerStatefulWidget {
  const KycPage({super.key});
  @override
  ConsumerState<KycPage> createState() => _KycPageState();
}

final class _KycPageState extends ConsumerState<KycPage> {
  bool _emailLoading = true;
  bool _emailFailed = false;

  Future<void> _refreshEmail() async {
    if (!mounted) { return; }
    setState(() { _emailLoading = true; _emailFailed = false; });
    try {
      await ref.read(authProvider.notifier).refreshCurrentUser();
    } catch (_) {
      if (mounted) { setState(() => _emailFailed = true); }
    } finally {
      if (mounted) { setState(() => _emailLoading = false); }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadKyc);
  }

  Future<void> _loadKyc() async {
    if (!mounted) { return; }
    ref.invalidate(myKaoIdR7cProvider);
    ref.invalidate(kycReviewerAccessProvider);
    final dashboard = ref.read(dashboardControllerProvider.notifier);
    final kyc = ref.read(kycControllerProvider.notifier);
    await Future.wait([dashboard.loadDashboard(), kyc.load(), _refreshEmail()]);
  }

  Future<void> _open(WidgetBuilder builder) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(builder: builder));
    if (mounted) { await _loadKyc(); }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(kycControllerProvider);
    final dashboard = ref.watch(dashboardControllerProvider);
    final canReview = ref.watch(kycReviewerAccessProvider).asData?.value == true;
    final emailStatus = ref.watch(emailVerificationStatusProvider);
    final busy = state.isLoading || dashboard.isLoading || _emailLoading;
    final verification = state.isAvailable(KycResource.verification)
        ? state.verification : null;
    final requestReady = state.isAvailable(KycResource.request);
    final problem = !busy && (state.hasError || dashboard.hasError || _emailFailed);
    String flag(bool? value) => value == null ? l10n.kycUnknownStatus
        : value ? l10n.kycVerifiedStatus : l10n.kycUnverifiedStatus;
    Widget heading(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(label, style: theme.textTheme.titleMedium),
    );
    Widget entry(String id, IconData icon, String title, String status,
        WidgetBuilder destination) => Card(
      child: ListTile(
        key: ValueKey('kyc-$id'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title), subtitle: Text(status),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(destination),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.identityVerification)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: RefreshIndicator(
          onRefresh: _loadKyc,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(l10n.kycHubIntro),
              KaoIdIssuanceCard(eligible: verification?.status == 'approved'),
              if (canReview) OutlinedButton.icon(
                onPressed: () => _open((_) => const KycReviewPage()),
                icon: const Icon(Icons.fact_check_outlined), label: Text(l10n.reviewTitle)),
              if (busy) ...[
                const SizedBox(height: 16), const LinearProgressIndicator(),
              ],
              if (problem) Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.kycLoadFailed,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _loadKyc, child: Text(l10n.retry)),
                    ],
                  ),
                ),
              ),
              heading(l10n.kycRequestTitle),
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(!requestReady ? l10n.kycUnknownStatus
                    : state.verificationRequest == null ? l10n.kycNoRequest
                    : kycStatusLabel(l10n, state.verificationRequest!.status)),
              )),
              heading(l10n.kycContactGroup),
              entry('email', Icons.mail_outline, l10n.kycEmailTitle,
                flag(_emailLoading || _emailFailed ? null : emailStatus), (_) => const EmailVerificationPage()),
              entry('phone', Icons.phone_outlined, l10n.kycPhoneTitle,
                flag(verification?.phoneVerified), (_) => const PhoneVerificationPage()),
              heading(l10n.kycDocumentsGroup),
              entry('identity-card', Icons.badge_outlined, l10n.kycIdCardTitle,
                documentStatusLabel(l10n, state, state.identityCard),
                (_) => const IdentityCardPage()),
              entry('passport', Icons.menu_book_outlined, l10n.kycPassportTitle,
                documentStatusLabel(l10n, state, state.passport),
                (_) => const PassportPage()),
              entry('history', Icons.history, l10n.kycHistoryTitle,
                state.failedResources.contains(KycResource.history)
                    ? l10n.kycHistoryFailed : l10n.kycHistoryDescription,
                (_) => const VerificationHistoryPage()),
              const SizedBox(height: 16),
              Card(child: ExpansionTile(
                title: Text(l10n.kycOtherGroup),
                children: [
                  entry('residence', Icons.description_outlined, l10n.kycResidenceTitle,
                    documentStatusLabel(l10n, state, state.residencePermit), (_) => const ResidencePermitPage()),
                  entry('bank', Icons.account_balance_outlined, l10n.kycBankTitle,
                    state.isAvailable(KycResource.bank)
                        ? state.bankVerification == null ? l10n.bankNoAccounts
                          : kycStatusLabel(l10n, state.bankVerification!.status)
                        : l10n.kycUnknownStatus,
                    (_) => const BankVerificationPage()),
                ],
              )),
            ],
          ),
        ),
      ))),
    );
  }
}
