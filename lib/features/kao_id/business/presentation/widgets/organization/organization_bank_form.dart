import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../domain/entities/organization_bank_draft.dart';

typedef SubmitOrganizationBank =
    Future<bool> Function({
      required String bankName,
      required String accountName,
      required String accountNumber,
      required String branch,
      required OrganizationBankAccountType type,
      required Uint8List evidenceJpeg,
    });

/// Company bank account form; the account name must match the company's legal name.
class OrganizationBankForm extends StatefulWidget {
  const OrganizationBankForm({
    super.key,
    required this.legalName,
    required this.legalNameEn,
    required this.busy,
    required this.onPickEvidence,
    required this.onSubmit,
    required this.onCancel,
  });

  final String legalName;
  final String? legalNameEn;
  final bool busy;
  final Future<Uint8List?> Function() onPickEvidence;
  final SubmitOrganizationBank onSubmit;
  final VoidCallback onCancel;

  @override
  State<OrganizationBankForm> createState() => _OrganizationBankFormState();
}

class _OrganizationBankFormState extends State<OrganizationBankForm> {
  final _formKey = GlobalKey<FormState>();
  final _bank = TextEditingController();
  late final _name = TextEditingController(text: widget.legalName);
  final _number = TextEditingController();
  final _branch = TextEditingController();
  var _type = OrganizationBankAccountType.current;
  Uint8List? _evidence;
  bool _validate = false;

  @override
  void dispose() {
    _bank.dispose();
    _name.dispose();
    _number.dispose();
    _branch.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final bytes = await widget.onPickEvidence();
    if (bytes != null && mounted) setState(() => _evidence = bytes);
  }

  Future<void> _submit() async {
    setState(() => _validate = true);
    if (!_formKey.currentState!.validate() || _evidence == null) return;
    FocusScope.of(context).unfocus();
    await widget.onSubmit(
      bankName: _bank.text,
      accountName: _name.text,
      accountNumber: _number.text,
      branch: _branch.text,
      type: _type,
      evidenceJpeg: _evidence!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final enabled = !widget.busy;
    final control = RegExp(r'[\x00-\x1F\x7F]');
    String? text(String? value, {int min = 1}) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.length < min || control.hasMatch(trimmed)) return l10n.bankCompleteForm;
      return null;
    }

    final names = [widget.legalName, if (widget.legalNameEn != null) widget.legalNameEn!].join(' / ');
    return Form(
      key: _formKey,
      autovalidateMode: _validate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.businessOrgBankFormTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.businessOrgBankNameRule(names),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('org-bank-name'),
            controller: _bank,
            enabled: enabled,
            maxLength: 100,
            decoration: InputDecoration(labelText: l10n.bankInstitutionName, counterText: ''),
            validator: (value) => text(value, min: 2),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('org-bank-holder'),
            controller: _name,
            enabled: enabled,
            maxLength: 200,
            decoration: InputDecoration(labelText: l10n.businessOrgBankHolder, counterText: ''),
            validator: text,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('org-bank-number'),
            controller: _number,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(20)],
            decoration: InputDecoration(labelText: l10n.bankAccountNumber),
            validator: (value) =>
                RegExp(r'^[0-9]{6,20}$').hasMatch(value?.trim() ?? '') ? null : l10n.bankNumberInvalid,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('org-bank-branch'),
            controller: _branch,
            enabled: enabled,
            maxLength: 100,
            decoration: InputDecoration(labelText: l10n.bankBranchOptional, counterText: ''),
            validator: (value) => control.hasMatch(value ?? '') ? l10n.bankCompleteForm : null,
          ),
          const SizedBox(height: 12),
          Text(l10n.bankAccountType),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              ChoiceChip(
                label: Text(l10n.bankCurrent),
                selected: _type == OrganizationBankAccountType.current,
                onSelected: enabled ? (_) => setState(() => _type = OrganizationBankAccountType.current) : null,
              ),
              ChoiceChip(
                label: Text(l10n.bankSavings),
                selected: _type == OrganizationBankAccountType.savings,
                onSelected: enabled ? (_) => setState(() => _type = OrganizationBankAccountType.savings) : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.businessOrgBankEvidenceHelp, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          if (_evidence != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(_evidence!, height: 160, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            key: const ValueKey('org-bank-pick'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: enabled ? _pick : null,
            icon: const Icon(Icons.photo_outlined),
            label: Text(_evidence == null ? l10n.kycChooseFile : l10n.businessRegDocumentReplace),
          ),
          if (_validate && _evidence == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.bankEvidenceRequired, style: TextStyle(color: theme.colorScheme.error)),
            ),
          const SizedBox(height: 20),
          if (widget.busy) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator()),
          FilledButton(
            key: const ValueKey('org-bank-submit'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: enabled ? _submit : null,
            child: Text(l10n.bankSubmitReview),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: enabled ? widget.onCancel : null,
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
