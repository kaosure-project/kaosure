import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/features/kao_id/governance/data/repositories/supabase_owner_requests_repository.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/owner_request_detail_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../widgets/admin_display.dart';

String requestStatus(AppLocalizations l, String code) => switch (code) {
  'pending' => l.lifePending, 'cancelled' => l.lifeCancelled,
  'rejected' => l.lifeRejected, 'approved' => l.lifeApproved, _ => l.kycUnknownStatus,
};

class OwnerRequestsPage extends ConsumerStatefulWidget {
  const OwnerRequestsPage({super.key});
  @override
  ConsumerState<OwnerRequestsPage> createState() => _OwnerRequestsPageState();
}

class _OwnerRequestsPageState extends ConsumerState<OwnerRequestsPage> {
  String? _owner;
  String _status = 'pending';
  List<Map<String, dynamic>> _rows = [];
  bool _busy = false, _loaded = false, _more = false;
  Object? _error;
  bool get _same => mounted && _owner != null && ref.read(authProvider).asData?.value?.id == _owner;
  @override
  void initState() { super.initState(); _owner = ref.read(authProvider).asData?.value?.id; Future.microtask(_load); }
  Future<void> _load({bool more = false}) async {
    if (!_same || _busy) { return; }
    final cursor = more && _rows.isNotEmpty ? _rows.last : null;
    setState(() { _busy = true; _error = null; if (!more) { _rows = []; _loaded = false; _more = false; } });
    try {
      final rows = await ref.read(ownerRequestsRepositoryProvider).list(_status, cursor);
      if (_same) { setState(() { _rows = [..._rows, ...rows]; _more = rows.length == 30; _loaded = true; }); }
    } catch (e) { if (_same) { setState(() { _error = e; if (e is PostgrestException && e.code == '42501') { _rows = []; _more = false; _loaded = false; } }); } }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    final denied = _error is PostgrestException && (_error as PostgrestException).code == '42501';
    return Scaffold(appBar: AppBar(title: Text(l.ownerRequests)), body: SafeArea(child: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: !same
        ? Text(l.contactSessionChanged) : ListView(padding: const EdgeInsets.all(20), children: [
          AdminSection(title: l.ownerRequests, children: [Text(l.ownerRequestsHelp),
            const SizedBox(height: 16), Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in ['pending','cancelled','rejected','approved']) ChoiceChip(
                label: Text(requestStatus(l,s)), selected: _status == s,
                onSelected: _busy ? null : (_) { setState(() => _status = s); _load(); }),
            ]), OutlinedButton.icon(onPressed: _busy ? null : () => _load(),
              icon: const Icon(Icons.refresh), label: Text(l.authCheckAgain)),
          ]),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(denied ? l.adminAccessDenied : l.kycLoadFailed),
          if (_loaded && _rows.isEmpty) Text(l.staffEmpty),
          for (final row in _rows) Card(child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: const Icon(Icons.assignment_outlined),
            title: Text(realValue(row['display_name'])),
            subtitle: Text('${realValue(row['account_code'] ?? row['profile_id'])}\n${row['kind'] == 'closure' ? l.lifeClose : l.lifeRecover}\n${adminDate(context,row['created_at'])}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OwnerRequestDetail(row: row)));
              if (_same) { await _load(); }
            })),
          if (_more) OutlinedButton(onPressed: _busy ? null : () => _load(more: true), child: Text(l.adminMore)),
        ])))));
  }
}
