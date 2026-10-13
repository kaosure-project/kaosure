import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/pages/review/kyc_review_detail_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../../account/presentation/pages/security/mfa_page.dart';
import '../../../../auth/application/providers/auth_provider.dart';
import '../../../../governance/application/services/access_refresh.dart';
import '../../../data/repositories/supabase_kyc_review_repository.dart';
import '../../utils/review_failure_message.dart';

int requiredEvidenceCount(Map<String, dynamic> row) => switch(row['document_type']) {
  'passport' || 'bank' || 'business_bank' => 1,
  'residence_card' => row['residence_format'] == 'paper' ? 1 : 2,
  null || 'thai_national_id' => 2,
  _ => 0,
};

String reviewTypeLabel(AppLocalizations l, dynamic type) => switch(type) {
  'passport' => l.kycPassportTitle, 'residence_card' => l.kycForeignDocTitle,
  'bank' => l.kycBankTitle, 'business_bank' => l.reviewBusinessBankTitle,
  null || 'thai_national_id' => l.kycIdCardTitle,
  _ => l.kycUnknownStatus,
};

class KycReviewPage extends ConsumerStatefulWidget {
  const KycReviewPage({super.key});
  @override
  ConsumerState<KycReviewPage> createState() => _KycReviewPageState();
}

class _KycReviewPageState extends ConsumerState<KycReviewPage> with WidgetsBindingObserver, AccessRefresh<KycReviewPage> {
  @override
  void refreshAccess() { _load(); }
  List<Map<String, dynamic>> _rows = [];
  bool _busy = false;
  Object? _failure;
  String? _owner;
  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(_load);
  }
  Future<void> _load() async {
    if (!mounted || _busy) { return; }
    setState(() { _busy = true; _failure = null; _rows = []; });
    try {
      final rows = await ref.read(kycReviewRepositoryProvider).queue();
      if (mounted) { setState(() => _rows = rows); }
    } catch (error) {
      if (mounted) { setState(() => _failure = error); }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currentOwner = ref.watch(authProvider).asData?.value?.id;
    if (_owner == null || currentOwner != _owner) {
      return Scaffold(appBar: AppBar(title: Text(l.reviewTitle)),
        body: Center(child: Text(l.contactSessionChanged)));
    }
    return Scaffold(appBar: AppBar(title: Text(l.reviewTitle)), body: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.reviewQueueHelp),
          OutlinedButton(onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MfaPage()));
            if (mounted) { await _load(); }
          }, child: Text(l.twoFactorAuthentication)),
          OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
          if (_busy) const LinearProgressIndicator(),
          if (_failure != null) Text(reviewFailureMessage(l, _failure!, l.reviewLoadFailed)),
          if (!_busy && _failure == null && _rows.isEmpty) Text(l.reviewEmpty),
          for (final row in _rows) Card(child: ListTile(
            title: Text(row['full_name'] as String? ?? '—'),
            subtitle: Text('${reviewTypeLabel(l, row['document_type'])} · ${row['id']}${row['first_reviewer'] != null ? '\n${l.dualWaiting}' : ''}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : () async {
              await Navigator.of(context).push<void>(MaterialPageRoute(
                builder: (_) => KycReviewDetailPage(row: row)));
              if (mounted) { await _load(); }
            },
          )),
        ]),
      ),
    ));
  }
}
