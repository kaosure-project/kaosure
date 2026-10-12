import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../domain/entities/app_client.dart';
import '../../domain/entities/sso_app.dart';
import '../utils/sso_texts.dart';

/// Register or edit a registry entry. Saves through [onSave] so server errors
/// stay in the dialog; pops `true` once saved.
class AppClientFormDialog extends StatefulWidget {
  const AppClientFormDialog({super.key, required this.onSave, this.initial});

  final AppClient? initial;
  final Future<void> Function(AppClientDraft draft) onSave;

  @override
  State<AppClientFormDialog> createState() => _AppClientFormDialogState();
}

class _AppClientFormDialogState extends State<AppClientFormDialog> {
  late final AppClientDraft? _initial = widget.initial?.toDraft();
  late final _code = TextEditingController(text: _initial?.appCode);
  late final _clientId = TextEditingController(text: _initial?.clientId);
  late final _name = TextEditingController(text: _initial?.displayName);
  late final _rpcs = TextEditingController(text: _initial?.rpcs.join('\n'));
  late final _tables = TextEditingController(text: _initial?.tables.join('\n'));
  late bool _firstParty = _initial?.firstParty ?? true;
  late final Set<SsoClaim> _claims = {...?_initial?.claims};
  bool _showErrors = false;
  bool _saving = false;
  String? _failure;

  @override
  void dispose() {
    for (final controller in [_code, _clientId, _name, _rpcs, _tables]) {
      controller.dispose();
    }
    super.dispose();
  }

  AppClientDraft get _draft => AppClientDraft(
        appCode: _code.text,
        clientId: _clientId.text,
        displayName: _name.text,
        firstParty: _firstParty,
        claims: _claims,
        rpcs: AppClientDraft.parseNames(_rpcs.text),
        tables: AppClientDraft.parseNames(_tables.text),
      );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final draft = _draft;
    if (!draft.isValid) {
      setState(() { _showErrors = true; _failure = l10n.ssoErrorInvalidClient; });
      return;
    }
    setState(() { _saving = true; _failure = null; });
    try {
      await widget.onSave(draft);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() { _saving = false; _failure = l10n.ssoFailureMessage(ssoFailureCodeOf(error)); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final invalid = _showErrors ? _draft.invalidFields : const <AppClientField>{};
    final editing = widget.initial != null;

    InputDecoration decoration(String label, String help, AppClientField field) => InputDecoration(
          labelText: label,
          helperText: help,
          helperMaxLines: 3,
          errorText: invalid.contains(field) ? help : null,
          errorMaxLines: 3,
          border: const OutlineInputBorder(),
        );

    Widget gap() => const SizedBox(height: 16);

    return AlertDialog(
      title: Text(editing ? l10n.ssoAppEdit : l10n.ssoAppRegister),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('sso-app-code'),
              controller: _code,
              enabled: !editing && !_saving,
              decoration: decoration(l10n.ssoAppCode, l10n.ssoAppCodeHelp, AppClientField.appCode),
              onChanged: (_) => setState(() {}),
            ),
            gap(),
            TextField(
              key: const Key('sso-app-client-id'),
              controller: _clientId,
              enabled: !_saving,
              decoration: decoration(l10n.ssoAppClientId, l10n.ssoAppClientIdHelp, AppClientField.clientId),
              onChanged: (_) => setState(() {}),
            ),
            gap(),
            TextField(
              key: const Key('sso-app-name'),
              controller: _name,
              enabled: !_saving,
              decoration: decoration(l10n.ssoAppName, l10n.ssoAppNameHelp, AppClientField.displayName),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('sso-app-first-party'),
              contentPadding: EdgeInsets.zero,
              value: _firstParty,
              onChanged: _saving ? null : (value) => setState(() => _firstParty = value),
              title: Text(l10n.ssoFirstParty),
              subtitle: Text(l10n.ssoAppFirstPartyHelp),
            ),
            const SizedBox(height: 8),
            Text(l10n.ssoAppClaims, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final claim in SsoClaim.values)
              CheckboxListTile(
                key: Key('sso-app-claim-${claim.name}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                value: _claims.contains(claim),
                onChanged: _saving ? null : (checked) => setState(() =>
                    checked == true ? _claims.add(claim) : _claims.remove(claim)),
                title: Text(l10n.ssoClaimLabel(claim)),
              ),
            gap(),
            TextField(
              key: const Key('sso-app-rpcs'),
              controller: _rpcs,
              enabled: !_saving,
              minLines: 2,
              maxLines: 6,
              decoration: decoration(l10n.ssoAppAllowedRpcs, l10n.ssoAppNamesHelp, AppClientField.rpcs),
              onChanged: (_) => setState(() {}),
            ),
            gap(),
            TextField(
              key: const Key('sso-app-tables'),
              controller: _tables,
              enabled: !_saving,
              minLines: 2,
              maxLines: 6,
              decoration: decoration(l10n.ssoAppAllowedTables, l10n.ssoAppTablesHelp, AppClientField.tables),
              onChanged: (_) => setState(() {}),
            ),
            if (_failure case final failure?) ...[
              gap(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.kaoDangerSoft,
                  borderRadius: BorderRadius.circular(8)),
                child: Text(failure, style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ],
        )),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('sso-app-save'),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.save),
        ),
      ],
    );
  }
}
