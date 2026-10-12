import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../application/providers/kyc_provider.dart';
import '../../application/states/kyc_state.dart';
import '../widgets/kyc_status_label.dart';

final class VerificationHistoryPage extends ConsumerStatefulWidget {
  const VerificationHistoryPage({super.key});
  @override
  ConsumerState<VerificationHistoryPage> createState() => _VerificationHistoryPageState();
}

class _VerificationHistoryPageState extends ConsumerState<VerificationHistoryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(kycControllerProvider.notifier).load();
    });
  }
  Future<void> _reload() => ref.read(kycControllerProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycControllerProvider);
    final l10n = AppLocalizations.of(context);
    final available = state.isAvailable(KycResource.history);
    String action(String value) => switch (value) {
      'approve:bank' => '${l10n.kycActionApprove} · ${l10n.kycBankTitle}',
      'reject:bank' => '${l10n.kycActionReject} · ${l10n.kycBankTitle}',
      'email_confirmed' => '${l10n.kycEmailTitle} · ${l10n.kycVerifiedStatus}',
      'phone_confirmed' => '${l10n.kycPhoneTitle} · ${l10n.kycVerifiedStatus}',
      'submit:thai_national_id' => '${l10n.kycActionSubmit} · ${l10n.kycIdCardTitle}',
      'submit:passport' => '${l10n.kycActionSubmit} · ${l10n.kycPassportTitle}',
      'submit:residence_card' => '${l10n.kycActionSubmit} · ${l10n.kycResidenceTitle}',
      'submit:bank' => '${l10n.kycActionSubmit} · ${l10n.kycBankTitle}',
      'submit:document' || 'submitted' => l10n.kycActionSubmit,
      'approve' => l10n.kycActionApprove,
      'reject' => l10n.kycActionReject,
      'review' => l10n.kycActionReview,
      'submit' => l10n.kycActionSubmit,
      'cancel' => l10n.kycActionCancel,
      _ => l10n.kycHistoryEvent,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.kycHistoryTitle)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.kycHistoryDescription), const SizedBox(height: 16),
              if (state.isLoading) const LinearProgressIndicator()
              else if (!available) ...[
                Text(l10n.kycHistoryFailed), const SizedBox(height: 12),
                FilledButton(onPressed: _reload, child: Text(l10n.retry)),
              ] else if (state.verificationHistory.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text(l10n.kycHistoryEmpty))
              else ...state.verificationHistory.map((item) {
                final date = item.createdAt.toLocal();
                final material = MaterialLocalizations.of(context);
                return Card(child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(action(item.action)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kycStatusLabel(l10n, item.newStatus ?? item.oldStatus)),
                      if (item.notes?.isNotEmpty == true) Text(item.notes!),
                      Text('${material.formatMediumDate(date)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(date))}'),
                    ],
                  ),
                ));
              }),
            ],
          ),
        ),
      ))),
    );
  }
}
