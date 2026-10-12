import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/features/kao_id/account/data/repositories/supabase_recovery_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../../auth/application/providers/auth_provider.dart';
import '../../../../kyc/domain/entities/id_image.dart';
import '../../../../kyc/application/providers/id_image_picker_provider.dart';

class RecoveryEvidencePage extends ConsumerStatefulWidget {
  const RecoveryEvidencePage({super.key, required this.requestId});
  final String requestId;
  @override
  ConsumerState<RecoveryEvidencePage> createState() => _RecoveryEvidencePageState();
}

class _RecoveryEvidencePageState extends ConsumerState<RecoveryEvidencePage> {
  final _number = TextEditingController(), _given = TextEditingController(),
    _family = TextEditingController(), _country = TextEditingController();
  String? _user;
  String _type = 'thai_national_id';
  bool _busy = false, _failed = false, _loaded = false, _single = false, _familyFirst = false, _lifetime = false;
  DateTime? _birth, _issued, _expiry;
  IdImage? _front, _back;
  Map<String, dynamic>? _draft;
  bool get _same => mounted && _user != null && ref.read(authProvider).asData?.value?.id == _user;
  @override
  void initState() { super.initState(); _user = ref.read(authProvider).asData?.value?.id; Future.microtask(_load); }
  @override
  void dispose() { _number.dispose(); _given.dispose(); _family.dispose(); _country.dispose(); super.dispose(); }
  Future<void> _load() async {
    if (!_same || _busy) { return; }
    setState(() { _busy = true; _failed = false; _loaded = false; });
    try {
      final rows = await ref.read(recoveryRepositoryProvider).snapshot();
      final matching = rows.where((r) => r['lifecycle_id'] == widget.requestId);
      if (_same) { setState(() {
        _draft = matching.isEmpty ? null : matching.first;
        if (_draft != null) { _type = _draft!['document_type'] as String; }
        _loaded = true;
      }); }
    } catch (_) { if (_same) { setState(() => _failed = true); } }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _pick(bool back) async {
    try {
      final file = await ref.read(nationalIdImagePickerProvider)();
      if (_same && file != null) { setState(() { if (back) { _back = file; } else { _front = file; } }); }
    } catch (_) { if (_same) { setState(() => _failed = true); } }
  }
  Future<void> _date(String field) async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, initialDate: field == 'expiry' ? now.add(const Duration(days: 365)) : now,
      firstDate: DateTime(1900), lastDate: field == 'expiry' ? DateTime(now.year + 30) : now);
    if (_same && date != null) { setState(() { switch (field) {
      case 'birth': _birth = date;
      case 'issued': _issued = date;
      default: _expiry = date;
    } }); }
  }
  DateTime get _today { final now = DateTime.now(); return DateTime(now.year, now.month, now.day); }
  bool get _valid => _given.text.trim().isNotEmpty && (_single || _family.text.trim().isNotEmpty) &&
    (_type == 'passport' ? _number.text.trim().isNotEmpty && _country.text.trim().length >= 2 : RegExp(r'^\d{13}$').hasMatch(_number.text.trim())) &&
    _birth != null && _issued != null && !_issued!.isBefore(_birth!) &&
    ((_type == 'thai_national_id' && _lifetime) || (_expiry != null && _expiry!.isAfter(_issued!) && !_expiry!.isBefore(_today))) &&
    _front != null && (_type == 'passport' || _back != null);
  Future<void> _submit() async {
    if (!_same || _busy || !_valid) { return; }
    final l = AppLocalizations.of(context);
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(l.recoveryEvidenceTitle), content: Text(l.recoveryEvidenceHelp), actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.continueLabel))]));
    if (yes != true || !_same) { return; }
    setState(() { _busy = true; _failed = false; });
    String? date(DateTime? d) => d == null ? null : '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    try {
      final repo = ref.read(recoveryRepositoryProvider);
      final draft = await repo.prepare(widget.requestId, _type);
      if (!_same) { return; }
      setState(() => _draft = draft);
      await repo.submit(draft, {'number': _number.text.trim(), 'given': _given.text.trim(),
        'family': _single ? '' : _family.text.trim(), 'single': _single, 'family_first': _familyFirst,
        'country': _country.text.trim(), 'birth': date(_birth), 'issued': date(_issued),
        'expiry': _type == 'thai_national_id' && _lifetime ? null : date(_expiry)},
        [_front!, if (_type != 'passport') _back!]);
    } catch (_) { if (_same) { setState(() => _failed = true); } }
    finally { if (mounted) { setState(() => _busy = false); } }
    if (_same && !_failed) { await _load(); }
  }
  Future<void> _preview(String path) async {
    if (!_same || _busy) { return; }
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(recoveryRepositoryProvider).preview(path);
      if (!mounted || !_same) { return; }
      setState(() => _busy = false);
      await showDialog<void>(context: context, builder: (c) => AlertDialog(content: SizedBox(width: 600, height: 400,
        child: Consumer(builder: (context, ref, _) => ref.watch(authProvider).asData?.value?.id == _user
          ? InteractiveViewer(child: Image.memory(bytes)) : const SizedBox.shrink()))));
    } catch (_) { if (_same) { setState(() => _failed = true); } }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final same = ref.watch(authProvider).asData?.value?.id == _user && _user != null;
    final editable = _loaded && (_draft == null || _draft!['status'] == 'draft');
    String date(DateTime? d) => d == null ? '—' : MaterialLocalizations.of(context).formatMediumDate(d);
    return PopScope(canPop: !_busy, child: Scaffold(appBar: AppBar(title: Text(l.recoveryEvidenceTitle)), body: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: !same ? Text(l.contactSessionChanged) :
        ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.recoveryEvidenceHelp),
          if (_busy) const LinearProgressIndicator(),
          if (_failed) Text(l.recoveryActionFailed),
          OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
          if (editable) ...[
            Wrap(spacing: 8, children: [for (final type in ['thai_national_id','passport']) ChoiceChip(
              label: Text(type == 'passport' ? l.kycPassportTitle : l.kycIdCardTitle), selected: _type == type,
              onSelected: _busy || _draft != null ? null : (_) => setState(() { _type = type; _front = null; _back = null; }))]),
            TextField(controller: _number, enabled: !_busy, maxLength: 30, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: _type == 'passport' ? l.kycPassportNumber : l.idNumber)),
            TextField(controller: _given, enabled: !_busy, maxLength: 100, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l.passportGiven)),
            if (!_single) TextField(controller: _family, enabled: !_busy, maxLength: 100, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l.passportFamily)),
            CheckboxListTile(title: Text(l.residenceSingleName), value: _single, onChanged: _busy ? null : (v) => setState(() => _single = v ?? false)),
            if (!_single) CheckboxListTile(title: Text(l.passportFamilyFirst), value: _familyFirst, onChanged: _busy ? null : (v) => setState(() => _familyFirst = v ?? false)),
            if (_type == 'passport') TextField(controller: _country, enabled: !_busy, maxLength: 100, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l.residenceIssuingCountry)),
            OutlinedButton(onPressed: _busy ? null : () => _date('birth'), child: Text('${l.passportBirth}: ${date(_birth)}')),
            OutlinedButton(onPressed: _busy ? null : () => _date('issued'), child: Text('${l.kycIssueDate}: ${date(_issued)}')),
            if (_type == 'thai_national_id') CheckboxListTile(title: Text(l.idLifetime), value: _lifetime, onChanged: _busy ? null : (v) => setState(() => _lifetime = v ?? false)),
            if (_type == 'passport' || !_lifetime) OutlinedButton(onPressed: _busy ? null : () => _date('expiry'), child: Text('${l.kycExpiryDate}: ${date(_expiry)}')),
            OutlinedButton(onPressed: _busy ? null : () => _pick(false), child: Text(_type == 'passport' ? l.kycChooseDocument : l.kycChooseFrontImage)),
            if (_front != null) Text(_front!.name),
            if (_type != 'passport') OutlinedButton(onPressed: _busy ? null : () => _pick(true), child: Text(l.kycChooseBackImage)),
            if (_type != 'passport' && _back != null) Text(_back!.name),
            Text(l.recoveryRetryHelp),
            FilledButton(onPressed: !_busy && _valid ? _submit : null, child: Text(l.idSubmit)),
          ] else if (_loaded) ...[
            Text(switch (_draft?['status']) { 'submitted' => l.lifePending, 'approved' => l.lifeApproved,
              'rejected' => l.lifeRejected, 'cancelled' => l.lifeCancelled, _ => l.kycUnknownStatus }),
            if (_draft?['reason'] != null) Text(_draft!['reason'] as String),
            if (_draft?['status'] == 'submitted') for (final p in (_draft?['paths'] as List? ?? []).cast<String>())
              OutlinedButton(onPressed: _busy ? null : () => _preview(p), child: Text(p.contains('/back.') ? l.idViewBack : l.idViewDocument)),
          ],
        ])))));
  }
}
