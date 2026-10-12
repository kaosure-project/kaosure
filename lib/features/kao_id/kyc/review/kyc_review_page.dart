import '../../account/presentation/pages/security/mfa_page.dart';
import '../../governance/application/services/access_refresh.dart';
import '../../account/application/providers/recovery_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../auth/application/providers/auth_provider.dart';
import '../identity_card/national_id_repository.dart';
import 'kyc_review_repository.dart';
import 'review_failure_message.dart';

int requiredEvidenceCount(Map<String, dynamic> row) => switch(row['document_type']) {
  'passport' || 'bank' => 1,
  'residence_card' => row['residence_format'] == 'paper' ? 1 : 2,
  null || 'thai_national_id' => 2,
  _ => 0,
};
String reviewTypeLabel(AppLocalizations l, dynamic type) => switch(type) {
  'passport' => l.kycPassportTitle, 'residence_card' => l.kycResidenceTitle,
  'bank' => l.kycBankTitle, null || 'thai_national_id' => l.kycIdCardTitle,
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

class KycReviewDetailPage extends ConsumerStatefulWidget {
  const KycReviewDetailPage({super.key, required this.row});
  final Map<String, dynamic> row;
  @override
  ConsumerState<KycReviewDetailPage> createState() => _KycReviewDetailPageState();
}
class _KycReviewDetailPageState extends ConsumerState<KycReviewDetailPage> with WidgetsBindingObserver, AccessRefresh<KycReviewDetailPage> {
  @override
  void refreshAccess() { ref.invalidate(kycReviewerAccessProvider); }
  final _reason = TextEditingController();
  final _viewed = <String>{};
  bool _busy = false, _checked = false, _recoveryChecked = false;
  Object? _failure;
  String? _owner;
  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(() { if (mounted) { refreshAccess(); } });
  }
  @override
  void dispose() { _reason.dispose(); super.dispose(); }
  Future<void> _preview(String path) async {
    setState(() { _busy = true; _failure = null; });
    try {
      final downloaded = await ref.read(kycReviewRepositoryProvider).preview(path);
      final bytes = await compute(prepareIdImage, downloaded);
      if (!mounted || ref.read(authProvider).asData?.value?.id != _owner) { return; }
      setState(() => _busy = false);
      final l = AppLocalizations.of(context);
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        title: Text(l.idViewDocument),
        content: SizedBox(width: 640, height: 420, child: InteractiveViewer(
          child: Consumer(builder: (context, ref, child) {
            final owner = ref.watch(authProvider).asData?.value?.id;
            final access = ref.watch(kycReviewerAccessProvider);
            return owner == _owner && owner != null && !access.isLoading && !access.hasError && access.asData?.value == true
                ? Image.memory(bytes, fit: BoxFit.contain)
                : Text(l.contactSessionChanged);
          }))),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l.back))],
      ));
      if (mounted) { setState(() => _viewed.add(path)); }
    } catch (error) {
      if (mounted) { setState(() => _failure = error); }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }
  Future<void> _decide(bool approve) async {
    if (_busy) { return; }
    final l = AppLocalizations.of(context);
    if ((!approve || widget.row['is_recovery'] == true) && _reason.text.trim().length < 3) {
      setState(() => _failure = StateError('reason')); return;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(approve ? l.reviewApprove : l.reviewReject),
      content: Text(l.reviewConfirm),
      actions: [TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.continueLabel))],
    ));
    if (confirmed != true || !mounted || ref.read(authProvider).asData?.value?.id != _owner) { return; }
    setState(() { _busy = true; _failure = null; });
    try {
      if (widget.row['is_recovery'] == true) {
        await ref.read(recoveryDecisionProvider)(widget.row['id'] as String, approve, _reason.text.trim(), _recoveryChecked);
      } else {
        await ref.read(kycReviewRepositoryProvider).decide(widget.row['id'] as String, approve, _reason.text.trim());
      }
      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context).pop();
      }
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
    final access = ref.watch(kycReviewerAccessProvider);
    if (access.isLoading || access.hasError || access.asData?.value != true) {
      return Scaffold(appBar: AppBar(title: Text(l.reviewTitle)), body: Center(
        child: access.isLoading ? const CircularProgressIndicator() : Column(
          mainAxisSize: MainAxisSize.min, children: [
            Text(access.hasError ? l.reviewLoadFailed : l.adminAccessDenied),
            OutlinedButton(onPressed: refreshAccess, child: Text(l.authCheckAgain)),
            TextButton(onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MfaPage()));
              if (mounted) { refreshAccess(); }
            }, child: Text(l.twoFactorAuthentication)),
          ])));
    }
    final row = widget.row;
    final ownVote = row['dual_review'] == true && row['first_reviewer'] == _owner;
    final paths = (row['paths'] as List? ?? []).cast<String>();
    final previous = (row['previous_paths'] as List? ?? []).cast<String>();
    String date(dynamic value) {
      final d = DateTime.tryParse(value?.toString() ?? '');
      return d == null ? '—' : MaterialLocalizations.of(context).formatMediumDate(d);
    }
    return PopScope(canPop: !_busy, child: Scaffold(
      appBar: AppBar(title: Text(l.reviewTitle)), body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          OutlinedButton(onPressed: _busy ? null : () async {
            await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MfaPage()));
            if (mounted) { refreshAccess(); }
          }, child: Text(l.twoFactorAuthentication)),
          if (row['dual_review'] == true) ...[
            Text(l.dualReviewHelp),
            if (row['first_reviewer'] != null) ...[
              Text('${l.dualFirstDecision}: ${row['first_decision'] == true ? l.reviewApprove : l.reviewReject}'),
              SelectableText(row['first_reason'] as String? ?? '—'),
              Text(ownVote ? l.dualOwnVote : l.dualDisagreeHelp),
            ],
          ],
          if (row['is_recovery'] == true) ...[
            Text(l.recoveryReviewTitle, style: Theme.of(context).textTheme.titleLarge),
            Text(l.recoveryReviewHelp),
            Text('${l.idFullName}: ${row['previous_name'] ?? '—'}'),
            SelectableText('${row['previous_number'] ?? '—'}'),
            for (final path in previous) OutlinedButton(onPressed: _busy ? null : () => _preview(path), child: Text(l.recoveryPreviousEvidence)),
            CheckboxListTile(value: _recoveryChecked, title: Text(l.recoveryConfirmPerson),
              onChanged: _busy ? null : (v) => setState(() => _recoveryChecked = v ?? false)),
            const Divider(),
          ],
          Text(reviewTypeLabel(l, row['document_type'])),
          Text('${l.idFullName}: ${row['full_name'] ?? '—'}'),
          if (row['issuing_country'] != null) Text('${l.residenceIssuingCountry}: ${row['issuing_country']}'),
          if (row['bank_name'] != null) Text('${l.bankInstitutionName}: ${row['bank_name']}'),
          if (row['document_type'] == 'bank') Text('${l.reviewIdentityName}: ${row['identity_name'] ?? l.kycUnknownStatus}'),
          SelectableText('${row['document_type'] == 'passport' ? l.kycPassportNumber : row['document_type'] == 'residence_card' ? l.residenceNumber : row['document_type'] == 'bank' ? l.bankAccountNumber : l.idNumber}: ${row['document_number'] ?? '—'}'),
          if (row['document_type'] != 'bank') Text('${l.kycIssueDate}: ${date(row['issued_date'])}'),
          if (row['document_type'] != 'bank') Text('${l.kycExpiryDate}: ${row['expiry_date'] == null && (row['document_type'] == null || row['document_type'] == 'thai_national_id') ? l.idLifetime : date(row['expiry_date'])}'),
          for (final path in paths) OutlinedButton(onPressed: _busy ? null : () => _preview(path),
            child: Text(path.contains('/front.') ? l.idViewFront : path.contains('/back.') ? l.idViewBack : l.idViewDocument)),
          CheckboxListTile(value: _checked, title: Text(l.reviewChecked),
            onChanged: _busy ? null : (v) => setState(() => _checked = v ?? false)),
          TextField(controller: _reason, enabled: !_busy, maxLength: 1000, maxLines: 3,
            decoration: InputDecoration(labelText: l.reviewReason)),
          if (_failure != null) Text(_failure is StateError && (_failure! as StateError).message == 'reason'
            ? l.reviewReasonRequired : reviewFailureMessage(l, _failure!, l.reviewActionFailed)),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          FilledButton(onPressed: !ownVote && !_busy && _checked && (row['is_recovery'] != true || (_recoveryChecked && previous.every(_viewed.contains))) && requiredEvidenceCount(row) > 0 && paths.length == requiredEvidenceCount(row) && paths.every(_viewed.contains)
            ? () => _decide(true) : null, child: Text(l.reviewApprove)),
          OutlinedButton(onPressed: _busy || ownVote ? null : () => _decide(false), child: Text(l.reviewReject)),
        ]),
      )),
    ));
  }
}
