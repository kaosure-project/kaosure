import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/features/wallet/data/repositories/supabase_wallet_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../kao_id/account/data/repositories/supabase_account_access_repository.dart';
import '../../../kao_id/governance/presentation/widgets/admin_display.dart';
import 'linked_wallets_page.dart';
import 'topup_page.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});
  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> with WidgetsBindingObserver {
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _rows = [];
  String? _user;
  bool _busy = true, _failed = false, _more = false;
  int _generation = 0;
  StreamSubscription<void>? _subscription;
  bool get _same => _user != null && ref.read(accountAccessRepositoryProvider).userId == _user;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _user = ref.read(accountAccessRepositoryProvider).userId;
    _subscription = ref.read(accountAccessRepositoryProvider).changes.listen((_) {
      if (!mounted) { return; }
      if (!_same) {
        _generation++;
        setState(() { _wallet = null; _rows = []; _busy = false; _more = false; });
      } else { unawaited(_load()); }
    });
    unawaited(_load());
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _same) { unawaited(_load()); }
  }
  Future<void> _load({bool more = false}) async {
    if (!_same) { if (mounted) { setState(() => _busy = false); } return; }
    final generation = ++_generation;
    final cursor = more && _rows.isNotEmpty ? _rows.last : null;
    setState(() { _busy = true; _failed = false; if (!more) { _wallet = null; _rows = []; _more = false; } });
    try {
      final data = await ref.read(walletRepositoryProvider).load(_user!, time: cursor?['created_at'] as String?, id: cursor?['id'] as String?);
      final wallet = data['wallet'] == null ? null : Map<String, dynamic>.from(data['wallet'] as Map);
      final rows = (data['transactions'] as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
      if (mounted && _same && generation == _generation) {
        setState(() {
          _wallet = wallet;
          final seen = more ? _rows.map((r) => r['id']).toSet() : <dynamic>{};
          _rows = [if (more) ..._rows, ...rows.where((r) => seen.add(r['id']))];
          _more = data['has_more'] == true;
        });
      }
    } catch (_) {
      if (mounted && _same && generation == _generation) {
        setState(() { _failed = true; _wallet = null; _rows = []; _more = false; });
      }
    } finally {
      if (mounted && generation == _generation) { setState(() => _busy = false); }
    }
  }
  Future<void> _openTopup() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TopupPage()));
    if (mounted && _same) { unawaited(_load()); }
  }
  @override
  void dispose() {
    _generation++; _subscription?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(appBar: AppBar(title: Text(l.walletTitle)), body: SafeArea(child: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: ListView(
        padding: const EdgeInsets.all(20), children: [
          Text(l.walletReadHelp), const SizedBox(height: 16),
          if (_same) FilledButton.icon(key: const ValueKey('wallet-topup'), onPressed: _openTopup, icon: const Icon(Icons.add_card), label: Text(l.topupTitle)),
          if (_same) TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LinkedWalletsPage())), child: Text(l.linkedWalletTitle)),
          if (!_same) Text(l.contactSessionChanged)
          else if (_failed) ...[Text(l.walletLoadFailed), OutlinedButton(onPressed: () => _load(), child: Text(l.retry))]
          else ...[
            if (_busy) const LinearProgressIndicator(),
            if (!_busy) Align(alignment: Alignment.centerRight, child: TextButton.icon(
              onPressed: () => _load(), icon: const Icon(Icons.refresh), label: Text(l.authCheckAgain))),
            if (!_busy && _wallet == null) Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 48), const SizedBox(height: 12), Text(l.walletMissing),
            ]))),
            if (_wallet != null) ...[
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.walletRecorded),
                SelectableText('${realValue(_wallet!['balance'])} ${realValue(_wallet!['currency'])}', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Text('${l.walletHeld}: ${realValue(_wallet!['hold_balance'])} ${realValue(_wallet!['currency'])}'),
                Text('${l.walletStateCode}: ${realValue(_wallet!['status'])}'),
                Text('${l.walletUpdated}: ${adminDate(context, _wallet!['updated_at'])}'),
              ]))),
              const SizedBox(height: 20), Text(l.walletHistory, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (_rows.isEmpty && !_busy) Text(l.walletNoTransactions),
              for (final row in _rows) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SelectableText('${realValue(row['amount'])} ${realValue(_wallet!['currency'])}'),
                Text('${l.walletTypeCode}: ${realValue(row['type'])}'),
                Text('${l.walletStateCode}: ${realValue(row['status'])}'),
                Text(adminDate(context, row['created_at'])),
                SelectableText('${l.walletReference}: ${realValue(row['id'])}'),
                Text('${l.walletAfter}: ${realValue(row['balance_after'])} ${realValue(_wallet!['currency'])}'),
              ]))),
              if (_more && !_busy) OutlinedButton(onPressed: () => _load(more: true), child: Text(l.walletMore)),
            ],
          ],
        ],
      )),
    )));
  }
}
