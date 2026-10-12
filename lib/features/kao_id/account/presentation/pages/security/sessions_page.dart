import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/features/kao_id/account/data/repositories/supabase_sessions_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../../governance/shared/admin_display.dart';
import '../../../data/repositories/supabase_account_access_repository.dart';

class SessionsPage extends ConsumerStatefulWidget {
  const SessionsPage({super.key});
  @override
  ConsumerState<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends ConsumerState<SessionsPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _rows = [];
  bool _busy = true, _failed = false;
  String? _user;
  int _generation = 0;
  StreamSubscription<void>? _subscription;
  bool get _same => _user != null && _user == ref.read(accountAccessRepositoryProvider).userId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _user = ref.read(accountAccessRepositoryProvider).userId;
    _subscription = ref.read(accountAccessRepositoryProvider).changes.listen((_) {
      if (mounted && !_same) { _generation++; setState(() { _rows = []; _busy = false; }); }
    });
    unawaited(_load());
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _same) { unawaited(_load()); }
  }
  Future<void> _load() async {
    final generation = ++_generation;
    if (!_same) { if (mounted) { setState(() => _busy = false); } return; }
    setState(() { _busy = true; _failed = false; _rows = []; });
    try {
      final rows = await ref.read(sessionsRepositoryProvider).list();
      if (mounted && _same && generation == _generation) { setState(() => _rows = rows); }
    } catch (_) {
      if (mounted && _same && generation == _generation) { setState(() => _failed = true); }
    } finally {
      if (mounted && generation == _generation) { setState(() => _busy = false); }
    }
  }
  Future<void> _revoke(String? id, {bool others = false}) async {
    final l = AppLocalizations.of(context);
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(l.sessionRevoke), content: Text(l.sessionConfirm), actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.continueLabel)),
      ]));
    if (!mounted || !_same || yes != true) { return; }
    setState(() => _busy = true);
    try {
      await ref.read(sessionsRepositoryProvider).revoke(id, others: others, expectedUser: _user!);
      if (mounted && _same) { await _load(); }
    } catch (_) {
      if (mounted && _same) { setState(() { _failed = true; _rows = []; _busy = false; }); }
    }
  }
  @override
  void dispose() { _generation++; _subscription?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(appBar: AppBar(title: Text(l.sessionTitle)), body: SafeArea(child: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: ListView(
        padding: const EdgeInsets.all(20), children: [
          Text(l.sessionHelp), const SizedBox(height: 16),
          if (!_same) Text(l.contactSessionChanged)
          else if (_busy) const LinearProgressIndicator()
          else if (_failed) ...[Text(l.kycLoadFailed), OutlinedButton(onPressed: _load, child: Text(l.retry))]
          else ...[
            OutlinedButton(onPressed: _load, child: Text(l.authCheckAgain)),
            if (_rows.any((r) => r['current_session'] != true))
              FilledButton(onPressed: () => _revoke(null, others: true), child: Text(l.sessionOthers)),
            if (_rows.isEmpty) Text(l.adminSearchEmpty),
            for (final row in _rows) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (row['current_session'] == true) Text(l.sessionCurrent, style: Theme.of(context).textTheme.titleMedium),
                SelectableText(realValue(row['user_agent'])),
                const SizedBox(height: 8),
                Text('${l.sessionStarted}: ${adminDate(context, row['created_at'])}'),
                Text('${l.sessionRefreshed}: ${adminDate(context, row['refreshed_at'])}'),
                SelectableText('IP: ${realValue(row['ip'])}'),
                if (row['current_session'] != true) OutlinedButton(
                  onPressed: () => _revoke(row['id'] as String), child: Text(l.sessionRevoke)),
              ]))),
          ],
        ])))));
  }
}
