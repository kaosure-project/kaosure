import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../auth/application/providers/auth_provider.dart';
import '../../governance/members/member_repository.dart';
import '../../kyc/review/kyc_review_repository.dart';
import 'mfa_repository.dart';

class MfaPage extends ConsumerStatefulWidget {
  const MfaPage({super.key});
  @override
  ConsumerState<MfaPage> createState() => _MfaPageState();
}
class _MfaPageState extends ConsumerState<MfaPage> with WidgetsBindingObserver {
  final _name = TextEditingController(), _password = TextEditingController(), _code = TextEditingController();
  Map<String, dynamic>? _data;
  Map<String, String>? _draft;
  String? _owner, _factor;
  bool _busy = false, _failed = false, _showSecret = false;
  bool get _same => mounted && _owner != null && ref.read(authProvider).asData?.value?.id == _owner;
  @override
  void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this);
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(_load);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) { setState(() => _showSecret = false); }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _password.clear(); _code.clear(); _draft = null;
    _name.dispose(); _password.dispose(); _code.dispose(); super.dispose();
  }
  Future<void> _load() async {
    if (!_same || _busy) { return; }
    setState(() { _busy = true; _failed = false; });
    try {
      final data = await ref.read(mfaRepositoryProvider).load();
      if (_same) { setState(() => _data = data); }
    } catch (_) { if (_same) { setState(() { _failed = true; _data = null; }); } }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !_same) { return; }
    setState(() { _busy = true; _failed = false; });
    try { await action(); }
    catch (_) { if (_same) { setState(() => _failed = true); } }
    finally { _password.clear(); _code.clear(); if (mounted) { setState(() => _busy = false); } }
    if (_same) { ref.invalidate(memberAccessProvider); ref.invalidate(kycReviewerAccessProvider); }
  }
  Future<void> _verify() async {
    final factor = _draft?['id'] ?? _factor;
    if (factor == null) { return; }
    await _run(() async {
      await ref.read(mfaRepositoryProvider).verify(factor, _code.text);
      if (_same) { setState(() { _draft = null; _showSecret = false; }); }
    });
    if (_same && !_failed) { await _load(); }
  }
  Future<void> _enable() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(l.securityEnable), content: Text(l.securityEnableHelp), actions: [
        TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.continueLabel)),
      ]));
    if (ok != true || !_same) { return; }
    await _run(() => ref.read(mfaRepositoryProvider).enablePolicy());
    if (_same && !_failed) { await _load(); }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(authProvider).asData?.value?.id;
    if (_owner == null || current != _owner) {
      _draft = null;
      return Scaffold(appBar: AppBar(title: Text(l.twoFactorAuthentication)), body: Center(child: Text(l.contactSessionChanged)));
    }
    final factors = (_data?['factors'] as List? ?? []).cast<Map>();
    final selected = _factor != null && factors.any((f) => f['id'] == _factor) ? _factor : null;
    final ready = _data?['aal2'] == true && (_data?['verified_factors'] as num? ?? 0) >= 2 && (_data?['ready_reviewers'] as num? ?? 0) >= 2;
    return Scaffold(appBar: AppBar(title: Text(l.twoFactorAuthentication)), body: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: ListView(padding: const EdgeInsets.all(24), children: [
        Text(l.mfaHelp), const SizedBox(height: 16),
        if (_busy) const LinearProgressIndicator(),
        if (_failed) Text(l.mfaFailed),
        OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
        if (_data != null) ...[
          Text(_data!['aal2'] == true ? l.mfaSessionVerified : l.mfaSessionRequired),
          Text('${l.mfaFactorCount}: ${_data!['verified_factors']}'),
          if (factors.isNotEmpty && _draft == null) DropdownButton<String>(
            isExpanded: true, value: selected, hint: Text(l.mfaChoose),
            items: [for (final f in factors) DropdownMenuItem(value: f['id'] as String, child: Text(f['name'] as String))],
            onChanged: _busy ? null : (value) => setState(() => _factor = value)),
          if (_draft != null) ...[
            Text(l.mfaManualSetup),
            TextButton(onPressed: _busy ? null : () => setState(() => _showSecret = !_showSecret), child: Text(l.mfaShowSecret)),
            if (_showSecret) SelectableText(_draft!['secret']!),
            TextButton(onPressed: _busy ? null : () async {
              final id = _draft!['id']!;
              await _run(() async { await ref.read(mfaRepositoryProvider).cancelEnrollment(id); if (_same) { setState(() => _draft = null); } });
            }, child: Text(l.cancel)),
          ],
          if (_draft != null || selected != null) ...[
            TextField(controller: _code, enabled: !_busy, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              decoration: InputDecoration(labelText: l.mfaCode)),
            FilledButton(onPressed: _busy ? null : _verify, child: Text(l.mfaVerify)),
          ],
          if (_draft == null) ...[
            const Divider(), Text(l.mfaBackupHelp),
            TextField(controller: _name, enabled: !_busy, maxLength: 40, decoration: InputDecoration(labelText: l.mfaDeviceName)),
            if (factors.isEmpty) TextField(controller: _password, enabled: !_busy, obscureText: true, enableSuggestions: false, autocorrect: false,
              decoration: InputDecoration(labelText: l.password)),
            OutlinedButton(onPressed: _busy ? null : () => _run(() async {
              if (_name.text.trim().isEmpty) { throw StateError('name'); }
              final draft = await ref.read(mfaRepositoryProvider).enroll(_name.text, _password.text);
              if (_same) { setState(() { _draft = draft; _showSecret = false; }); }
            }), child: Text(l.mfaAdd)),
          ],
          const Divider(), Text(l.mfaRecoveryHelp),
          if (_data!['owner'] == true) ...[
            const Divider(), Text(l.securityEnableHelp),
            Text('${l.securityReadyReviewers}: ${_data!['ready_reviewers']} / 2'),
            Text(_data!['mfa_required'] == true ? l.securityEnabled : l.securitySetupPending),
            if (_data!['mfa_required'] != true) FilledButton(onPressed: !_busy && ready ? _enable : null, child: Text(l.securityEnable)),
          ],
        ],
      ]))));
  }
}
