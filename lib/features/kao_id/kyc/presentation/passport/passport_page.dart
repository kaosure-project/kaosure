import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../domain/failures/national_id_failure.dart';
import '../../domain/entities/id_image.dart';
import '../../application/providers/id_image_picker_provider.dart';
import '../../domain/entities/passport.dart';
import '../../data/repositories/supabase_passport_repository.dart';
import '../widgets/kyc_status_label.dart';

final class PassportPage extends ConsumerStatefulWidget {
  const PassportPage({super.key});
  @override
  ConsumerState<PassportPage> createState() => _PassportPageState();
}
final class _PassportPageState extends ConsumerState<PassportPage> {
  final _form = GlobalKey<FormState>();
  final _given = TextEditingController(), _family = TextEditingController();
  final _number = TextEditingController(), _country = TextEditingController();
  DateTime? _birth, _issued, _expiry;
  IdImage? _image;
  PassportRecord? _record;
  PassportDraft? _attempt;
  String? _owner, _error;
  bool _busy = false, _known = false, _pending = false;
  bool _single = false, _familyFirst = false, _validate = false;
  bool _sessionChanged = false;

  @override
  void initState() { super.initState(); Future.microtask(_load); }
  @override
  void dispose() {
    _given.dispose(); _family.dispose(); _number.dispose(); _country.dispose();
    super.dispose();
  }
  Future<void> _load() async {
    if (!mounted || _busy || _sessionChanged) { return; }
    setState(() { _busy = true; _error = null; _known = false; });
    try {
      final repo = ref.read(passportRepositoryProvider);
      final owner = await repo.owner();
      if (_owner != null && _owner != owner) { throw const NationalIdFailure('session'); }
      final record = await repo.latest(owner);
      final pending = await repo.hasPendingRequest(owner);
      if (!mounted || _sessionChanged) { return; }
      setState(() {
        _owner = owner; _record = record; _pending = pending; _known = true;
        if (record?.id == _attempt?.id && record != null) {
          _attempt = null; _image = null;
        }
      });
    } catch (e) {
      if (mounted) { setState(() { _error = e is NationalIdFailure ? e.code : 'load'; _record = null; }); }
    } finally { if (mounted) { setState(() => _busy = false); } }
  }
  String _message(AppLocalizations l, String code) => switch (code) {
    'session' => l.contactSessionChanged,
    'load' => l.contactLoadFailed,
    'file' => l.idFileInvalid,
    'preview' => l.idPreviewFailed,
    'pending' => l.passportOtherPending,
    'form' => l.passportCompleteForm,
    _ => l.idSaveFailed,
  };
  void _fail(String code) {
    if (!mounted || _sessionChanged) { return; }
    setState(() => _error = code);
  }
  Future<void> _pick() async {
    setState(() { _busy = true; _error = null; });
    try {
      final selected = await ref.read(nationalIdImagePickerProvider)();
      if (mounted && !_sessionChanged && selected != null) { setState(() => _image = selected); }
    } catch (_) { _fail('file'); }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _date(String field) async {
    final now = DateTime.now(), l = AppLocalizations.of(context);
    final today = DateTime(now.year, now.month, now.day);
    final current = switch(field) { 'birth' => _birth, 'issued' => _issued, _ => _expiry };
    final date = await showDatePicker(context: context,
      helpText: field == 'birth' ? l.passportBirth : field == 'issued' ? l.kycIssueDate : l.kycExpiryDate,
      initialDate: current ?? today, firstDate: field == 'expiry' ? today : DateTime(1900),
      lastDate: field == 'expiry' ? DateTime(today.year + 30) : today);
    if (!mounted || _sessionChanged || date == null) { return; }
    setState(() {
      if (field == 'birth') { _birth = date; }
      else if (field == 'issued') { _issued = date; } else { _expiry = date; }
    });
  }
  Future<void> _save() async {
    if (_busy || !_known || _owner == null || _sessionChanged) { return; }
    if (_attempt == null) {
      setState(() => _validate = true);
      final fieldsValid = _form.currentState!.validate();
      if (!fieldsValid || _birth == null || _issued == null || _expiry == null ||
          _issued!.isBefore(_birth!) || !_expiry!.isAfter(_issued!) || _image == null) {
        _fail('form'); return;
      }
      _attempt = PassportDraft(id: const Uuid().v4(), owner: _owner!,
        number: _number.text.trim(), given: _given.text.trim(),
        family: _single ? '' : _family.text.trim(), singleName: _single,
        familyFirst: _single ? false : _familyFirst, country: _country.text.trim(),
        birth: _birth!, issued: _issued!, expiry: _expiry!, image: _image!);
    }
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    try {
      final result = await ref.read(passportRepositoryProvider).submit(_attempt!);
      if (mounted && !_sessionChanged) {
        setState(() { _record = result; _pending = true; _attempt = null; _image = null; });
        _given.clear(); _family.clear(); _number.clear(); _country.clear();
      }
    } catch (e) { _fail(e is NationalIdFailure ? e.code : 'save'); }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _preview(String path) async {
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(passportRepositoryProvider).preview(_owner!, path);
      if (!mounted || _sessionChanged) { return; }
      final l = AppLocalizations.of(context);
      await showDialog<void>(context: context, builder: (c) => AlertDialog(
        title: Text(l.kycPassportDocument),
        content: SizedBox(width: 600, height: 400, child: Consumer(builder: (context, ref, child) {
          final current = ref.watch(authProvider).asData?.value?.id;
          if (_sessionChanged || current != _owner) { return Text(l.contactSessionChanged); }
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
      final previousId = previous?.asData?.value?.id;
      final nextId = next.asData?.value?.id;
      if (_owner != null && (previousId == _owner || nextId != null) && nextId != _owner) {
        setState(() {
          _sessionChanged = true; _record = null; _attempt = null; _image = null;
          _given.clear(); _family.clear(); _number.clear(); _country.clear();
        });
      }
    });
    final l = AppLocalizations.of(context);
    if (_sessionChanged) { return Scaffold(appBar: AppBar(title: Text(l.kycPassport)), body: Center(child: Text(l.contactSessionChanged))); }
    final editable = !_busy && _attempt == null;
    final showForm = _known && !_pending && (_record == null || _record!.canResubmit);
    String date(DateTime? d) => d == null ? l.kycSelectDate : MaterialLocalizations.of(context).formatMediumDate(d);
    Widget field(String key, TextEditingController controller, String label, int max) => Padding(
      padding: const EdgeInsets.only(bottom: 16), child: TextFormField(
        key: ValueKey(key), controller: controller, enabled: editable, maxLength: max,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          if (value == null || value.trim().isEmpty) { return l.passportRequired; }
          if (key == 'passport-country' && value.trim().length < 2) { return l.passportCountryInvalid; }
          return null;
        },
      ));
    Widget dateButton(String key, String label, DateTime? value) => OutlinedButton(
      key: ValueKey('passport-$key'), onPressed: editable ? () => _date(key) : null,
      child: Text('$label: ${date(value)}'));
    return PopScope(canPop: !_busy, child: Scaffold(appBar: AppBar(title: Text(l.kycPassport)),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
        child: Form(key: _form, autovalidateMode: _validate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text(l.passportIntro), const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null && !showForm) Semantics(liveRegion: true, child: Text(_message(l, _error!))),
            OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
            if (_known && _record == null) Text(l.kycNoDocumentSubmitted),
            if (_record != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(kycStatusLabel(l, _record!.status)),
                if (_record!.data['full_name'] != null) Text(_record!.data['full_name'] as String),
                Text('${l.kycExpiryDate}: ${date(_record!.expiry)}'),
                if (_record!.rejection?.isNotEmpty == true) Text(_record!.rejection!),
                for (final path in _record!.paths) TextButton(onPressed: _busy ? null : () => _preview(path), child: Text(l.idViewDocument)),
                if (const {'pending', 'pending_review', 'under_review', 'submitted'}.contains(_record!.status))
                  Text(l.passportPendingHelp),
              ]))),
            if (_known && _pending && (_record == null || _record!.canResubmit)) Text(l.passportOtherPending),
            if (showForm) ...[
              const SizedBox(height: 16),
              CheckboxListTile(key: const ValueKey('passport-single'), value: _single,
                onChanged: editable ? (v) => setState(() => _single = v ?? false) : null,
                title: Text(l.passportSingleName)),
              field('passport-given', _given, _single ? l.passportOnlyName : l.passportGiven, 100),
              if (!_single) field('passport-family', _family, l.passportFamily, 100),
              if (!_single) CheckboxListTile(value: _familyFirst,
                onChanged: editable ? (v) => setState(() => _familyFirst = v ?? false) : null,
                title: Text(l.passportFamilyFirst)),
              field('passport-number', _number, l.kycPassportNumber, 30),
              field('passport-country', _country, l.passportIssuingCountry, 100),
              dateButton('birth', l.passportBirth, _birth),
              dateButton('issued', l.kycIssueDate, _issued),
              dateButton('expiry', l.kycExpiryDate, _expiry),
              if (_validate && (_birth == null || _issued == null || _expiry == null ||
                (_issued != null && _birth != null && _issued!.isBefore(_birth!)) ||
                (_expiry != null && _issued != null && !_expiry!.isAfter(_issued!)))) Text(l.passportDatesInvalid),
              const SizedBox(height: 16),
              Text(l.kycPassportDocument), Text(l.idFileHelp),
              if (_image != null) ...[Image.memory(_image!.bytes, height: 180), Text(_image!.name)],
              OutlinedButton(key: const ValueKey('passport-image'), onPressed: editable ? _pick : null, child: Text(l.kycChooseFile)),
              if (_validate && _image == null) Text(l.kycSelectAPassportImage),
              const SizedBox(height: 16),
              if (_error != null) Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(liveRegion: true, child: Text(_message(l, _error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error)))),
              if (_busy) Text(l.idSubmitting),
              FilledButton(key: const ValueKey('passport-submit'), onPressed: _busy ? null : _save,
                child: Text(_attempt == null ? l.passportSubmit : l.idRetrySubmission)),
            ],
          ]),
        ),
      ))),
    ));
  }
}
