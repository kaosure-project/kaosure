import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../application/services/access_refresh.dart';
import '../../data/repositories/supabase_staff_repository.dart';
import '../../domain/entities/staff_grant_request.dart';
import '../widgets/admin/grant_request_card.dart';
import '../widgets/admin_display.dart';

/// Role requests for second approvers: another Owner or a Legal & security admin.
class GrantApprovalsPage extends ConsumerStatefulWidget {
  const GrantApprovalsPage({super.key});

  @override
  ConsumerState<GrantApprovalsPage> createState() => _GrantApprovalsPageState();
}

class _GrantApprovalsPageState extends ConsumerState<GrantApprovalsPage>
    with WidgetsBindingObserver, AccessRefresh<GrantApprovalsPage> {
  @override
  void refreshAccess() { _load(); }

  final _reason = TextEditingController();
  List<StaffGrantRequest>? _queue;
  String? _owner;
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _same => mounted && _owner != null && ref.read(authProvider).asData?.value?.id == _owner;

  Future<void> _load() async {
    if (!_same || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final rows = await ref.read(staffRepositoryProvider).grantQueue();
      if (_same) setState(() => _queue = staffGrantsFrom(rows));
    } catch (e) {
      if (_same) setState(() { _queue = null; _error = e; });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(StaffGrantRequest grant, bool approve) async {
    if (_busy || !_same) return;
    final l = AppLocalizations.of(context);
    _reason.clear();
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(approve ? l.staffGrantApprove : l.staffGrantReject),
      content: Consumer(builder: (context, ref, _) {
        if (ref.watch(authProvider).asData?.value?.id != _owner) return Text(l.contactSessionChanged);
        return SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${realValue(grant.targetName)}\n${realValue(grant.targetCode)}\n'
                '${staffRoleLabel(l, grant.roleCode, grant.roleName)}'),
            TextField(key: const ValueKey('grant-reason'), controller: _reason, maxLength: 1000,
              decoration: InputDecoration(labelText: l.staffGrantReason)),
          ],
        ));
      }),
      actions: [
        TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.continueLabel)),
      ],
    ));
    if (confirmed != true || !_same) return;
    final reason = _reason.text.trim();
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(staffRepositoryProvider).decideGrant(grant.id, approve, reason.isEmpty ? null : reason);
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    ref.invalidate(staffToolsProvider);
    if (_same && _error == null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).asData?.value?.id;
    if (_owner == null || user != _owner) {
      return Scaffold(appBar: AppBar(title: Text(l.staffGrantsTitle)), body: Center(child: Text(l.contactSessionChanged)));
    }
    final queue = _queue;
    return Scaffold(
      appBar: AppBar(title: Text(l.staffGrantsTitle)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.grantApprovalsHelp),
          OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(staffErrorText(l, _error), key: const ValueKey('grant-error')),
          if (queue != null && queue.isEmpty) Text(l.staffEmpty),
          for (final grant in queue ?? const <StaffGrantRequest>[])
            GrantRequestCard(grant: grant, onDecide: _busy ? null : (approve) => _decide(grant, approve)),
        ]),
      ))),
    );
  }
}
