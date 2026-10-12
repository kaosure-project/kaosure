import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/kao_id_subpage_scaffold.dart';
import '../../../dashboard/presentation/widgets/section/section_body.dart';
import '../../domain/failures/national_id_failure.dart';
import '../../domain/entities/id_image.dart';
import '../../application/providers/id_image_picker_provider.dart';
import '../../domain/entities/residence.dart';
import '../../domain/entities/thai_document_kind.dart';
import '../../domain/reference/countries.dart';
import '../../domain/validators/alien_id_number.dart';
import '../../data/repositories/supabase_residence_repository.dart';
import '../widgets/form/kyc_form_parts.dart';
import '../widgets/form/nationality_field.dart';
import '../widgets/form/thai_address_fields.dart';
import '../widgets/kyc_status_label.dart';
import '../widgets/thai_document_kind_label.dart';

/// Thai government documents for foreign residents. Residence documents sent
/// before document kinds existed are still shown read-only.
final class ResidencePermitPage extends ConsumerStatefulWidget {
  const ResidencePermitPage({super.key});
  @override
  ConsumerState<ResidencePermitPage> createState() => _ResidencePermitPageState();
}
final class _ResidencePermitPageState extends ConsumerState<ResidencePermitPage> {
  final _form = GlobalKey<FormState>();
  final _given = TextEditingController(), _family = TextEditingController();
  final _number = TextEditingController();
  final _address = ThaiAddressController();
  ThaiDocumentKind? _kind;
  String? _nationality;
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
    _given.dispose(); _family.dispose(); _number.dispose(); _address.dispose();
    super.dispose();
  }
  void _clearForm() {
    _given.clear(); _family.clear(); _number.clear(); _address.clear(); _nationality = null; _kind = null;
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
    'form' => l.thaiDocCompleteForm,
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
  bool get _datesValid => _issued != null && (_noExpiry || (_expiry != null && _expiry!.isAfter(_issued!)));
  Future<void> _save() async {
    if (_busy || !_known || _owner == null || _sessionChanged) { return; }
    if (_attempt == null) {
      setState(() => _validate = true);
      final fieldsValid = _form.currentState!.validate();
      if (!fieldsValid || _kind == null || countryByCode(_nationality) == null || !_address.value.isValid ||
          !_datesValid || _front == null || (_card && _back == null)) {
        _fail('form'); return;
      }
      _attempt = ResidenceDraft(id: const Uuid().v4(), owner: _owner!, kind: _kind!,
        number: _number.text.trim(), given: _given.text.trim(),
        family: _single ? '' : _family.text.trim(), singleName: _single,
        familyFirst: _single ? false : _familyFirst, nationality: _nationality!,
        format: _card ? 'card' : 'paper', noExpiry: _noExpiry,
        issued: _issued!, expiry: _noExpiry ? null : _expiry, address: _address.value,
        front: _front!, back: _card ? _back : null);
    }
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    try {
      final result = await ref.read(residenceRepositoryProvider).submit(_attempt!);
      if (mounted && !_sessionChanged) {
        setState(() { _record = result; _pending = true; _attempt = null; _front = null; _back = null; _clearForm(); });
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
        title: Text(l.kycForeignDocTitle),
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

  Widget _statusPanel(AppLocalizations l, bool showForm) {
    final record = _record;
    final language = l.localeName.split('_').first;
    String date(DateTime? d) => d == null ? l.kycSelectDate : MaterialLocalizations.of(context).formatMediumDate(d);
    final kind = record?.kind;
    return KycFormPanel(title: l.kycLatestSubmission, icon: Icons.history, color: AppColors.kaoSlate, children: [
      if (_busy) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator()),
      if (_error != null && !showForm) KycFormMessage(message: _message(l, _error!)),
      if (_known && record == null) Text(l.kycNoDocumentSubmitted,
        style: const TextStyle(color: AppColors.textSecondary)),
      if (record != null) ...[
        Text(kind == null ? l.thaiDocLegacy : thaiDocumentKindLabel(l, kind),
          style: const TextStyle(color: AppColors.textSecondary)),
        Text(kycStatusLabel(l, record.status), style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.w700)),
        if (record.data['full_name'] != null) Text(record.data['full_name'] as String),
        if (countryByCode(record.nationality) case final country?)
          Text('${l.nationalityLabel}: ${country.name(language)}')
        else if (kind == null && record.data['issuing_country'] != null)
          Text('${l.residenceIssuingCountry}: ${record.data['issuing_country']}'),
        Text('${l.kycExpiryDate}: ${record.data['no_expiry'] == true ? l.residenceNoExpiry : date(record.expiry)}'),
        if (record.rejection?.isNotEmpty == true) Text(record.rejection!,
          style: const TextStyle(color: AppColors.error)),
        for (final path in record.paths) Align(alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(onPressed: _busy ? null : () => _preview(path),
            icon: const Icon(Icons.visibility_outlined),
            label: Text(path.endsWith('/back.jpg') ? l.residenceViewBack : l.residenceViewFront))),
        if (const {'pending', 'pending_review', 'under_review', 'submitted'}.contains(record.status))
          Text(l.thaiDocPendingHelp, style: const TextStyle(color: AppColors.textSecondary)),
      ],
      if (_known && _pending && (record == null || record.canResubmit)) ...[
        const SizedBox(height: 8),
        KycFormMessage(message: l.residenceOtherPending, error: false),
      ],
      const SizedBox(height: 8),
      Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(
        onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh), label: Text(l.authCheckAgain))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      final previousId = previous?.asData?.value?.id;
      final nextId = next.asData?.value?.id;
      if (_owner != null && (previousId == _owner || nextId != null) && nextId != _owner) {
        setState(() {
          _sessionChanged = true; _record = null; _attempt = null; _front = null; _back = null; _clearForm();
        });
      }
    });
    final l = AppLocalizations.of(context);
    Widget frame(Widget child) => KaoIdSubpageScaffold(
      badgeIcon: Icons.verified_user_outlined, badgeLabel: l.kycIdentityVerification, child: child);
    if (_sessionChanged) { return frame(Center(child: Text(l.contactSessionChanged))); }
    final editable = !_busy && _attempt == null;
    final showForm = _known && !_pending && (_record == null || _record!.canResubmit);
    Widget field(String key, TextEditingController controller, String label, int max,
        {String? helper, bool digits = false, String? Function(String)? check}) => Padding(
      padding: const EdgeInsets.only(bottom: 8), child: TextFormField(
        key: ValueKey(key), controller: controller, enabled: editable, maxLength: max,
        textInputAction: TextInputAction.next,
        keyboardType: digits ? TextInputType.number : null,
        inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(labelText: label, helperText: helper, helperMaxLines: 2,
          border: const OutlineInputBorder()),
        validator: (value) {
          if (value == null || value.trim().isEmpty) { return l.passportRequired; }
          return check?.call(value.trim());
        },
      ));
    Widget picker(bool front) => KycImagePicker(
      buttonKey: front ? 'residence-front' : 'residence-back',
      title: front ? (_card ? l.thaiDocFront : l.thaiDocPage) : l.thaiDocBack,
      image: front ? _front : _back,
      onPick: editable ? () => _pick(front) : null,
      errorText: _validate && (front ? _front : _back) == null ? l.residenceImageRequired : null);
    final text = Theme.of(context).textTheme;
    return PopScope(canPop: !_busy, child: frame(Form(key: _form,
      autovalidateMode: _validate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      child: SectionBody(
        icon: Icons.assignment_ind_outlined, color: AppColors.kaoBlue, tint: AppColors.kaoBlueSoft,
        title: l.kycForeignDocTitle, description: l.kycForeignDocIntro,
        top: [_statusPanel(l, showForm)],
        start: [
          if (showForm) KycFormPanel(title: l.kycDocumentSection, icon: Icons.badge_outlined, children: [
            Text(l.thaiDocKindLabel, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final kind in ThaiDocumentKind.values)
                ChoiceChip(
                  key: ValueKey('residence-kind-${kind.code}'),
                  label: Text(thaiDocumentKindLabel(l, kind)),
                  selected: _kind == kind,
                  onSelected: editable ? (_) => setState(() { _kind = kind; _card = kind.cardByDefault; }) : null,
                ),
            ]),
            if (_validate && _kind == null) Padding(padding: const EdgeInsets.only(top: 6),
              child: Text(l.thaiDocKindRequired, style: const TextStyle(color: AppColors.error))),
            const SizedBox(height: 20),
            field('residence-number', _number, l.alienIdLabel, 13, helper: l.alienIdHelp, digits: true,
              check: (value) => isValidThaiPersonalNumber(value) ? null : l.alienIdInvalid),
            const SizedBox(height: 8),
            KycDateField(fieldKey: 'residence-issued', label: l.kycIssueDate, value: _issued,
              onTap: editable ? () => _date('issued') : null,
              errorText: _validate && _issued == null ? l.residenceDatesInvalid : null),
            CheckboxListTile(key: const ValueKey('residence-no-expiry'), value: _noExpiry,
              contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
              onChanged: editable ? (v) => setState(() => _noExpiry = v ?? false) : null,
              title: Text(l.residenceNoExpiry)),
            if (!_noExpiry) Padding(padding: const EdgeInsets.only(top: 8), child: KycDateField(
              fieldKey: 'residence-expiry', label: l.kycExpiryDate, value: _expiry,
              onTap: editable ? () => _date('expiry') : null,
              errorText: _validate && _issued != null && !_datesValid ? l.residenceDatesInvalid : null)),
          ]),
          if (showForm) KycFormPanel(title: l.kycHolderSection, icon: Icons.person_outline, children: [
            CheckboxListTile(key: const ValueKey('residence-single'), value: _single,
              contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
              onChanged: editable ? (v) => setState(() => _single = v ?? false) : null,
              title: Text(l.residenceSingleName)),
            const SizedBox(height: 8),
            field('residence-given', _given, _single ? l.residenceOnlyName : l.passportGiven, 100),
            if (!_single) field('residence-family', _family, l.passportFamily, 100),
            if (!_single) CheckboxListTile(value: _familyFirst,
              contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
              onChanged: editable ? (v) => setState(() => _familyFirst = v ?? false) : null,
              title: Text(l.passportFamilyFirst)),
            const SizedBox(height: 8),
            NationalityField(fieldKey: 'residence-nationality', label: l.nationalityLabel,
              value: _nationality, enabled: editable, showError: _validate,
              onChanged: (code) => setState(() => _nationality = code)),
          ]),
        ],
        end: [
          if (showForm) KycFormPanel(title: l.docAddressTitle, subtitle: l.docAddressHelp,
            icon: Icons.home_outlined, color: AppColors.kaoGreen, children: [
              ThaiAddressFields(controller: _address, keyPrefix: 'residence', enabled: editable,
                showErrors: _validate, onChanged: () => setState(() {})),
            ]),
          if (showForm) KycFormPanel(title: l.kycImagesSection, subtitle: l.idFileHelp,
            icon: Icons.photo_camera_outlined, children: [
              SwitchListTile(key: const ValueKey('residence-card'), value: _card, contentPadding: EdgeInsets.zero,
                onChanged: editable ? (v) => setState(() => _card = v) : null,
                title: Text(l.thaiDocCardFormat), subtitle: Text(_card ? l.residenceTwoSides : l.residenceOnePage)),
              const SizedBox(height: 8),
              picker(true),
              if (_card) picker(false),
              const SizedBox(height: 4),
              if (_error != null) KycFormMessage(message: _message(l, _error!)),
              if (_busy) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(l.idSubmitting)),
              FilledButton.icon(key: const ValueKey('residence-submit'), onPressed: _busy ? null : _save,
                icon: const Icon(Icons.send_outlined),
                label: Text(_attempt == null ? l.thaiDocSubmit : l.idRetrySubmission)),
            ]),
        ],
      ),
    )));
  }
}
