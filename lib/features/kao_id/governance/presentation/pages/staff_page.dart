import '../../application/services/access_refresh.dart';
import '../widgets/admin_display.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../data/repositories/supabase_member_repository.dart';
import '../../data/repositories/supabase_staff_repository.dart';

String staffRoleLabel(AppLocalizations l, String code) => switch (code) {
  'admin' => l.staffAdmin, 'super_admin' => l.staffSuperAdmin,
  'support' => l.staffSupport, 'kyc_officer' => l.staffReviewer,
  _ => l.kycUnknownStatus,
};
class StaffPage extends ConsumerStatefulWidget {
  const StaffPage({super.key});
  @override
  ConsumerState<StaffPage> createState() => _StaffPageState();
}
class _StaffPageState extends ConsumerState<StaffPage> with WidgetsBindingObserver, AccessRefresh<StaffPage> {
  @override
  void refreshAccess() { _load(); }
  final _query = TextEditingController();
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
  void dispose() { _query.dispose(); super.dispose(); }
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
  Future<void> _change({Map<String,dynamic>? assignment}) async {
    if (_busy || !_same) { return; }
    final target = assignment ?? _target;
    if (target == null || (assignment == null && _role == null)) { return; }
    final l = AppLocalizations.of(context);
    final role = assignment?['code'] as String? ?? _role!;
    final id = assignment?['profile_id'] ?? target['id'];
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(assignment == null ? l.staffAssign : l.staffRevoke),
      content: Consumer(builder: (context, ref, _) {
        if (ref.watch(authProvider).asData?.value?.id != _owner) { return Text(l.contactSessionChanged); }
        return SingleChildScrollView(child: Text('${target['display_name'] ?? ''}\n$id\n${staffRoleLabel(l, role)}\n\n${l.staffConfirm}'));
      }),
      actions: [TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.continueLabel))]));
    if (confirmed != true || !_same) { return; }
    setState(() { _busy = true; _error = null; });
    try {
      final repo = ref.read(staffRepositoryProvider);
      if (assignment == null) { await repo.assign(target['id'] as String, role); }
      else { await repo.revoke(assignment['id'] as String); }
      if (_same) { setState(() { _target = null; _role = null; }); }
    } catch(e) { if (_same) { setState(() => _error = e); } }
    finally { if (mounted) { setState(() => _busy = false); } }
    if (_same && _error == null) { await _load(); }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).asData?.value?.id;
    if (_owner == null || user != _owner) {
      return Scaffold(appBar: AppBar(title: Text(l.staffTitle)), body: Center(child: Text(l.contactSessionChanged)));
    }
    final roles = (_data?['roles'] as List? ?? []).cast<Map>();
    final rows = (_data?['assignments'] as List? ?? []).cast<Map>();
    final history = (_data?['history'] as List? ?? []).cast<Map>();
    String error() {
      final code = _error is PostgrestException ? (_error as PostgrestException).message
        : _error is StateError ? (_error as StateError).message : '';
      return switch(code) {
        'mfa_required' => l.mfaSessionRequired,
        'owner_required' => l.adminAccessDenied,
        'target_kyc_required' => l.staffKycRequired,
        'target_unavailable' || 'owner_role_protected' => l.staffTargetInvalid,
        _ => l.reviewActionFailed,
      };
    }
    String date(dynamic value) => adminDate(context, value);
    final permissions = [for(final role in roles) if(role['code']==_role) ...(role['permissions'] as List? ?? [])];
    return Scaffold(appBar: AppBar(title: Text(l.staffTitle)), body: SafeArea(child: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: ListView(
        padding: const EdgeInsets.all(20), children: [
          Text(l.staffHelp),
          OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(error()),
          if (_data != null) ...[
            TextField(controller: _query, enabled: !_busy, maxLength: 254,
              onChanged: (_) => setState(() => _target = null),
              decoration: InputDecoration(labelText: '${l.adminSearchHint} / ${l.adminAccountCode}')),
            OutlinedButton(onPressed: !_busy && _query.text.trim().length >= 3 ? _find : null, child: Text(l.adminSearch)),
            if (_target != null) ...[
              SelectableText('${_target!['display_name'] ?? ''}\n${_target!['email'] ?? ''}\n${_target!['id']}'),
              DropdownButton<String>(isExpanded: true, value: _role, hint: Text(l.staffRole),
                items: [for(final role in roles) DropdownMenuItem(value: role['code'] as String,
                  child: Text(staffRoleLabel(l, role['code'] as String)))],
                onChanged: _busy ? null : (v) => setState(() => _role = v)),
              if (_role != null) ...[Text(l.staffPermissions),
                for(final permission in permissions) Text(permission.toString()),
                if (_role == 'kyc_officer') Text(l.staffReviewScope)],
              FilledButton(onPressed: !_busy && _role != null ? () => _change() : null, child: Text(l.staffAssign)),
            ],
            const SizedBox(height: 24), Text(l.staffAssignments),
            if(rows.isEmpty) Text(l.staffEmpty),
            for(final row in rows) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(realValue(row['display_name']), style: Theme.of(context).textTheme.titleMedium),
                AdminValue(label:l.adminAccountCode,value:row['account_code'],copyable:true),
                SelectableText(row['profile_id'] as String),
                Text(staffRoleLabel(l,row['code'] as String)),
                Text(row['currently_assigned'] == true ? l.adminActive : l.staffInactive),
                Text('${l.kycExpiryDate}: ${row['expires_at'] == null ? l.staffNoExpiry : date(row['expires_at'])}'),
                if(row['is_active'] == true) TextButton(onPressed: _busy ? null : () => _change(assignment: Map<String,dynamic>.from(row)),child: Text(l.staffRevoke)),
              ]))),
            const SizedBox(height: 24), Text(l.staffHistory), Text(l.staffLatest),
            if(history.isEmpty) Text(l.staffEmpty),
            for(final item in history) Builder(builder: (context) {
              Map details = {};
              try { details = jsonDecode(item['description'] as String? ?? '{}') as Map; } catch (_) { /* Legacy entry. */ }
              return Card(child: Padding(padding: const EdgeInsets.all(16),child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['action']=='governance.role.assign' ? l.staffAssign : l.staffRevoke),
                  Text(staffRoleLabel(l,details['role'] as String? ?? '')),
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
