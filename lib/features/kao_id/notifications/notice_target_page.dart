import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../auth/application/providers/auth_provider.dart';
import '../account/presentation/pages/security/mfa_page.dart';
import '../governance/shared/access_refresh.dart';
import '../kyc/review/kyc_review_page.dart';

abstract interface class NoticeTargetRepository {
  Future<Map<String, dynamic>> open(String id);
}
final noticeTargetRepositoryProvider = Provider<NoticeTargetRepository>((ref) => _TargetRepository(ref));
class _TargetRepository implements NoticeTargetRepository {
  _TargetRepository(this.ref);
  final Ref ref;
  @override
  Future<Map<String, dynamic>> open(String id) async {
    final client = ref.read(supabaseClientProvider);
    final owner = client.auth.currentUser?.id;
    if (owner == null) { throw StateError('session'); }
    final data = await client.rpc('kaoid_notice_target_r14b', params: {'p_notice': id});
    if (client.auth.currentUser?.id != owner) { throw StateError('session'); }
    return Map<String, dynamic>.from(data as Map);
  }
}
class NoticeTargetPage extends ConsumerStatefulWidget {
  const NoticeTargetPage({super.key, required this.noticeId});
  final String noticeId;
  @override
  ConsumerState<NoticeTargetPage> createState() => _NoticeTargetPageState();
}
class _NoticeTargetPageState extends ConsumerState<NoticeTargetPage>
    with WidgetsBindingObserver, AccessRefresh<NoticeTargetPage> {
  String? _owner;
  Map<String, dynamic>? _data;
  bool _busy = true;
  bool _failed = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(_load);
  }
  @override
  void refreshAccess() {
    // Review detail owns its live permission refresh; preserve the in-progress form.
    if (_data?['kind'] != 'review') { _load(); }
  }
  Future<void> _load() async {
    if (!mounted) { return; }
    final generation = ++_generation;
    setState(() { _busy = true; _data = null; _failed = false; });
    try {
      final value = await ref.read(noticeTargetRepositoryProvider).open(widget.noticeId);
      if (mounted && generation == _generation) { setState(() => _data = value); }
    } catch (_) {
      if (mounted && generation == _generation) { setState(() => _failed = true); }
    } finally {
      if (mounted && generation == _generation) { setState(() => _busy = false); }
    }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_owner == null || ref.watch(authProvider).asData?.value?.id != _owner) {
      return Scaffold(appBar: AppBar(title: Text(l.noticeTitle)), body: Center(child: Text(l.contactSessionChanged)));
    }
    if (!_busy && !_failed && _data?['kind'] == 'review' && _data?['row'] is Map) {
      return KycReviewDetailPage(row: Map<String, dynamic>.from(_data!['row'] as Map));
    }
    final status = _data?['status'];
    final statusLabel = switch (status) {
      'approved' => l.kycApproved,
      'rejected' => l.kycRejected,
      'pending' || 'under_review' => l.kycPendingStatus,
      _ => l.kycUnknownStatus,
    };
    return Scaffold(appBar: AppBar(title: Text(l.noticeTitle)), body: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: ListView(
        padding: const EdgeInsets.all(24), shrinkWrap: true, children: [
          if (_busy) const LinearProgressIndicator()
          else if (_failed) ...[
            Text(l.noticeAccessFailed),
            TextButton(onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MfaPage()));
              if (mounted) { await _load(); }
            }, child: Text(l.twoFactorAuthentication)),
          ] else if (_data?['kind'] == 'result') ...[
            Text(l.noticeCurrentStatus, style: Theme.of(context).textTheme.titleLarge),
            Text(statusLabel),
            if ((_data?['reason'] as String? ?? '').trim().isNotEmpty) SelectableText(_data!['reason'] as String),
          ] else if (_data?['kind'] == 'role') ...[
            Text(l.noticeCurrentStatus, style: Theme.of(context).textTheme.titleLarge),
            Text(_data?['active'] == true ? l.noticeRoleAssigned : l.noticeRoleRevoked),
          ] else Text(l.noticeTargetUnavailable),
          if (!_busy) TextButton(onPressed: _load, child: Text(l.authCheckAgain)),
        ],
      )),
    ));
  }
}
