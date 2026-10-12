import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import '../../auth/application/providers/auth_provider.dart';
import 'member_repository.dart';

abstract interface class AccountStateRepository {
  Future<List<Map<String, dynamic>>> history(String target);
  Future<void> change(String target, String expected, String next, String reason);
}
final accountStateRepositoryProvider = Provider<AccountStateRepository>((ref) =>
  _AccountStateRepository(ref.watch(supabaseClientProvider)));
class _AccountStateRepository implements AccountStateRepository {
  _AccountStateRepository(this.client);
  final SupabaseClient client;
  Future<dynamic> call(String name, Map<String, dynamic> params) async {
    final id = client.auth.currentUser?.id;
    if (id == null) { throw StateError('session'); }
    final result = await client.rpc(name, params: params);
    if (client.auth.currentUser?.id != id) { throw StateError('session'); }
    return result;
  }
  @override
  Future<List<Map<String, dynamic>>> history(String target) async =>
    (await call('account_history_r9f', {'p_target': target}) as List)
      .map((e) => Map<String, dynamic>.from(e as Map)).toList();
  @override
  Future<void> change(String target, String expected, String next, String reason) async {
    await call('set_account_state_r9f', {'p_target': target, 'p_expected': expected,
      'p_next': next, 'p_reason': reason});
  }
}
class AccountStatePage extends ConsumerStatefulWidget {
  const AccountStatePage({super.key, required this.target, required this.initialStatus});
  final String target, initialStatus;
  @override
  ConsumerState<AccountStatePage> createState() => _AccountStatePageState();
}
class _AccountStatePageState extends ConsumerState<AccountStatePage> {
  final _reason = TextEditingController();
  late String _status;
  String? _actor;
  bool _busy = false, _failed = false;
  List<Map<String, dynamic>> _history = [];
  bool get sameSession => _actor != null && ref.read(authProvider).asData?.value?.id == _actor;
  @override
  void initState() {
    super.initState(); _status = widget.initialStatus;
    _actor = ref.read(authProvider).asData?.value?.id;
    Future.microtask(_load);
  }
  @override
  void dispose() { _reason.dispose(); super.dispose(); }
  Future<void> _load() async {
    if (_busy || !sameSession) { return; }
    setState(() { _busy = true; _failed = false; _history = []; });
    try {
      final rows = await ref.read(accountStateRepositoryProvider).history(widget.target);
      if (mounted && sameSession) { setState(() => _history = rows); }
    } catch (_) { if (mounted) { setState(() => _failed = true); } }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _change() async {
    if (_busy || !sameSession || _reason.text.trim().length < 3) { return; }
    final next = _status == 'active' ? 'suspended' : 'active';
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(next == 'suspended' ? l.accountSuspend : l.accountRestore),
      content: Text('${widget.target}\n\n${l.accountStateHelp}\n\n${_reason.text.trim()}'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.continueLabel))]));
    if (confirmed != true || !mounted || !sameSession) { return; }
    setState(() { _busy = true; _failed = false; });
    try {
      await ref.read(accountStateRepositoryProvider).change(widget.target, _status, next, _reason.text.trim());
      if (mounted && sameSession) { setState(() { _status = next; _reason.clear(); }); }
    } catch (_) { if (mounted) { setState(() => _failed = true); } }
    finally { if (mounted) { setState(() => _busy = false); } }
    if (mounted && sameSession && !_failed) { await _load(); }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final actor = ref.watch(authProvider).asData?.value?.id;
    final access = ref.watch(memberAccessProvider);
    Widget body;
    if (_actor == null || actor != _actor) { body = Text(l.contactSessionChanged); }
    else if (access.isLoading) { body = const CircularProgressIndicator(); }
    else if (access.asData?.value != true) { body = Text(l.adminAccessDenied); }
    else {
      body = ListView(padding: const EdgeInsets.all(20), children: [
        Text(l.accountStateHelp), SelectableText(widget.target),
        Text(_status == 'active' ? l.adminActive : _status == 'suspended' ? l.adminSuspended : l.kycUnknownStatus),
        if (widget.target != actor && ['active', 'suspended'].contains(_status)) ...[
          TextField(controller: _reason, enabled: !_busy, maxLength: 1000, maxLines: 3,
            onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l.reviewReason)),
          FilledButton(onPressed: !_busy && _reason.text.trim().length >= 3 ? _change : null,
            child: Text(_status == 'active' ? l.accountSuspend : l.accountRestore)),
        ],
        if (_busy) const LinearProgressIndicator(),
        if (_failed) Text(l.accountStateFailed),
        OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
        Text(l.accountStateHistory),
        for (final row in _history) Builder(builder: (context) {
          Map details = {};
          try { details = jsonDecode(row['description'] as String? ?? '{}') as Map; } catch (_) { /* Legacy text is not exposed. */ }
          final date = DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
          final stamp = date == null ? '—' : '${MaterialLocalizations.of(context).formatMediumDate(date)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
          return Card(child: ListTile(title: Text(row['action'] == 'account.suspend' ? l.accountSuspend : l.accountRestore),
            subtitle: Text('$stamp\n${l.accountStateActor}: ${row['actor_id']}\n${details['reason'] ?? ''}')));
        }),
      ]);
    }
    return Scaffold(appBar: AppBar(title: Text(l.accountStateTitle)),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: body)));
  }
}
