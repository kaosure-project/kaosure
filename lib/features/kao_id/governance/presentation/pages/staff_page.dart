import '../../application/services/access_refresh.dart';
import '../widgets/admin_display.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../data/repositories/supabase_member_repository.dart';
import '../../data/repositories/supabase_staff_repository.dart';
import '../../domain/entities/staff_grant_request.dart';
import '../../domain/entities/staff_role.dart';
import '../widgets/admin/grant_request_card.dart';
import 'role_editor_page.dart';

class StaffPage extends ConsumerStatefulWidget {
  const StaffPage({super.key});
  @override
  ConsumerState<StaffPage> createState() => _StaffPageState();
}
class _StaffPageState extends ConsumerState<StaffPage> with WidgetsBindingObserver, AccessRefresh<StaffPage> {
  @override
  void refreshAccess() { _load(); }
  final _query = TextEditingController();
  final _reason = TextEditingController();
  Map<String, dynamic>? _data, _target;
  String? _owner, _role;
  bool _busy = false;
  Object? _error;
  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(_load);
  }
  @override
  void dispose() { _query.dispose(); _reason.dispose(); super.dispose(); }
  bool get _same => mounted && _owner != null && ref.read(authProvider).asData?.value?.id == _owner;
  Future<void> _load() async {
    if (!_same || _busy) { return; }
    setState(() { _busy = true; _data = null; _error = null; });
    try {
      final data = await ref.read(staffRepositoryProvider).load();
      if (_same) { setState(() => _data = data); }
    } catch(e) { if (_same) { setState(() => _error = e); } }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _find() async {
    if (_busy || !_same) { return; }
    setState(() { _busy = true; _target = null; _error = null; });
    try {
      final member = await ref.read(memberRepositoryProvider).find(_query.text);
      if (_same) { setState(() { _target = member; if (member == null) { _error = StateError('target_unavailable'); } }); }
    } catch(e) { if (_same) { setState(() => _error = e); } }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _run(Future<void> Function() action) async {
    setState(() { _busy = true; _error = null; });
    try { await action(); }
    catch(e) { if (_same) { setState(() => _error = e); } }
    finally { if (mounted) { setState(() => _busy = false); } }
    if (_same && _error == null) { await _load(); }
  }
  Future<bool> _confirm(String title, String body, {TextEditingController? reason}) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(title),
      content: Consumer(builder: (context, ref, _) {
        if (ref.watch(authProvider).asData?.value?.id != _owner) { return Text(l.contactSessionChanged); }
        return SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(body),
          if (reason != null) TextField(key: const ValueKey('grant-reason'), controller: reason, maxLength: 1000,
            decoration: InputDecoration(labelText: l.staffGrantReason)),
        ]));
      }),
      actions: [TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.continueLabel))]));
    return confirmed == true && _same;
  }
  Future<void> _change({Map<String,dynamic>? assignment}) async {
    if (_busy || !_same) { return; }
    final target = assignment ?? _target;
    if (target == null || (assignment == null && _role == null)) { return; }
    final l = AppLocalizations.of(context);
    final role = assignment?['code'] as String? ?? _role!;
    final id = assignment?['profile_id'] ?? target['id'];
    final label = staffRoleLabel(l, role, assignment?['role_name'] as String?
      ?? staffRolesFrom(_data).where((r) => r.code == role).firstOrNull?.name);
    if (!await _confirm(assignment == null ? l.staffAssign : l.staffRevoke,
        '${target['display_name'] ?? ''}\n$id\n$label\n\n${l.staffConfirm}')) { return; }
    await _run(() async {
      final repo = ref.read(staffRepositoryProvider);
      if (assignment == null) { await repo.assign(target['id'] as String, role); }
      else { await repo.revoke(assignment['id'] as String); }
      if (_same) { setState(() { _target = null; _role = null; }); }
    });
  }
  Future<void> _cancelGrant(StaffGrantRequest grant) async {
    if (_busy || !_same) { return; }
    final l = AppLocalizations.of(context);
    if (!await _confirm(l.staffGrantCancel,
        '${realValue(grant.targetName)}\n${staffRoleLabel(l, grant.roleCode, grant.roleName)}')) { return; }
    await _run(() => ref.read(staffRepositoryProvider).cancelGrant(grant.id));
  }
  Future<void> _decideGrant(StaffGrantRequest grant, bool approve) async {
    if (_busy || !_same) { return; }
    final l = AppLocalizations.of(context);
    _reason.clear();
    if (!await _confirm(approve ? l.staffGrantApprove : l.staffGrantReject,
        '${realValue(grant.targetName)}\n${staffRoleLabel(l, grant.roleCode, grant.roleName)}', reason: _reason)) { return; }
    final text = _reason.text.trim();
    await _run(() => ref.read(staffRepositoryProvider).decideGrant(grant.id, approve, text.isEmpty ? null : text));
  }
  Future<void> _openRoles() async {
    if (_busy || !_same) { return; }
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RoleEditorPage()));
    if (_same) { await _load(); }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).asData?.value?.id;
    if (_owner == null || user != _owner) {
      return Scaffold(appBar: AppBar(title: Text(l.staffTitle)), body: Center(child: Text(l.contactSessionChanged)));
    }
    final roles = staffRolesFrom(_data);
    final catalogue = {for (final p in staffCatalogueFrom(_data)) p.code: p};
    final rows = (_data?['assignments'] as List? ?? []).cast<Map>();
    final grants = staffGrantsFrom(_data?['grants'] as List?);
    final history = (_data?['history'] as List? ?? []).cast<Map>();
    String date(dynamic value) => adminDate(context, value);
    final selected = roles.where((r) => r.code == _role).firstOrNull;
    final permissions = [...?selected?.permissions]..sort();
    return Scaffold(appBar: AppBar(title: Text(l.staffTitle)), body: SafeArea(child: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: ListView(
        padding: const EdgeInsets.all(20), children: [
          Text(l.staffHelp),
          OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(staffErrorText(l, _error)),
          if (_data != null) ...[
            OutlinedButton.icon(key: const ValueKey('staff-roles'), onPressed: _busy ? null : _openRoles,
              icon: const Icon(Icons.tune_outlined), label: Text(l.staffRolesTitle)),
            TextField(controller: _query, enabled: !_busy, maxLength: 254,
              onChanged: (_) => setState(() => _target = null),
              decoration: InputDecoration(labelText: '${l.adminSearchHint} / ${l.adminAccountCode}')),
            OutlinedButton(onPressed: !_busy && _query.text.trim().length >= 3 ? _find : null, child: Text(l.adminSearch)),
            if (_target != null) ...[
              SelectableText('${_target!['display_name'] ?? ''}\n${_target!['email'] ?? ''}\n${_target!['id']}'),
              DropdownButton<String>(isExpanded: true, value: _role, hint: Text(l.staffRole),
                items: [for(final role in roles) if (role.isActive) DropdownMenuItem(value: role.code,
                  child: Text(staffRoleLabel(l, role.code, role.name)))],
                onChanged: _busy ? null : (v) => setState(() => _role = v)),
              if (_role != null) ...[Text(l.staffPermissions),
                for(final code in permissions) Text(catalogue[code]?.dangerous == true
                  ? '${catalogue[code]!.name} · ${l.staffPermissionDangerous}' : catalogue[code]?.name ?? code),
                if (_role == 'kaoid_admin') Text(l.staffKaoidMfaScope)],
              FilledButton(onPressed: !_busy && _role != null ? () => _change() : null, child: Text(l.staffAssign)),
            ],
            const SizedBox(height: 24), Text(l.staffGrantsTitle, style: Theme.of(context).textTheme.titleMedium),
            Text(l.staffGrantHelp),
            if (grants.isEmpty) Text(l.staffEmpty),
            for (final grant in grants) GrantRequestCard(grant: grant,
              onCancel: grant.pending && !_busy ? () => _cancelGrant(grant) : null,
              onDecide: _busy ? null : (approve) => _decideGrant(grant, approve)),
            const SizedBox(height: 24), Text(l.staffAssignments),
            if(rows.isEmpty) Text(l.staffEmpty),
            for(final row in rows) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(realValue(row['display_name']), style: Theme.of(context).textTheme.titleMedium),
                AdminValue(label:l.adminAccountCode,value:row['account_code'],copyable:true),
                SelectableText(row['profile_id'] as String),
                Text(staffRoleLabel(l,row['code'] as String,row['role_name'] as String?)),
                Text(row['currently_assigned'] == true ? l.adminActive : l.staffInactive),
                if (row['scheduled'] == true) AdminValue(label: l.staffStartsAt, value: date(row['starts_at'])),
                if (row['needs_mfa'] == true) Text(l.staffNeedsMfa),
                Text('${l.kycExpiryDate}: ${row['expires_at'] == null ? l.staffNoExpiry : date(row['expires_at'])}'),
                if(row['is_active'] == true) TextButton(onPressed: _busy ? null : () => _change(assignment: Map<String,dynamic>.from(row)),child: Text(l.staffRevoke)),
              ]))),
            const SizedBox(height: 24), Text(l.staffHistory), Text(l.staffLatest),
            if(history.isEmpty) Text(l.staffEmpty),
            for(final item in history) Builder(builder: (context) {
              Map details = {};
              try { details = jsonDecode(item['description'] as String? ?? '{}') as Map; } catch (_) { /* Legacy entry. */ }
              final role = details['role'];
              return Card(child: Padding(padding: const EdgeInsets.all(16),child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(staffActionLabel(l, item['action'] as String?)),
                  if (role is String) Text(staffRoleLabel(l, role, details['name'] as String?)),
                  if (details['permission'] is String)
                    Text('${details['enabled'] == false ? '−' : '+'} ${details['permission']}'),
                  if (item['action'] == 'governance.grant.reject') AdminValue(label: l.staffGrantReason, value: details['reason']),
                  AdminValue(label:l.displayName,value:item['target_name']),
                  AdminValue(label:l.adminAccountCode,value:item['target_code'],copyable:true),
                  SelectableText('${l.adminUserId}: ${details['target_profile_id'] ?? '—'}'),
                  AdminValue(label:l.staffActor,value:'${realValue(item['actor_name_at_event'])}\n${realValue(item['actor_code'] ?? item['profile_id'])}',copyable:true),
                  AdminValue(label:l.adminActorRole,value:adminRoles(l,item['actor_roles_at_event'])),
                  Text(date(item['created_at'])),
                ])));
            }),
          ],
        ])))));
  }
}
