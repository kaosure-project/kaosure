import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/services/access_refresh.dart';
import '../../data/repositories/supabase_staff_repository.dart';
import '../../domain/entities/staff_role.dart';
import '../widgets/admin/permission_toggle_list.dart';
import '../widgets/admin_display.dart';

/// Owner-only: create custom roles and choose which permissions each role carries.
class RoleEditorPage extends ConsumerStatefulWidget {
  const RoleEditorPage({super.key});

  @override
  ConsumerState<RoleEditorPage> createState() => _RoleEditorPageState();
}

class _RoleEditorPageState extends ConsumerState<RoleEditorPage>
    with WidgetsBindingObserver, AccessRefresh<RoleEditorPage> {
  @override
  void refreshAccess() { _load(); }

  final _code = TextEditingController(text: 'custom_');
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _editName = TextEditingController();
  final _editDescription = TextEditingController();
  Map<String, dynamic>? _data;
  String? _owner, _selected;
  bool _active = true;
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
    for (final controller in [_code, _name, _description, _editName, _editDescription]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _same => mounted && _owner != null && ref.read(authProvider).asData?.value?.id == _owner;

  Future<void> _load() async {
    if (!_same || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final data = await ref.read(staffRepositoryProvider).load();
      if (_same) setState(() { _data = data; _select(_selected); });
    } catch (e) {
      if (_same) setState(() { _data = null; _error = e; });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _select(String? code) {
    final role = staffRolesFrom(_data).where((r) => r.code == code && r.editable).firstOrNull;
    _selected = role?.code;
    _editName.text = role?.name ?? '';
    _editDescription.text = role?.description ?? '';
    _active = role?.isActive ?? true;
  }

  Future<void> _run(Future<void> Function() action, {String? select}) async {
    if (_busy || !_same) return;
    setState(() { _busy = true; _error = null; });
    try {
      await action();
      if (select != null) _selected = select;
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_same && _error == null) await _load();
  }

  Future<void> _create() {
    final code = _code.text.trim();
    final description = _description.text.trim();
    return _run(() async {
      await ref.read(staffRepositoryProvider).createRole(code, _name.text.trim(), description.isEmpty ? null : description);
      _code.text = 'custom_';
      _name.clear();
      _description.clear();
    }, select: code);
  }

  Future<void> _save(StaffRole role) {
    final description = _editDescription.text.trim();
    return _run(() => ref.read(staffRepositoryProvider)
        .updateRole(role.code, _editName.text.trim(), description.isEmpty ? null : description, _active));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).asData?.value?.id;
    if (_owner == null || user != _owner) {
      return Scaffold(appBar: AppBar(title: Text(l.staffRolesTitle)), body: Center(child: Text(l.contactSessionChanged)));
    }
    final roles = staffRolesFrom(_data).where((r) => r.editable).toList();
    final catalogue = staffCatalogueFrom(_data);
    final role = roles.where((r) => r.code == _selected).firstOrNull;
    final validNew = RegExp(r'^custom_[a-z0-9_]{2,40}$').hasMatch(_code.text.trim())
        && _name.text.trim().length >= 2;
    return Scaffold(
      appBar: AppBar(title: Text(l.staffRolesTitle)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.staffRolesHelp),
          OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(staffErrorText(l, _error), key: const ValueKey('role-error')),
          if (_data != null) ...[
            DropdownButton<String>(
              key: const ValueKey('role-select'),
              isExpanded: true,
              value: role?.code,
              hint: Text(l.staffRole),
              items: [
                for (final r in roles)
                  DropdownMenuItem(value: r.code, child: Text(
                    '${staffRoleLabel(l, r.code, r.name)} · ${r.isSystem ? l.staffSystemRole : l.staffCustomRole}')),
              ],
              onChanged: _busy ? null : (code) => setState(() => _select(code)),
            ),
            if (role != null) AdminSection(title: staffRoleLabel(l, role.code, role.name), children: [
              Text(role.isSystem ? l.staffSystemRole : l.staffCustomRole),
              SelectableText(role.code),
              AdminValue(label: l.staffHolders, value: role.holders),
              if (role.holders > 0) Text(l.staffRoleInUse),
              if (role.custom) ...[
                TextField(key: const ValueKey('role-edit-name'), controller: _editName, enabled: !_busy, maxLength: 60,
                  decoration: InputDecoration(labelText: l.staffRoleName)),
                TextField(key: const ValueKey('role-edit-description'), controller: _editDescription, enabled: !_busy,
                  maxLength: 300, decoration: InputDecoration(labelText: l.staffRoleDescription)),
                SwitchListTile(key: const ValueKey('role-active'), contentPadding: EdgeInsets.zero,
                  value: _active, title: Text(l.adminActive),
                  onChanged: _busy ? null : (v) => setState(() => _active = v)),
                FilledButton(key: const ValueKey('role-save'), onPressed: _busy ? null : () => _save(role),
                  child: Text(l.staffRoleSave)),
              ],
              const SizedBox(height: 12),
              Text(l.staffPermissions, style: Theme.of(context).textTheme.titleSmall),
              PermissionToggleList(
                catalogue: catalogue,
                enabled: role.permissions,
                onChanged: _busy ? null : (permission, enabled) =>
                    _run(() => ref.read(staffRepositoryProvider).setPermission(role.code, permission.code, enabled)),
              ),
            ]),
            AdminSection(title: l.staffRoleCreate, children: [
              TextField(key: const ValueKey('role-code'), controller: _code, enabled: !_busy, maxLength: 47,
                onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l.staffRoleCode)),
              TextField(key: const ValueKey('role-name'), controller: _name, enabled: !_busy, maxLength: 60,
                onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l.staffRoleName)),
              TextField(key: const ValueKey('role-description'), controller: _description, enabled: !_busy,
                maxLength: 300, decoration: InputDecoration(labelText: l.staffRoleDescription)),
              FilledButton(key: const ValueKey('role-create'), onPressed: !_busy && validNew ? _create : null,
                child: Text(l.staffRoleCreate)),
            ]),
          ],
        ]),
      ))),
    );
  }
}
