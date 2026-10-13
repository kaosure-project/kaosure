import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../domain/entities/topup_review.dart';
import '../widgets/admin_display.dart';
import 'topups_page.dart';

/// The company PromptPay account members pay into, and the top-up limits.
/// Top-up stays off until an account is set. Saving is logged with the number masked.
class TopupSettingsPage extends ConsumerStatefulWidget {
  const TopupSettingsPage({super.key});

  @override
  ConsumerState<TopupSettingsPage> createState() => _TopupSettingsPageState();
}

class _TopupSettingsPageState extends ConsumerState<TopupSettingsPage> {
  static final _money = RegExp(r'^\d{1,8}(\.\d{1,2})?$');

  final _id = TextEditingController();
  final _receiver = TextEditingController();
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _daily = TextEditingController();
  final _dual = TextEditingController();
  final _hours = TextEditingController();
  String? _owner;
  TopupSettings? _data;
  bool _enabled = false;
  PromptPayType? _type;
  bool _busy = false;
  Object? _error;
  String? _done;

  bool get _same => mounted && _owner != null && ref.read(authProvider).asData?.value?.id == _owner;

  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(_load);
  }

  @override
  void dispose() {
    for (final controller in [_id, _receiver, _min, _max, _daily, _dual, _hours]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fill(TopupSettings data) {
    String amount(double value) => NumberFormat('0.##').format(value);
    _data = data;
    _enabled = data.enabled;
    _type = data.promptPayType;
    _id.text = data.promptPayId ?? '';
    _receiver.text = data.receiverName ?? '';
    _min.text = amount(data.minAmount);
    _max.text = amount(data.maxAmount);
    _daily.text = amount(data.dailyMax);
    _dual.text = amount(data.dualReviewFrom);
    _hours.text = '${data.slipHours}';
  }

  Future<void> _load() async {
    if (!_same || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await ref.read(topupReviewRepositoryProvider).settings();
      if (_same) setState(() => _fill(data));
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  double? _amount(TextEditingController controller) {
    final text = controller.text.trim().replaceAll(',', '');
    return _money.hasMatch(text) ? double.tryParse(text) : null;
  }

  String get _cleanId => _id.text.replaceAll(RegExp(r'[\s-]'), '');

  TopupSettings? get _draft {
    final data = _data;
    final min = _amount(_min), max = _amount(_max), daily = _amount(_daily), dual = _amount(_dual);
    final hours = int.tryParse(_hours.text.trim());
    if (data == null || min == null || max == null || daily == null || dual == null || hours == null) return null;
    final id = _cleanId;
    return TopupSettings(
      enabled: _enabled,
      promptPayType: id.isEmpty ? null : _type,
      promptPayId: id.isEmpty ? null : id,
      receiverName: _receiver.text.trim().isEmpty ? null : _receiver.text.trim(),
      minAmount: min,
      maxAmount: max,
      dailyMax: daily,
      dualReviewFrom: dual,
      slipHours: hours,
      version: data.version,
    );
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !_same || _busy) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _done = null;
    });
    try {
      final saved = await ref.read(topupReviewRepositoryProvider).saveSettings(draft);
      if (_same) {
        setState(() {
          _fill(saved);
          _done = l.topupSettingsSaved;
        });
      }
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
    final data = _data;
    final id = _cleanId;
    final idOk = id.isEmpty || (_type?.accepts(id) ?? false);
    final ready = !_enabled || (id.isNotEmpty && _receiver.text.trim().isNotEmpty);
    final canSave = !_busy && _draft != null && idOk && ready;
    Widget field(String key, TextEditingController controller, String label, {String? helper, bool money = true}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            key: ValueKey(key),
            controller: controller,
            enabled: !_busy,
            keyboardType: money ? const TextInputType.numberWithOptions(decimal: true) : null,
            inputFormatters: money ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))] : null,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: label, helperText: helper, border: const OutlineInputBorder()),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l.topupSettingsTitle)),
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
                        Text(
                          topupReviewErrorText(l, error),
                          key: const ValueKey('topup-settings-error'),
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      if (_done case final done?) Text(done, key: const ValueKey('topup-settings-done')),
                      if (data != null) ...[
                        AdminSection(
                          title: l.topupSettingsAccount,
                          children: [
                            Text(l.topupSettingsHelp),
                            SwitchListTile(
                              key: const ValueKey('topup-settings-enabled'),
                              contentPadding: EdgeInsets.zero,
                              value: _enabled,
                              onChanged: _busy ? null : (value) => setState(() => _enabled = value),
                              title: Text(l.topupSettingsEnabled),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DropdownButtonFormField<PromptPayType>(
                                key: const ValueKey('topup-settings-type'),
                                initialValue: _type,
                                decoration: InputDecoration(
                                  labelText: l.topupSettingsType,
                                  border: const OutlineInputBorder(),
                                ),
                                items: [
                                  for (final type in PromptPayType.values)
                                    DropdownMenuItem(
                                      value: type,
                                      child: Text(switch (type) {
                                        PromptPayType.phone => l.topupSettingsTypePhone,
                                        PromptPayType.nationalId => l.topupSettingsTypeNationalId,
                                        PromptPayType.ewallet => l.topupSettingsTypeEwallet,
                                      }),
                                    ),
                                ],
                                onChanged: _busy ? null : (value) => setState(() => _type = value),
                              ),
                            ),
                            field(
                              'topup-settings-id',
                              _id,
                              l.topupSettingsId,
                              helper: idOk ? l.topupSettingsIdHelp : l.topupSettingsPromptPayInvalid,
                              money: false,
                            ),
                            field('topup-settings-receiver', _receiver, l.topupSettingsReceiver, money: false),
                          ],
                        ),
                        AdminSection(
                          title: l.topupSettingsLimits,
                          children: [
                            field('topup-settings-min', _min, l.topupSettingsMin),
                            field('topup-settings-max', _max, l.topupSettingsMax),
                            field('topup-settings-daily', _daily, l.topupSettingsDaily),
                            field(
                              'topup-settings-dual',
                              _dual,
                              l.topupSettingsDual,
                              helper: l.topupSettingsDualHelp,
                            ),
                            field('topup-settings-hours', _hours, l.topupSettingsHours, helper: l.topupSettingsHoursHelp),
                            AdminValue(
                              label: l.topupSettingsUpdated,
                              value:
                                  '${realValue(data.updatedByName)} · ${adminDate(context, data.updatedAt?.toIso8601String())}',
                            ),
                          ],
                        ),
                        if (!ready) Text(l.topupSettingsReceiverRequired, key: const ValueKey('topup-settings-not-ready')),
                        FilledButton.icon(
                          key: const ValueKey('topup-settings-save'),
                          onPressed: canSave ? _save : null,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(l.topupSettingsSave),
                        ),
                      ],
                      if (data == null && !_busy) OutlinedButton(onPressed: _load, child: Text(l.authCheckAgain)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
