import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../account/data/repositories/supabase_account_access_repository.dart';
import '../../governance/presentation/widgets/admin_display.dart';
import '../presentation/widgets/kyc_status_label.dart';
import '../presentation/identity_card/identity_card_page.dart';
import '../presentation/passport/passport_page.dart';
import '../presentation/screens/residence_permit_page.dart';

abstract class DocumentHealthRepository {
  Future<Map<String, dynamic>> load(String? profile);
  Future<void> revoke(String document, String reason);
}
final documentHealthRepositoryProvider = Provider<DocumentHealthRepository>((ref) => _DocumentHealthRepository(ref));
class _DocumentHealthRepository implements DocumentHealthRepository {
  _DocumentHealthRepository(this.ref);
  final Ref ref;
  @override
  Future<Map<String, dynamic>> load(String? profile) async => Map<String, dynamic>.from(
    await ref.read(supabaseClientProvider).rpc('document_health_r11a', params: {'p_profile': profile}) as Map);
  @override
  Future<void> revoke(String document, String reason) async {
    await ref.read(supabaseClientProvider).rpc('revoke_document_r11a', params: {'p_document': document, 'p_reason': reason});
  }
}
class DocumentHealthPage extends ConsumerStatefulWidget {
  const DocumentHealthPage({super.key, this.profile});
  final String? profile;
  @override
  ConsumerState<DocumentHealthPage> createState() => _DocumentHealthPageState();
}
class _DocumentHealthPageState extends ConsumerState<DocumentHealthPage> {
  Map<String, dynamic>? _data;
  bool _busy = true, _failed = false;
  String? _user;
  StreamSubscription<void>? _subscription;
  bool get _same => _user != null && _user == ref.read(accountAccessRepositoryProvider).userId;
  @override
  void initState() {
    super.initState(); _user = ref.read(accountAccessRepositoryProvider).userId;
    _subscription = ref.read(accountAccessRepositoryProvider).changes.listen((_) {
      if (mounted && !_same) { setState(() { _data = null; _busy = false; }); }
    });
    unawaited(_load());
  }
  Future<void> _load() async {
    if (!_same) { if (mounted) { setState(() => _busy = false); } return; }
    setState(() { _busy = true; _failed = false; _data = null; });
    try {
      final result = await ref.read(documentHealthRepositoryProvider).load(widget.profile);
      if (mounted && _same) { setState(() => _data = result); }
    } catch (_) {
      if (mounted && _same) { setState(() => _failed = true); }
    } finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _revoke(Map row) async {
    final l = AppLocalizations.of(context);
    var input = ''; 
    final reason = await showDialog<String>(context: context, builder: (c) => StatefulBuilder(
      builder: (c, update) => AlertDialog(title: Text(l.documentRevoke), content: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min, children: [Text(l.documentRevokeHelp),
          TextField(maxLength: 1000, onChanged: (value) => update(() => input = value),
            decoration: InputDecoration(labelText: l.reviewReason))])), actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          FilledButton(onPressed: input.trim().length < 3 ? null : () => Navigator.pop(c, input.trim()),
            child: Text(l.continueLabel)),
        ])));
    if (!mounted || !_same || reason == null) { return; }
    setState(() => _busy = true);
    try {
      await ref.read(documentHealthRepositoryProvider).revoke(row['id'] as String, reason);
      if (mounted && _same) { await _load(); }
    } catch (_) { if (mounted && _same) { setState(() { _busy = false; _failed = true; _data = null; }); } }
  }
  Future<void> _renew(String type) async {
    final Widget page = switch(type) {
      'thai_national_id' => const IdentityCardPage(),
      'passport' => const PassportPage(),
      _ => const ResidencePermitPage(),
    };
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted && _same) { await _load(); }
  }
  @override
  void dispose() { _subscription?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = (_data?['documents'] as List? ?? []).cast<Map>();
    final history = (_data?['history'] as List? ?? []).cast<Map>();
    String type(String value) => switch(value) {
      'thai_national_id' => l.kycIdCardTitle,
      'passport' => l.kycPassportTitle,
      'residence_card' => l.kycResidenceTitle,
      _ => value,
    };
    return Scaffold(appBar: AppBar(title: Text(l.documentHealthTitle)), body: SafeArea(child: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: ListView(
        padding: const EdgeInsets.all(20), children: [
          Text(l.documentHealthHelp), const SizedBox(height: 16),
          if (!_same) Text(l.contactSessionChanged)
          else if (_busy) const LinearProgressIndicator()
          else if (_failed) ...[Text(l.kycLoadFailed), OutlinedButton(onPressed: _load, child: Text(l.retry))]
          else ...[
            OutlinedButton(onPressed: _load, child: Text(l.authCheckAgain)),
            if (rows.isEmpty) Text(l.adminSearchEmpty),
            for (final row in rows) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(type(row['document_type'] as String), style: Theme.of(context).textTheme.titleMedium),
                Text(kycStatusLabel(l, row['status'] as String?)),
                Text('${l.kycExpiryDate}: ${realValue(row['expiry_date'])}'),
                if (row['rejected_reason'] != null) Text(realValue(row['rejected_reason'])),
                if (widget.profile != null && widget.profile != _user && ['approved', 'expired'].contains(row['status']))
                  OutlinedButton(onPressed: () => _revoke(row), child: Text(l.documentRevoke)),
                if (widget.profile == null && ['thai_national_id', 'passport', 'residence_card'].contains(row['document_type']))
                  OutlinedButton(onPressed: () => _renew(row['document_type'] as String), child: Text(l.documentRenew)),
              ]))),
            const SizedBox(height: 20), Text(l.documentHistory, style: Theme.of(context).textTheme.titleMedium),
            for (final item in history) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(item['action'] == 'kyc.expire' ? l.kycExpiredStatus : l.documentRevoked),
                Text(adminDate(context, item['created_at'])),
                Text(item['actor_id'] == null ? l.documentSystem : '${realValue(item['actor_name_at_event'])} · ${realValue(item['actor_code'] ?? item['actor_id'])}'),
                if (item['actor_id'] != null) Text((item['actor_roles_at_event'] as List?)?.map((r) => r == 'owner' ? 'Owner' : realValue(r)).join(', ') ?? '—'),
                if (_reason(item['description']).isNotEmpty) Text(_reason(item['description'])),
              ]))),
          ],
        ])))));
  }
  String _reason(dynamic value) {
    try { final data = jsonDecode(value?.toString() ?? ''); return data is Map ? data['reason']?.toString() ?? '' : ''; }
    catch (_) { return ''; }
  }
}
