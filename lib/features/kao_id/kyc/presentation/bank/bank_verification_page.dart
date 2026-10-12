import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../domain/entities/bank_account.dart';
import '../../data/repositories/supabase_bank_repository.dart';
import '../../domain/failures/national_id_failure.dart';
import '../../domain/entities/id_image.dart';
import '../../application/providers/id_image_picker_provider.dart';
import '../widgets/kyc_status_label.dart';

final class BankVerificationPage extends ConsumerStatefulWidget {
  const BankVerificationPage({super.key});
  @override
  ConsumerState<BankVerificationPage> createState() => _BankVerificationPageState();
}
final class _BankVerificationPageState extends ConsumerState<BankVerificationPage> {
  final _form = GlobalKey<FormState>();
  final _bank = TextEditingController(), _name = TextEditingController();
  final _number = TextEditingController(), _branch = TextEditingController();
  List<BankRecord> _records = [];
  BankDraft? _attempt;
  IdImage? _evidence;
  String? _owner, _error;
  String _type = 'savings';
  bool _busy = false, _known = false, _adding = false, _validate = false;
  bool _sessionChanged = false;
  bool get _pending => _records.any((r) => r.pending);
  @override
  void initState() { super.initState(); Future.microtask(_load); }
  @override
  void dispose() {
    _bank.dispose(); _name.dispose(); _number.dispose(); _branch.dispose();
    super.dispose();
  }
  void _clearForm() {
    _attempt = null; _evidence = null; _validate = false; _adding = false;
    _bank.clear(); _name.clear(); _number.clear(); _branch.clear();
  }
  bool _sameUser(String owner) => !_sessionChanged &&
      ref.read(authProvider).asData?.value?.id == owner;
  Future<void> _load() async {
    if (!mounted || _busy || _sessionChanged) { return; }
    setState(() { _busy = true; _known = false; _records = []; _error = null; });
    try {
      final repo = ref.read(bankRepositoryProvider);
      final owner = await repo.owner();
      if (_owner != null && _owner != owner) { throw const NationalIdFailure('session'); }
      final records = await repo.list(owner);
      if (!mounted) { return; }
      if (!_sameUser(owner)) { throw const NationalIdFailure('session'); }
      setState(() {
        _owner = owner; _records = records; _known = true;
        if (_pending || records.any((r) => r.id == _attempt?.id)) { _clearForm(); }
      });
    } catch (e) { _fail(e is NationalIdFailure ? e.code : 'load'); }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  void _fail(String code) {
    if (!mounted || _sessionChanged) { return; }
    setState(() {
      _error = code;
      if (code == 'session') { _sessionChanged = true; _records = []; _clearForm(); }
    });
  }
  String _message(AppLocalizations l, String code) => switch (code) {
    'session' => l.contactSessionChanged,
    'load' => l.contactLoadFailed,
    'file' => l.idFileInvalid,
    'preview' => l.idPreviewFailed,
    'pending' => l.bankPendingHelp,
    'duplicate' => l.bankDuplicate,
    'form' => l.bankCompleteForm,
    'invalid' => l.bankErrorInvalid,
    'evidence_missing' => l.bankErrorEvidenceMissing,
    'upload_denied' => l.bankErrorUploadDenied,
    'upload_network' => l.bankErrorUploadNetwork,
    'sign_in' => l.bankErrorSignIn,
    'inactive' => l.bankErrorInactive,
    'conflict' => l.bankErrorConflict,
    'unavailable' => l.bankErrorUnavailable,
    _ => l.idSaveFailed,
  };
  /// Failures where resending the same draft cannot succeed, so the form is reopened.
  static const _needsNewAttempt = {'file', 'invalid', 'evidence_missing', 'conflict', 'duplicate'};
  static const _needsNewEvidence = {'file', 'evidence_missing'};
  Future<void> _pick() async {
    setState(() { _busy = true; _error = null; });
    try {
      final image = await ref.read(nationalIdImagePickerProvider)();
      if (!mounted || _sessionChanged) { return; }
      if (!_sameUser(_owner!)) { _fail('session'); return; }
      if (image != null) { setState(() => _evidence = image); }
    } catch (_) { _fail('file'); }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _save() async {
    if (_busy || !_known || _owner == null || _sessionChanged || _pending) { return; }
    if (_attempt == null) {
      setState(() { _validate = true; _error = null; });
      if (!_form.currentState!.validate()) { _fail('form'); return; }
      if (_evidence == null) { return; }
      _attempt = BankDraft(id: const Uuid().v4(), owner: _owner!, bank: _bank.text.trim(),
        name: _name.text.trim(), number: _number.text.trim(), branch: _branch.text.trim(),
        type: _type, evidence: _evidence!);
    }
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    try {
      final record = await ref.read(bankRepositoryProvider).submit(_attempt!);
      if (!mounted) { return; }
      if (!_sameUser(_owner!)) { _fail('session'); return; }
      setState(() { _records = [record, ..._records.where((r) => r.id != record.id)]; _clearForm(); });
    } catch (e) {
      final code = e is NationalIdFailure ? e.code : 'save';
      if (mounted && _needsNewAttempt.contains(code)) {
        setState(() {
          _attempt = null;
          if (_needsNewEvidence.contains(code)) { _evidence = null; }
        });
      }
      _fail(code);
    }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _preview(String path) async {
    setState(() { _busy = true; _error = null; });
    try {
      final bytes = await ref.read(bankRepositoryProvider).preview(_owner!, path);
      if (!mounted || _sessionChanged) { return; }
      if (!_sameUser(_owner!)) { _fail('session'); return; }
      // Loading ends when the download completes, not when the viewer closes.
      setState(() => _busy = false);
      final l = AppLocalizations.of(context);
      await showDialog<void>(context: context, builder: (c) => AlertDialog(
        title: Text(l.bankEvidence),
        content: SizedBox(width: 600, height: 400, child: Consumer(builder: (context, ref, child) {
          if (_sessionChanged || ref.watch(authProvider).asData?.value?.id != _owner) {
            return Text(l.contactSessionChanged);
          }
          return InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain,
            errorBuilder: (_, error, stack) => Text(l.idPreviewFailed)));
        })),
        actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(l.back))],
      ));
    } catch (_) { _fail('preview'); }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (_owner != null && next.asData?.value?.id != _owner) {
        setState(() { _sessionChanged = true; _records = []; _clearForm(); });
      }
    });
    final l = AppLocalizations.of(context);
    if (_sessionChanged) {
      return Scaffold(appBar: AppBar(title: Text(l.kycBankAccount)),
        body: Center(child: Text(l.contactSessionChanged)));
    }
    final editable = !_busy && _attempt == null;
    Widget field(String key, TextEditingController controller, String label, int max,
        {bool optional = false, bool number = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 16), child: TextFormField(
        key: ValueKey(key), controller: controller, enabled: editable, maxLength: max,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (!optional && text.isEmpty) { return l.passportRequired; }
          if (number && !RegExp(r'^[0-9]{6,20}$').hasMatch(text)) { return l.bankNumberInvalid; }
          if ((key == 'bank-name' && text.length < 2) || RegExp(r'[\x00-\x1F\x7F]').hasMatch(text)) {
            return l.bankCompleteForm;
          }
          return null;
        },
      ));
    Widget error() => Semantics(liveRegion: true, child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_message(l, _error!),
        style: TextStyle(color: Theme.of(context).colorScheme.error))));
    return PopScope(canPop: !_busy, child: Scaffold(appBar: AppBar(title: Text(l.kycBankAccount)),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
        child: Form(key: _form, autovalidateMode: _validate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text(l.bankSubmissionIntro), const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            OutlinedButton(key: const ValueKey('bank-refresh'), onPressed: _busy ? null : _load,
              child: Text(l.authCheckAgain)),
            if (_error != null && (!_known || !_adding || _pending)) error(),
            if (_known && _records.isEmpty && !_adding) Text(l.bankNoAccounts),
            for (final record in _records) Card(child: Padding(padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(record.data['bank_name'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium),
                Text(record.maskedNumber),
                Text(record.data['account_name'] as String? ?? ''),
                if (record.data['account_type'] == 'savings' || record.data['account_type'] == 'current')
                  Text(record.data['account_type'] == 'savings' ? l.bankSavings : l.bankCurrent),
                if ((record.data['branch_name'] as String? ?? '').isNotEmpty)
                  Text(record.data['branch_name'] as String),
                Text(kycStatusLabel(l, record.status)),
                if (record.pending) Text(l.bankPendingHelp),
                if (record.status == 'rejected' || record.status == 'expired') Text(l.bankResubmitHelp),
                if (record.evidence != null) TextButton(key: ValueKey('bank-view-${record.id}'),
                  onPressed: _busy ? null : () => _preview(record.evidence!), child: Text(l.bankViewEvidence)),
              ]))),
            if (_known && !_pending && !_adding) FilledButton(key: const ValueKey('bank-add'),
              onPressed: _busy ? null : () => setState(() { _adding = true; _error = null; }),
              child: Text(l.bankAddAccount)),
            if (_known && !_pending && _adding) ...[
              const SizedBox(height: 20),
              field('bank-name', _bank, l.bankInstitutionName, 100),
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l.bankHolderProfileHint,
                key: const ValueKey('bank-holder-hint'), style: Theme.of(context).textTheme.bodySmall)),
              field('bank-holder', _name, l.bankHolderName, 200),
              field('bank-number', _number, l.bankAccountNumber, 20, number: true),
              field('bank-branch', _branch, l.bankBranchOptional, 100, optional: true),
              Text(l.bankAccountType),
              Wrap(spacing: 12, children: [
                ChoiceChip(label: Text(l.bankSavings), selected: _type == 'savings',
                  onSelected: editable ? (_) => setState(() => _type = 'savings') : null),
                ChoiceChip(label: Text(l.bankCurrent), selected: _type == 'current',
                  onSelected: editable ? (_) => setState(() => _type = 'current') : null),
              ]),
              const SizedBox(height: 16), Text(l.bankEvidenceHelp), Text(l.idFileHelp),
              if (_evidence != null) ...[Image.memory(_evidence!.bytes, height: 160), Text(_evidence!.name)],
              OutlinedButton(key: const ValueKey('bank-pick'), onPressed: editable ? _pick : null,
                child: Text(l.kycChooseFile)),
              if (_validate && _evidence == null) Text(l.bankEvidenceRequired),
              if (_error != null) error(),
              if (_attempt != null) Text(l.bankRetryHelp),
              FilledButton(key: const ValueKey('bank-submit'), onPressed: _busy ? null : _save,
                child: Text(_attempt == null ? l.bankSubmitReview : l.idRetrySubmission)),
              if (_attempt == null) TextButton(onPressed: _busy ? null : () => setState(_clearForm),
                child: Text(l.back)),
            ],
          ]),
        ),
      ))),
    ));
  }
}
