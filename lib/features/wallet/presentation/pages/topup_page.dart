import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../kao_id/auth/application/providers/auth_provider.dart';
import '../../application/providers/topup_providers.dart';
import '../../data/repositories/supabase_topup_repository.dart';
import '../../domain/entities/topup_request.dart';
import '../utils/topup_texts.dart';
import '../widgets/topup_qr_card.dart';

/// "เติมเงิน": the member picks an amount, pays the PromptPay QR from an account
/// in their own name and sends the slip. Staff credit the wallet after checking it.
class TopupPage extends ConsumerStatefulWidget {
  const TopupPage({super.key});

  @override
  ConsumerState<TopupPage> createState() => _TopupPageState();
}

class _TopupPageState extends ConsumerState<TopupPage> {
  static final _amountPattern = RegExp(r'^\d{1,7}(\.\d{1,2})?$');

  final _amount = TextEditingController();
  String? _owner;
  TopupInfo? _info;
  List<TopupRequest> _history = [];
  bool _busy = false, _more = false, _loadFailed = false;
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
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (!_same || _busy) return;
    final before = more && _history.isNotEmpty ? _history.last.createdAt : null;
    setState(() {
      _busy = true;
      _loadFailed = false;
    });
    final repository = ref.read(topupRepositoryProvider);
    try {
      final info = more ? _info : await repository.info();
      final rows = await repository.history(before: before);
      if (_same) {
        setState(() {
          _info = info;
          _history = [if (more) ..._history, ...rows];
          _more = rows.length == 20;
        });
      }
    } catch (_) {
      if (_same) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    if (!_same || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _done = null;
    });
    try {
      await action();
      if (_same) setState(() => _done = done);
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_same) await _load();
  }

  double? get _amountValue {
    final text = _amount.text.trim().replaceAll(',', '');
    return _amountPattern.hasMatch(text) ? double.tryParse(text) : null;
  }

  Future<void> _create() async {
    final amount = _amountValue;
    if (amount == null) return;
    final l = AppLocalizations.of(context);
    await _run(() async {
      await ref.read(topupRepositoryProvider).create(amount);
      _amount.clear();
    }, l.topupCreatedDone);
  }

  Future<void> _sendSlip(TopupRequest request) async {
    final l = AppLocalizations.of(context);
    final picker = ref.read(slipPickerProvider);
    await _run(() async {
      final jpeg = await picker();
      if (jpeg == null) throw const _Skipped();
      await ref.read(topupRepositoryProvider).sendSlip(request, jpeg);
    }, l.topupSlipSentDone);
    if (_error is _Skipped && mounted) {
      setState(() {
        _error = null;
        _done = null;
      });
    }
  }

  Future<void> _cancel(TopupRequest request) async {
    final l = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.topupCancel),
        content: Text(l.topupCancelConfirm(topupBaht(request.amount))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(
            key: const ValueKey('topup-cancel-confirm'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.continueLabel),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await _run(() => ref.read(topupRepositoryProvider).cancel(request.id), l.topupCancelledDone);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    final info = _info;
    final open = info?.open;
    final amount = _amountValue;
    final amountOk = info != null && amount != null && amount >= info.minAmount && amount <= info.maxAmount;
    return Scaffold(
      appBar: AppBar(title: Text(l.topupTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: !same
                ? Text(l.contactSessionChanged)
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(l.topupHelp),
                      const SizedBox(height: 16),
                      if (_busy) const LinearProgressIndicator(),
                      if (_error case final error? when error is! _Skipped)
                        Text(
                          topupErrorText(l, error),
                          key: const ValueKey('topup-error'),
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      if (_done case final done?) Text(done, key: const ValueKey('topup-done')),
                      if (_loadFailed) ...[
                        Text(l.walletLoadFailed),
                        OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.retry)),
                      ],
                      if (info != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(l.walletRecorded),
                                SelectableText(
                                  topupBaht(info.balance),
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(l.topupToday(topupBaht(info.todayTotal), topupBaht(info.dailyMax))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (open != null)
                          TopupOpenCard(
                            request: open,
                            busy: _busy,
                            onSendSlip: () => _sendSlip(open),
                            onCancel: () => _cancel(open),
                          )
                        else if (info.canTopUp)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    key: const ValueKey('topup-amount'),
                                    controller: _amount,
                                    enabled: !_busy,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      labelText: l.topupAmount,
                                      helperText: l.topupAmountHelp(
                                        topupBaht(info.minAmount),
                                        topupBaht(info.maxAmount),
                                      ),
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      for (final quick in const [100, 500, 1000, 5000])
                                        if (quick >= info.minAmount && quick <= info.maxAmount)
                                          ActionChip(
                                            label: Text(topupBaht(quick.toDouble())),
                                            onPressed: _busy
                                                ? null
                                                : () => setState(() => _amount.text = '$quick'),
                                          ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(l.topupPayerNotice),
                                  Text(l.topupSlipHours(info.slipHours)),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    key: const ValueKey('topup-create'),
                                    onPressed: !_busy && amountOk ? _create : null,
                                    icon: const Icon(Icons.qr_code_2),
                                    label: Text(l.topupCreate),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (info.block case final block?)
                          Text(topupBlockText(l, block), key: const ValueKey('topup-blocked')),
                        const SizedBox(height: 20),
                        Text(l.topupHistory, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        if (_history.isEmpty && !_busy) Text(l.topupNoHistory),
                        for (final row in _history) TopupHistoryTile(request: row),
                        if (_more && !_busy)
                          OutlinedButton(onPressed: () => _load(more: true), child: Text(l.walletMore)),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// The member closed the picker without choosing a slip.
class _Skipped implements Exception {
  const _Skipped();
}
