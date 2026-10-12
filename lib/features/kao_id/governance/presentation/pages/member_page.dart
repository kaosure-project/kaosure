import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/features/wallet/linked_wallets_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../kyc/maintenance/document_health_page.dart';
import '../../../kyc/presentation/widgets/kyc_status_label.dart';
import '../../application/providers/member_access_provider.dart';
import '../../application/services/access_refresh.dart';
import '../../data/repositories/supabase_member_repository.dart';
import '../widgets/admin_display.dart';
import 'account_state_page.dart';

class MemberPage extends ConsumerStatefulWidget {
  const MemberPage({super.key});
  @override
  ConsumerState<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends ConsumerState<MemberPage> with WidgetsBindingObserver, AccessRefresh<MemberPage> {
  @override
  void refreshAccess() {
    ref.invalidate(memberAccessProvider);
  }
  final _query = TextEditingController();
  String? _owner;
  Map<String, dynamic>? _row;
  bool _busy = false, _searched = false, _failed = false;
  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(() { if (mounted) { ref.invalidate(memberAccessProvider); } });
  }
  @override
  void dispose() { _query.dispose(); super.dispose(); }
  Future<void> _search() async {
    final query = _query.text.trim();
    if (_busy || query.length < 3) { return; }
    setState(() { _busy = true; _row = null; _searched = false; _failed = false; });
    try {
      final row = await ref.read(memberRepositoryProvider).find(query);
      if (mounted && ref.read(authProvider).asData?.value?.id == _owner) {
        setState(() { _row = row; _searched = true; });
      }
    } catch (_) {
      if (mounted) { setState(() { _failed = true; _row = null; }); }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).asData?.value?.id;
    final access = ref.watch(memberAccessProvider);
    final session = _owner != null && user == _owner;
    String flag(dynamic value) => value == true ? l.kycVerifiedStatus : value == false ? l.kycUnverifiedStatus : l.kycUnknownStatus;
    String status(dynamic value) => switch(value) {
      'active' => l.adminActive,
      'suspended' || 'temporarily_locked' => l.adminSuspended,
      'closed' => l.adminClosed,
      _ => l.kycUnknownStatus,
    };
    Widget field(String title, String value) => AdminValue(label: title, value: value, copyable: title == l.adminUserId || title == l.kaoId || title == l.adminAccountCode);
    Widget body;
    if (!session) {
      body = Text(l.contactSessionChanged);
    } else if (access.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (access.hasError) {
      body = Column(mainAxisSize: MainAxisSize.min, children: [Text(l.kycLoadFailed),
        OutlinedButton(onPressed: () => ref.invalidate(memberAccessProvider), child: Text(l.retry))]);
    } else if (access.asData?.value != true) {
      body = Text(l.adminAccessDenied);
    } else {
      final row = _row;
      body = ListView(padding: const EdgeInsets.all(20), children: [
        OutlinedButton.icon(onPressed: () => Navigator.of(context).pushNamed('/admin'),
          icon: const Icon(Icons.admin_panel_settings_outlined), label: Text(l.adminHubTitle)),
        OutlinedButton.icon(onPressed: () => Navigator.of(context).pushNamed('/admin/staff'),
          icon: const Icon(Icons.manage_accounts), label: Text(l.staffTitle)),
        Text(l.adminReadOnly), const SizedBox(height: 20),
        TextField(controller: _query, enabled: !_busy, maxLength: 254,
          onChanged: (_) => setState(() {}), onSubmitted: (_) => _search(),
          decoration: InputDecoration(labelText: '${l.adminSearchHint} / ${l.adminAccountCode}', border: const OutlineInputBorder())),
        FilledButton(onPressed: !_busy && _query.text.trim().length >= 3 ? _search : null,
          child: Text(l.adminSearch)),
        if (_busy) const LinearProgressIndicator(),
        if (_failed) Text(l.kycLoadFailed),
        if (_searched && row == null) Text(l.adminSearchEmpty),
        if (row != null) Card(child: Padding(padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            field(l.adminAccountCode, realValue(row['account_code'])),
            field(l.adminUserId, row['id'] as String),
            OutlinedButton(onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AccountStatePage(target: row['id'] as String, initialStatus: row['account_status'] as String? ?? '')));
              if (mounted && ref.read(authProvider).asData?.value?.id == _owner) { await _search(); }
            }, child: Text(l.accountStateTitle)),
            OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LinkedWalletsPage(profile: row['id'] as String))), child: Text(l.linkedWalletTitle)),
            OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DocumentHealthPage(profile: row['id'] as String))), child: Text(l.documentHealthTitle)),
            field(l.displayName, row['display_name'] as String? ?? '—'),
            field(l.adminAccountState, status(row['account_status'])),
            field(l.kycEmailTitle, '${row['email'] ?? '—'} · ${flag(row['email_verified'])}'),
            field(l.kycPhoneTitle, '${row['phone'] ?? '—'} · ${flag(row['phone_verified'])}'),
            field(l.identityVerification, kycStatusLabel(l, row['kyc_status'] as String?)),
            field(l.kaoId, row['kao_id'] as String? ?? l.adminNotIssued),
            if (row['kao_id'] != null) field(l.adminIdentityState, status(row['identity_status'])),
          ]))),
      ]);
    }
    return Scaffold(appBar: AppBar(title: Text(l.adminMembersTitle)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800), child: body))));
  }
}
