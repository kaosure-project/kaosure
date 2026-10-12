import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../domain/entities/system_content_item.dart';
import 'system_contents_page.dart';

/// Adds or edits one content. Thai is required; English is shown to members
/// using English when it is filled in. Pops `true` after a save or delete.
class SystemContentEditorPage extends ConsumerStatefulWidget {
  const SystemContentEditorPage({super.key, this.initial, this.app});

  /// `null` to add a new content.
  final SystemContentItem? initial;

  /// The app picked in the list, used for a new content.
  final String? app;

  @override
  ConsumerState<SystemContentEditorPage> createState() => _SystemContentEditorPageState();
}

class _SystemContentEditorPageState extends ConsumerState<SystemContentEditorPage> {
  late final SystemContentItem? _initial = widget.initial;
  late final _key = TextEditingController(text: _initial?.key ?? '');
  late final _titleTh = TextEditingController(text: _initial?.title['th'] ?? '');
  late final _titleEn = TextEditingController(text: _initial?.title['en'] ?? '');
  late final _bodyTh = TextEditingController(text: _initial?.body['th'] ?? '');
  late final _bodyEn = TextEditingController(text: _initial?.body['en'] ?? '');
  late final _icon = TextEditingController(text: _initial?.icon ?? '');
  late final _sort = TextEditingController(text: '${_initial?.sortOrder ?? 0}');
  late String _app = _initial?.app ?? widget.app ?? SystemContentItem.apps.first;
  late String _category = _initial?.category ?? SystemContentItem.categories.first;
  late bool _active = _initial?.isActive ?? true;
  late String _role = SystemContentItem.presetRoles.contains(_initial?.presetRole)
      ? _initial!.presetRole!
      : SystemContentItem.presetRoles.first;
  String? _owner;
  Object? _error;
  bool _busy = false;

