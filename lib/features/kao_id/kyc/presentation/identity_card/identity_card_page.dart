import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../identity_card/national_id_repository.dart';
import '../widgets/kyc_status_label.dart';

final class IdentityCardPage extends ConsumerStatefulWidget {
  const IdentityCardPage({super.key});
  @override
  ConsumerState<IdentityCardPage> createState() => _IdentityCardPageState();
}

final class _IdentityCardPageState extends ConsumerState<IdentityCardPage> {
  final _number = TextEditingController();
  final _name = TextEditingController();
  final _surname = TextEditingController();
  bool _validationAttempted = false;
  String? _owner;
  NationalIdRecord? _record;
  NationalIdDraft? _attempt;
  IdImage? _front, _back;
  DateTime? _issued, _expiry;
  bool _lifetime = false, _busy = false, _known = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }
  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _surname.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted || _busy) { return; }
    setState(() { _busy = true; _message = null; });
    try {
      final repo = ref.read(nationalIdRepositoryProvider);
      final owner = await repo.owner();
      if (_owner != null && _owner != owner) { throw const NationalIdFailure('session'); }
      final record = await repo.latest(owner);
      if (!mounted) { return; }
      setState(() { _owner = owner; _record = record; _known = true; });
      if (record != null && record.id == _attempt?.id) {
        _attempt = null;
        _front = null;
        _back = null;
        _number.clear();
        _name.clear();
      _surname.clear();
      }
    } catch (error) {
      if (mounted) { setState(() { _known = false; _record = null; _message = error is NationalIdFailure ? error.code : 'load'; }); }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }

  Future<void> _pick(bool front) async {
    if (_busy || _attempt != null) { return; }
    setState(() { _busy = true; _message = null; });
    try {
      final selected = await ref.read(nationalIdImagePickerProvider)();
      if (selected == null || !mounted) { return; }
      setState(() {
        if (front) { _front = selected; } else { _back = selected; }
      });
    } catch (_) {
      if (mounted) { setState(() => _message = 'file'); }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }

  Future<void> _date(bool issue) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final chosen = await showDatePicker(context: context,
      initialDate: issue ? (_issued ?? today) : (_expiry ?? today),
      firstDate: issue ? DateTime(1900) : today,
      lastDate: issue ? today : DateTime(today.year + 30, 12, 31));
    if (chosen == null || !mounted) { return; }
    setState(() { if (issue) { _issued = chosen; } else { _expiry = chosen; } });
  }

  Map<String, String> _errors(AppLocalizations l) {
    final errors = <String, String>{};
    if (_name.text.trim().isEmpty) { errors['first'] = l.idFirstNameRequired; }
    if (_surname.text.trim().isEmpty) { errors['last'] = l.idLastNameRequired; }
    if ('${_name.text.trim()} ${_surname.text.trim()}'.length > 200) {
      errors['last'] = l.idNameTooLong;
    }
    if (!RegExp(r'^\d{13}$').hasMatch(_number.text.trim())) {
      errors['number'] = l.idNumberRequired;
    }
    if (_issued == null) { errors['issued'] = l.idIssuedRequired; }
    if (!_lifetime && (_expiry == null ||
        (_issued != null && !_expiry!.isAfter(_issued!)))) {
      errors['expiry'] = l.idExpiryRequired;
    }
    if (_front == null) { errors['front'] = l.idFrontRequired; }
    if (_back == null) { errors['back'] = l.idBackRequired; }
    return errors;
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 8)));
  }

  Future<void> _save() async {
    if (_busy || !_known || _owner == null) { return; }
    if (_attempt == null) {
      final l = AppLocalizations.of(context);
      final errors = _errors(l);
      setState(() => _validationAttempted = true);
      if (errors.isNotEmpty) {
        setState(() => _message = 'form');
        _notify(l.idCheckHighlightedFields);
        return;
      }
      FocusScope.of(context).unfocus();
      _attempt = NationalIdDraft(id: const Uuid().v4(), owner: _owner!,
        number: _number.text.trim(), fullName: '${_name.text.trim()} ${_surname.text.trim()}', issued: _issued!,
        expiry: _lifetime ? null : _expiry, front: _front!, back: _back!);
    }
    setState(() { _busy = true; _message = null; });
    try {
      final result = await ref.read(nationalIdRepositoryProvider).submit(_attempt!);
      if (!mounted) { return; }
      setState(() {
        _record = result;
        _attempt = null;
        _front = null;
        _back = null;
        _message = 'saved';
        _validationAttempted = false;
      });
      _number.clear();
      _name.clear();
      _surname.clear();
    } catch (error) {
      if (mounted) {
        setState(() => _message = error is NationalIdFailure ? error.code : 'save');
        final l = AppLocalizations.of(context);
        _notify(_message == 'session' ? l.contactSessionChanged : l.idSaveFailed);
      }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }

  Future<void> _view(String path) async {
    if (_busy || _owner == null) { return; }
    setState(() { _busy = true; _message = null; });
    Uint8List? bytes;
    try {
      bytes = await ref.read(nationalIdRepositoryProvider).preview(_owner!, path);
    } catch (_) {
      if (mounted) { setState(() => _message = 'preview'); }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
    final imageBytes = bytes;
    if (!mounted || imageBytes == null) { return; }
    final l = AppLocalizations.of(context);
    await showDialog<void>(context: context, builder: (_) => AlertDialog(
      title: Text(l.idViewDocument),
      content: SizedBox(width: 600, height: 400, child: InteractiveViewer(
        child: Image.memory(imageBytes, fit: BoxFit.contain,
          errorBuilder: (_, error, stack) => Text(l.idPreviewFailed)))),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.back))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final errors = _validationAttempted ? _errors(l) : <String, String>{};
    final editable = _known && !_busy && _attempt == null;
    final showForm = _known && (_record == null || _record!.canResubmit);
    final message = switch (_message) {
      'file' => l.idFileInvalid,
      'form' => l.idCheckHighlightedFields,
      'session' => l.contactSessionChanged,
      'load' => l.contactLoadFailed,
      'preview' => l.idPreviewFailed,
      'saved' => l.idSubmitted,
      _ => l.idSaveFailed,
    };
    Widget picker(bool front) {
      final selected = front ? _front : _back;
      return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(front ? l.kycFrontOfCard : l.kycBackOfCard,
            style: Theme.of(context).textTheme.titleMedium),
          if (selected != null) ...[
            const SizedBox(height: 12),
            Image.memory(selected.bytes, height: 160, fit: BoxFit.contain),
            Text(selected.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(key: ValueKey(front ? 'id-front' : 'id-back'), onPressed: editable ? () => _pick(front) : null,
            icon: const Icon(Icons.image_outlined), label: Text(l.kycChooseFile)),
          if (errors[front ? 'front' : 'back'] != null) Text(errors[front ? 'front' : 'back']!,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      )));
    }
    String dateText(DateTime? value) => value == null ? l.kycSelectDate
      : MaterialLocalizations.of(context).formatMediumDate(value);
    return PopScope(canPop: !_busy, child: Scaffold(
      appBar: AppBar(title: Text(l.kycIdCardTitle)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.idIntro),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          if (_record != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(kycStatusLabel(l, _record!.status)),
              if (_record!.paths.isEmpty) Text(l.idLegacyRecord),
              if (_record!.rejection?.isNotEmpty == true) Text(_record!.rejection!),
              for (final path in _record!.paths) TextButton.icon(
                onPressed: _busy ? null : () => _view(path), icon: const Icon(Icons.visibility_outlined),
                label: Text(path.contains('/front.') ? l.idViewFront : l.idViewBack)),
            ],
          ))),
          OutlinedButton.icon(onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh), label: Text(l.authCheckAgain)),
          if (showForm) ...[
            const SizedBox(height: 16),
            TextField(key: const ValueKey('id-name'), controller: _name, enabled: editable, maxLength: 200,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l.idFirstName, errorText: errors['first'], border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(key: const ValueKey('id-surname'), controller: _surname, enabled: editable, maxLength: 200,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l.idLastName, errorText: errors['last'], border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(key: const ValueKey('id-number'), controller: _number, enabled: editable, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(errorText: errors['number'], labelText: l.idNumber, border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            OutlinedButton(key: const ValueKey('id-issued'), onPressed: editable ? () => _date(true) : null,
              child: Text('${l.kycIssueDate}: ${dateText(_issued)}')),
            if (errors['issued'] != null) Text(errors['issued']!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            CheckboxListTile(key: const ValueKey('id-lifetime'), value: _lifetime, title: Text(l.idLifetime),
              onChanged: editable ? (value) => setState(() => _lifetime = value ?? false) : null),
            if (!_lifetime) OutlinedButton(onPressed: editable ? () => _date(false) : null,
              child: Text('${l.kycExpiryDate}: ${dateText(_expiry)}')),
            if (errors['expiry'] != null) Text(errors['expiry']!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            picker(true), picker(false),
            const SizedBox(height: 12),
            Text(l.idFileHelp),
            const SizedBox(height: 20),
            if (_validationAttempted && errors.isNotEmpty) Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(liveRegion: true, child: Text(errors.values.join('\n'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)))),
            if (_busy) Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text(l.idSubmitting)),
            FilledButton.icon(key: const ValueKey('id-submit'), onPressed: _busy ? null : _save,
              icon: const Icon(Icons.upload_file),
              label: Text(_attempt == null ? l.idSubmit : l.idRetrySubmission)),
          ],
          if (_message != null) ...[const SizedBox(height: 16),
            Semantics(liveRegion: true, child: Text(message))],
        ]),
      ))),
    ));
  }
}
