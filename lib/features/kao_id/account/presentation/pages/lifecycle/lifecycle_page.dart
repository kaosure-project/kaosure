import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/features/kao_id/account/data/repositories/supabase_lifecycle_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../../auth/application/providers/auth_provider.dart';
import '../../../../governance/shared/admin_display.dart';
import 'recovery_evidence_page.dart';

class LifecyclePage extends ConsumerStatefulWidget {
  const LifecyclePage({super.key});
  @override
  ConsumerState<LifecyclePage> createState() => _LifecyclePageState();
}

class _LifecyclePageState extends ConsumerState<LifecyclePage> {
  final _reason = TextEditingController();
  String? _user;
  Map<String, dynamic>? _data;
  bool _busy = false, _failed = false;
  bool get sessionMatches => _user != null && ref.read(authProvider).asData?.value?.id == _user;
  @override
  void initState() {
    super.initState(); _user = ref.read(authProvider).asData?.value?.id;
    Future.microtask(_load);
  }
  @override
  void dispose() { _reason.dispose(); super.dispose(); }
  Future<void> _load() async {
    if (!mounted || _busy || !sessionMatches) { return; }
    setState(() { _busy = true; _failed = false; _data = null; });
    try {
      final result = await ref.read(lifecycleRepositoryProvider).snapshot();
      if (mounted && sessionMatches) { setState(() => _data = result); }
    } catch (_) { if (mounted) { setState(() => _failed = true); } }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _submit(String kind, {String? cancelId}) async {
    if (!mounted || _busy || !sessionMatches) { return; }
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(cancelId == null ? l.lifeTitle : l.cancel), content: Text(l.lifeHelp),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.back)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.continueLabel))]));
    if (confirm != true || !mounted || !sessionMatches) { return; }
    setState(() { _busy = true; _failed = false; });
    try {
      final repository = ref.read(lifecycleRepositoryProvider);
      if (cancelId == null) {
        await repository.submit(kind, _reason.text.trim());
      } else { await repository.cancel(cancelId); }
      if (mounted && sessionMatches) { _reason.clear(); }
    } catch (_) { if (mounted) { setState(() => _failed = true); } }
    finally { if (mounted) { setState(() => _busy = false); } }
    if (mounted && sessionMatches && !_failed) { await _load(); }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(authProvider).asData?.value?.id;
    final data = _data;
    final rows = (data?['requests'] as List? ?? []).cast<Map>();
    final kind = data?['account_status'] == 'closed' ? 'recovery' : 'closure';
    final allowed = data != null && data['owner'] != true &&
      ['active', 'closed'].contains(data['account_status']) && !rows.any((r) => r['status'] == 'pending');
    return Scaffold(appBar: AppBar(title: Text(l.lifeTitle)), body: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
        child: current == null || current != _user ? Text(l.contactSessionChanged) :
        ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.lifeHelp),
          if (_busy) const LinearProgressIndicator(),
          if (_failed) Text(l.kycLoadFailed),
          OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
          if (data?['owner'] == true) Text(l.lifeOwner),
          if (allowed) ...[
            TextField(controller: _reason, enabled: !_busy, maxLength: 1000, maxLines: 3,
              decoration: InputDecoration(labelText: l.reviewReason), onChanged: (_) => setState(() {})),
            FilledButton(onPressed: !_busy && _reason.text.trim().length >= 3 ? () => _submit(kind) : null,
              child: Text(kind == 'closure' ? l.lifeClose : l.lifeRecover)),
          ],
          for (final row in rows) Card(child: Padding(padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row['kind'] == 'closure' ? l.lifeClose : l.lifeRecover),
              Text(row['status'] == 'pending' ? l.lifePending : row['status'] == 'cancelled' ? l.lifeCancelled : row['status'] == 'rejected' ? l.lifeRejected : row['status'] == 'approved' ? l.lifeApproved : l.kycUnknownStatus),
              Text(row['reason'] as String? ?? ''),
              if(row['decision_reason'] != null) AdminValue(label:l.reviewReason,value:row['decision_reason']),
              Text(adminDate(context,row['created_at'])),
              if (row['status'] == 'pending' && row['kind'] == 'recovery') FilledButton(
                onPressed: _busy ? null : () async {
                  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RecoveryEvidencePage(requestId: row['id'] as String)));
                  if (mounted && sessionMatches) { await _load(); }
                }, child: Text(l.recoveryEvidenceTitle)),
              if (row['status'] == 'pending') TextButton(onPressed: _busy ? null : () => _submit(kind, cancelId: row['id'] as String), child: Text(l.cancel)),
            ]))),
        ]))));
  }
}