  bool get _same => mounted && _owner != null && ref.read(authProvider).asData?.value?.id == _owner;
  bool get _editing => _initial?.id != null;
  bool get _preset => _category == 'preset';

  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
  }

  @override
  void dispose() {
    for (final controller in [_key, _titleTh, _titleEn, _bodyTh, _bodyEn, _icon, _sort]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> _texts(TextEditingController th, TextEditingController en) => {
    'th': th.text.trim(),
    if (en.text.trim().isNotEmpty) 'en': en.text.trim(),
  };

  Future<void> _save() async {
    if (!_same || _busy) return;
    final icon = _icon.text.trim();
    final meta = {...?_initial?.meta}
      ..remove('icon')
      ..remove('role');
    if (icon.isNotEmpty) meta['icon'] = icon;
    if (_preset) meta['role'] = _role;
    final item = SystemContentItem(
      id: _initial?.id,
      key: _key.text.trim(),
      app: _app,
      category: _category,
      title: _texts(_titleTh, _titleEn),
      body: _texts(_bodyTh, _bodyEn),
      meta: meta,
      sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
      isActive: _active,
      version: _initial?.version,
    );
    await _run(() => ref.read(systemContentRepositoryProvider).save(item));
  }

  Future<void> _delete() async {
    final initial = _initial;
    if (initial?.id == null || !_same || _busy) return;
    final l = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.contentsDelete),
        content: Text(l.contentsDeleteConfirm(initial!.key)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(
            key: const ValueKey('content-delete-confirm'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.contentsDelete),
          ),
        ],
      ),
    );
    if (yes != true || !_same) return;
    await _run(() => ref.read(systemContentRepositoryProvider).delete(initial!.id!, initial.version ?? 1));
  }

  Future<void> _run(Future<Object?> Function() action) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await action();
      if (!_same) return;
      messenger.showSnackBar(
        SnackBar(content: Text(result is SystemContentItem ? l.contentsSaved : l.contentsDeleted)),
      );
      navigator.pop(true);
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    final ready = _key.text.trim().isNotEmpty && _titleTh.text.trim().isNotEmpty && _bodyTh.text.trim().isNotEmpty;
    InputDecoration field(String label, {String? helper}) =>
        InputDecoration(labelText: label, helperText: helper, helperMaxLines: 3, border: const OutlineInputBorder());
    Widget gap() => const SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? _initial!.key : l.contentsAdd)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: !same
                ? Text(l.contactSessionChanged)
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_busy) const LinearProgressIndicator(),
                      if (_error case final error?)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            contentErrorText(l, error),
                            key: const ValueKey('content-error'),
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      TextField(
                        key: const ValueKey('content-key'),
                        controller: _key,
                        enabled: !_busy && !_editing,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]'))],
                        onChanged: (_) => setState(() {}),
                        decoration: field(l.contentsKey, helper: l.contentsKeyHelp),
                      ),
                      gap(),
                      Wrap(
                        spacing: 16,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: 260,
                            child: KeyedSubtree(
                              key: ValueKey('content-app-$_app'),
                              child: DropdownButtonFormField<String>(
                                key: const ValueKey('content-app'),
                                initialValue: _app,
                                isExpanded: true,
                                decoration: field(l.contentsApp),
                                items: [
                                  for (final app in {...SystemContentItem.apps, _app})
                                    DropdownMenuItem(value: app, child: Text(contentAppText(l, app))),
                                ],
                                onChanged: _busy || _editing || _preset
                                    ? null
                                    : (value) => setState(() => _app = value ?? _app),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 260,
                            child: DropdownButtonFormField<String>(
                              key: const ValueKey('content-category'),
                              initialValue: _category,
                              isExpanded: true,
                              decoration: field(l.contentsCategory),
                              items: [
                                for (final category in SystemContentItem.categories)
                                  DropdownMenuItem(value: category, child: Text(contentCategoryText(l, category))),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) => setState(() {
                                      _category = value ?? _category;
                                      if (_preset && !_editing) _app = SystemContentItem.presetApp;
                                    }),
                            ),
                          ),
                          if (_preset)
                            SizedBox(
                              width: 260,
                              child: DropdownButtonFormField<String>(
                                key: const ValueKey('content-preset-role'),
                                initialValue: _role,
                                isExpanded: true,
                                decoration: field(l.contentsPresetRole),
                                items: [
                                  for (final role in SystemContentItem.presetRoles)
                                    DropdownMenuItem(value: role, child: Text(contentPresetRoleText(l, role))),
                                ],
                                onChanged: _busy ? null : (value) => setState(() => _role = value ?? _role),
                              ),
                            ),
                        ],
                      ),
                      gap(),
                      TextField(
                        key: const ValueKey('content-title-th'),
                        controller: _titleTh,
                        enabled: !_busy,
                        maxLength: 200,
                        onChanged: (_) => setState(() {}),
                        decoration: field(l.contentsTitleTh),
                      ),
                      gap(),
                      TextField(
                        key: const ValueKey('content-body-th'),
                        controller: _bodyTh,
                        enabled: !_busy,
                        minLines: 4,
                        maxLines: 14,
                        onChanged: (_) => setState(() {}),
                        maxLength: _preset ? 300 : null,
                        decoration: field(
                          l.contentsBodyTh,
                          helper: switch (_category) {
                            'notice' => l.contentsPlaceholderHelp,
                            'preset' => l.contentsPresetHelp,
                            _ => l.contentsBodyHelp,
                          },
                        ),
                      ),
                      gap(),
                      TextField(
                        key: const ValueKey('content-title-en'),
                        controller: _titleEn,
                        enabled: !_busy,
                        maxLength: 200,
                        decoration: field(l.contentsTitleEn),
                      ),
                      gap(),
                      TextField(
                        key: const ValueKey('content-body-en'),
                        controller: _bodyEn,
                        enabled: !_busy,
                        minLines: 4,
                        maxLines: 14,
                        maxLength: _preset ? 300 : null,
                        decoration: field(l.contentsBodyEn),
                      ),
                      gap(),
                      Wrap(
                        spacing: 16,
                        runSpacing: 14,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 260,
                            child: TextField(
                              key: const ValueKey('content-icon'),
                              controller: _icon,
                              enabled: !_busy,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]'))],
                              decoration: field(l.contentsIcon),
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              key: const ValueKey('content-sort'),
                              controller: _sort,
                              enabled: !_busy,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))],
                              decoration: field(l.contentsSort),
                            ),
                          ),
                          SizedBox(
                            width: 260,
                            child: SwitchListTile(
                              key: const ValueKey('content-active'),
                              value: _active,
                              title: Text(l.contentsActive),
                              onChanged: _busy ? null : (value) => setState(() => _active = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            key: const ValueKey('content-save'),
                            onPressed: !_busy && ready ? _save : null,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(l.save),
                          ),
                          if (_editing)
                            OutlinedButton.icon(
                              key: const ValueKey('content-delete'),
                              onPressed: _busy ? null : _delete,
                              icon: const Icon(Icons.delete_outline),
                              label: Text(l.contentsDelete),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
