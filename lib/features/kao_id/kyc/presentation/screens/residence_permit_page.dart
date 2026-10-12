import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../domain/failures/national_id_failure.dart';
import '../../domain/entities/id_image.dart';
import '../../application/providers/id_image_picker_provider.dart';
import '../../domain/entities/residence.dart';
import '../../data/repositories/supabase_residence_repository.dart';
import '../widgets/kyc_status_label.dart';

final class ResidencePermitPage extends ConsumerStatefulWidget {
  const ResidencePermitPage({super.key});
  @override
  ConsumerState<ResidencePermitPage> createState() => _ResidencePermitPageState();
}
final class _ResidencePermitPageState extends ConsumerState<ResidencePermitPage> {
  final _form = GlobalKey<FormState>();
  final _given = TextEditingController(), _family = TextEditingController();
  final _number = TextEditingController(), _country = TextEditingController();
  DateTime? _issued, _expiry;
  IdImage? _front, _back;
  bool _card = true, _noExpiry = false;
  ResidenceRecord? _record;
  ResidenceDraft? _attempt;
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
      final repo = ref.read(residenceRepositoryProvider);
      final owner = await repo.owner();
      if (_owner != null && _owner != owner) { throw const NationalIdFailure('session'); }
      final record = await repo.latest(owner);
      final pending = await repo.hasPendingRequest(owner);
      if (!mounted || _sessionChanged) { return; }
      setState(() {
        _owner = owner; _record = record; _pending = pending; _known = true;
        if (record?.id == _attempt?.id && record != null) {
          _attempt = null; _front = null; _back = null;
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
    'pending' => l.residenceOtherPending,
    'form' => l.residenceCompleteForm,
    _ => l.idSaveFailed,
  };
  void _fail(String code) {
    if (!mounted || _sessionChanged) { return; }
    setState(() => _error = code);
  }
  Future<void> _pick(bool front) async {
    setState(() { _busy = true; _error = null; });
    try {
      final selected = await ref.read(nationalIdImagePickerProvider)();
      if (mounted && !_sessionChanged && selected != null) { setState(() { if (front) { _front = selected; } else { _back = selected; } }); }
    } catch (_) { _fail('file'); }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _date(String field) async {
    final now = DateTime.now(), l = AppLocalizations.of(context);
    final today = DateTime(now.year, now.month, now.day);
    final current = field == 'issued' ? _issued : _expiry;
    final date = await showDatePicker(context: context,
      helpText: field == 'issued' ? l.kycIssueDate : l.kycExpiryDate,
      initialDate: current ?? today, firstDate: field == 'expiry' ? today : DateTime(1900),
      lastDate: field == 'expiry' ? DateTime(today.year + 30) : today);
    if (!mounted || _sessionChanged || date == null) { return; }
    setState(() {
      if (field == 'issued') { _issued = date; } else { _expiry = date; }
    });
  }
  Future<void> _save() async {
    if (_busy || !_known || _owner == null || _sessionChanged) { return; }
    if (_attempt == null) {
      setState(() => _validate = true);
      final fieldsValid = _form.currentState!.validate();
      if (!fieldsValid || _issued == null ||
          (!_noExpiry && (_expiry == null || !_expiry!.isAfter(_issued!))) ||
          _front == null || (_card && _back == null)) {
        _fail('form'); return;
      }
      _attempt = ResidenceDraft(id: const Uuid().v4(), owner: _owner!,
        number: _number.text.trim(), given: _given.text.trim(),
        family: _single ? '' : _family.text.trim(), singleName: _single,
        familyFirst: _single ? false : _familyFirst, country: _country.text.trim(),
        format: _card ? 'card' : 'paper', noExpiry: _noExpiry,
        issued: _issued!, expiry: _noExpiry ? null : _expiry, front: _front!, back: _card ? _back : null);
    }
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    try {
      final result = await ref.read(residenceRepositoryProvider).submit(_attempt!);
      if (mounted && !_sessionChanged) {
        setState(() { _record = result; _pending = true; _attempt = null; _front = null; _back = null; });
        _given.clear(); _family.clear(); _number.clear(); _country.clear();
      }
    } catch (e) { _fail(e is NationalIdFailure ? e.code : 'save'); }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _preview(String path) async {
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(residenceRepositoryProvider).preview(_owner!, path);
      if (!mounted || _sessionChanged) { return; }
      final l = AppLocalizations.of(context);
      await showDialog<void>(context: context, builder: (c) => AlertDialog(
        title: Text(l.kycResidencePermit),
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
          _sessionChanged = true; _record = null; _attempt = null; _front = null; _back = null;
          _given.clear(); _family.clear(); _number.clear(); _country.clear();
        });
      }
    });
    final l = AppLocalizations.of(context);
    if (_sessionChanged) { return Scaffold(appBar: AppBar(title: Text(l.kycResidencePermit)), body: Center(child: Text(l.contactSessionChanged))); }
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
          if (key == 'residence-country' && value.trim().length < 2) { return l.passportCountryInvalid; }
          return null;
        },
      ));
    Widget dateButton(String key, String label, DateTime? value) => OutlinedButton(
      key: ValueKey('residence-$key'), onPressed: editable ? () => _date(key) : null,
      child: Text('$label: ${date(value)}'));
    Widget picker(bool front) {
      final image = front ? _front : _back;
      return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(front ? (_card ? l.residenceFront : l.residencePage) : l.residenceBack),
          if (image != null) ...[Image.memory(image.bytes, height: 160), Text(image.name)],
          OutlinedButton(key: ValueKey(front ? 'residence-front' : 'residence-back'),
            onPressed: editable ? () => _pick(front) : null, child: Text(l.kycChooseFile)),
          if (_validate && image == null) Text(l.residenceImageRequired),
        ])));
    }
    return PopScope(canPop: !_busy, child: Scaffold(appBar: AppBar(title: Text(l.kycResidencePermit)),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
        child: Form(key: _form, autovalidateMode: _validate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text(l.residenceIntro), const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null && !showForm) Semantics(liveRegion: true, child: Text(_message(l, _error!))),
            OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
            if (_known && _record == null) Text(l.kycNoDocumentSubmitted),
            if (_record != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(kycStatusLabel(l, _record!.status)),
                if (_record!.data['full_name'] != null) Text(_record!.data['full_name'] as String),
                if (_record!.data['issuing_country'] != null) Text('${l.residenceIssuingCountry}: ${_record!.data['issuing_country']}'),
                Text('${l.kycExpiryDate}: ${_record!.data['no_expiry'] == true ? l.residenceNoExpiry : date(_record!.expiry)}'),
                if (_record!.rejection?.isNotEmpty == true) Text(_record!.rejection!),
                for (final path in _record!.paths) TextButton(onPressed: _busy ? null : () => _preview(path), child: Text(path.endsWith('/back.jpg') ? l.residenceViewBack : l.residenceViewFront)),
                if (const {'pending', 'pending_review', 'under_review', 'submitted'}.contains(_record!.status))
                  Text(l.residencePendingHelp),
              ]))),
            if (_known && _pending && (_record == null || _record!.canResubmit)) Text(l.residenceOtherPending),
            if (showForm) ...[
              const SizedBox(height: 16),
              SwitchListTile(key: const ValueKey('residence-card'), value: _card,
                onChanged: editable ? (v) => setState(() => _card = v) : null,
                title: Text(l.residenceCardFormat), subtitle: Text(_card ? l.residenceTwoSides : l.residenceOnePage)),
              CheckboxListTile(key: const ValueKey('residence-single'), value: _single,
                onChanged: editable ? (v) => setState(() => _single = v ?? false) : null,
                title: Text(l.residenceSingleName)),
              field('residence-given', _given, _single ? l.residenceOnlyName : l.passportGiven, 100),
              if (!_single) field('residence-family', _family, l.passportFamily, 100),
              if (!_single) CheckboxListTile(value: _familyFirst,
                onChanged: editable ? (v) => setState(() => _familyFirst = v ?? false) : null,
                title: Text(l.passportFamilyFirst)),
              field('residence-number', _number, l.residenceNumber, 30),
              field('residence-country', _country, l.residenceIssuingCountry, 100),
              dateButton('issued', l.kycIssueDate, _issued),
              CheckboxListTile(key: const ValueKey('residence-no-expiry'), value: _noExpiry,
                onChanged: editable ? (v) => setState(() => _noExpiry = v ?? false) : null,
                title: Text(l.residenceNoExpiry)),
              if (!_noExpiry) dateButton('expiry', l.kycExpiryDate, _expiry),
              if (_validate && (_issued == null || (!_noExpiry && (_expiry == null ||
                (_issued != null && !_expiry!.isAfter(_issued!)))))) Text(l.residenceDatesInvalid),
              const SizedBox(height: 16),
              Text(l.idFileHelp),
              picker(true),
              if (_card) picker(false),
              const SizedBox(height: 16),
              if (_error != null) Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(liveRegion: true, child: Text(_message(l, _error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error)))),
              if (_busy) Text(l.idSubmitting),
              FilledButton(key: const ValueKey('residence-submit'), onPressed: _busy ? null : _save,
                child: Text(_attempt == null ? l.residenceSubmit : l.idRetrySubmission)),
            ],
          ]),
        ),
      ))),
    ));
  }
}
