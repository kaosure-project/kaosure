import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../domain/entities/system_content_item.dart';
import '../widgets/admin_display.dart';
import 'system_content_editor_page.dart';

String contentCategoryText(AppLocalizations l, String category) => switch (category) {
  'help' => l.contentsCategoryHelp,
  'guide' => l.contentsCategoryGuide,
  'rule' => l.contentsCategoryRule,
  'warning' => l.contentsCategoryWarning,
  'terms' => l.contentsCategoryTerms,
  'notice' => l.contentsCategoryNotice,
  _ => category,
};

String contentAppText(AppLocalizations l, String app) => app == 'common' ? l.contentsCommon : app;

/// The server's answers for content tools, in the staff member's language.
String contentErrorText(AppLocalizations l, Object error) {
  final message = error is PostgrestException ? error.message : error.toString();
  for (final (code, text) in [
    ('content_changed', l.contentsErrorChanged),
    ('content_not_found', l.contentsErrorChanged),
    ('content_key_taken', l.contentsErrorKeyTaken),
    ('content_key_locked', l.contentsErrorKey),
    ('invalid_content_key', l.contentsErrorKey),
    ('content_thai_required', l.contentsErrorThai),
    ('content_too_long', l.contentsErrorTooLong),
    ('invalid_content', l.contentsErrorInvalid),
    ('content_access_denied', l.staffToolDenied),
  ]) {
    if (message.contains(code)) return text;
  }
  if (error is PostgrestException && error.code == '42501') return l.staffToolDenied;
  return l.staffActionFailed;
}

/// "ศูนย์จัดการข้อความและข้อตกลง": guidance, rules, warnings, terms and help
/// that apps read from `public.system_contents` instead of shipping in code.
class SystemContentsPage extends ConsumerStatefulWidget {
  const SystemContentsPage({super.key});

  @override
  ConsumerState<SystemContentsPage> createState() => _SystemContentsPageState();
}

class _SystemContentsPageState extends ConsumerState<SystemContentsPage> {
  String? _owner;
  String? _app;
  List<SystemContentItem> _rows = [];
  bool _busy = false, _loaded = false;
  Object? _error;

  bool get _same => mounted && _owner != null && ref.read(authProvider).asData?.value?.id == _owner;

  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!_same || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await ref.read(systemContentRepositoryProvider).list(app: _app);
      if (_same) {
        setState(() {
          _rows = rows;
          _loaded = true;
        });
      }
    } catch (e) {
      if (_same) {
        setState(() {
          _error = e;
          _rows = [];
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([SystemContentItem? item]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SystemContentEditorPage(initial: item, app: _app),
      ),
    );
    if (saved == true && _same) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    return Scaffold(
      appBar: AppBar(title: Text(l.contentsTitle)),
      floatingActionButton: same && _loaded
          ? FloatingActionButton.extended(
              key: const ValueKey('contents-add'),
              onPressed: _busy ? null : () => _edit(),
              icon: const Icon(Icons.add),
              label: Text(l.contentsAdd),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: !same
                ? Text(l.contactSessionChanged)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    children: [
                      AdminSection(
                        title: l.contentsTitle,
                        children: [
                          Text(l.contentsHelp),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final app in <String?>[null, ...SystemContentItem.apps])
                                ChoiceChip(
                                  key: ValueKey('contents-app-${app ?? 'all'}'),
                                  label: Text(app == null ? l.contentsAllApps : contentAppText(l, app)),
                                  selected: _app == app,
                                  onSelected: _busy
                                      ? null
                                      : (_) {
                                          setState(() => _app = app);
                                          _load();
                                        },
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (_busy) const LinearProgressIndicator(),
                      if (_error case final error?) Text(contentErrorText(l, error)),
                      if (_loaded && _rows.isEmpty) Text(l.staffEmpty),
                      for (final item in _rows)
                        Card(
                          key: ValueKey('content-${item.key}'),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            title: Text(item.title['th'] ?? item.key),
                            subtitle: Text(
                              [
                                item.key,
                                '${contentAppText(l, item.app)} · ${contentCategoryText(l, item.category)}'
                                    ' · ${l.contentsVersion(item.version ?? 1)}',
                                if (item.updatedAt != null)
                                  '${adminDate(context, item.updatedAt!.toIso8601String())}'
                                      '${item.updatedByName == null ? '' : ' · ${item.updatedByName}'}',
                              ].join('\n'),
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!item.isActive)
                                  Chip(label: Text(l.contentsHidden), visualDensity: VisualDensity.compact),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: _busy ? null : () => _edit(item),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
