import 'notice_target_page.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../auth/application/providers/auth_provider.dart';

abstract interface class NoticeRepository {
  Future<Map<String, dynamic>> inbox();
  Future<void> read(String id);
}
final noticeRepositoryProvider = Provider<NoticeRepository>((ref) => _Notices(ref.watch(supabaseClientProvider)));
class _Notices implements NoticeRepository {
  _Notices(this.client);
  final SupabaseClient client;
  Future<dynamic> call(String name, [Map<String, dynamic>? params]) async {
    final id = client.auth.currentUser?.id;
    if (id == null) { throw StateError('session'); }
    final result = await client.rpc(name, params: params);
    if (id != client.auth.currentUser?.id) { throw StateError('session'); }
    return result;
  }
  @override
  Future<Map<String, dynamic>> inbox() async => Map<String, dynamic>.from(await call('kaoid_inbox_r10a') as Map);
  @override
  Future<void> read(String id) async { await call('kaoid_read_notice_r10a', {'p_id': id}); }
}
final noticeInboxProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final id = ref.watch(authProvider.select((s) => s.asData?.value?.id));
  if (id == null) { return {'unread': 0, 'items': []}; }
  return ref.watch(noticeRepositoryProvider).inbox();
});
String noticeLabel(AppLocalizations l, String code) => switch(code) {
  'review_new' => l.noticeReviewNew,
  'review_second' => l.noticeReviewSecond,
  'review_restart' => l.noticeReviewRestart,
  'role_assigned' => l.noticeRoleAssigned,
  'role_revoked' => l.noticeRoleRevoked,
  'security_policy_enabled' || 'security_factor_added' || 'security_factor_removed' => l.securityNotice,
  'lifecycle_requested' => l.lifePending,
  'lifecycle_rejected' => l.lifeRejected,
  'account_closed' => l.closeAccountTitle,
  'account_recovered' => l.recoveryRestored,
  'kyc_revoked' => l.documentRevoked,
  'kyc_expired' => l.kycExpiredStatus,
  'kyc_expiring' => l.documentExpiring,
  'submitted' => l.noticeSubmitted,
  'approved' => l.noticeApproved,
  'rejected' => l.noticeRejected,
  'bank_approved' => l.noticeBankApproved,
  'bank_rejected' => l.noticeBankRejected,
  'suspended' => l.noticeSuspended,
  'restored' => l.noticeRestored,
  _ => l.noticeUpdated,
};
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});
  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}
class _NotificationBellState extends ConsumerState<NotificationBell> with WidgetsBindingObserver {
  Timer? _timer;
  @override
  void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) { ref.invalidate(noticeInboxProvider); }
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { ref.invalidate(noticeInboxProvider); }
  }
  @override
  void dispose() { _timer?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(noticeInboxProvider);
    final count = state.asData?.value['unread'] ?? 0;
    return OutlinedButton.icon(icon: const Icon(Icons.notifications_outlined),
      label: Text('${l.noticeTitle}${state.hasError ? ' · !' : count == 0 ? '' : ' ($count)'}'),
      onPressed: () async {
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationCenter()));
        if (mounted) { ref.invalidate(noticeInboxProvider); }
      });
  }
}
class NotificationCenter extends ConsumerWidget {
  const NotificationCenter({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).asData?.value?.id;
    final state = ref.watch(noticeInboxProvider);
    return Scaffold(appBar: AppBar(title: Text(l.noticeTitle)), body: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
        child: user == null ? Text(l.contactSessionChanged) : state.when(
          loading: () => const CircularProgressIndicator(),
          error: (_, _) => Column(mainAxisSize: MainAxisSize.min, children: [Text(l.kycLoadFailed),
            TextButton(onPressed: () => ref.invalidate(noticeInboxProvider), child: Text(l.retry))]),
          data: (data) {
            final rows = (data['items'] as List? ?? []).cast<Map>();
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text(l.noticeHelp),
              TextButton(onPressed: () => ref.invalidate(noticeInboxProvider), child: Text(l.authCheckAgain)),
              if (rows.isEmpty) Text(l.noticeEmpty),
              for (final row in rows) Card(child: ListTile(
                leading: Icon(row['is_read'] == true ? Icons.drafts_outlined : Icons.mark_email_unread_outlined),
                title: Text(noticeLabel(l, row['message'] as String? ?? '')),
                subtitle: Text(() {
                  final date = DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
                  return date == null ? '' : '${MaterialLocalizations.of(context).formatMediumDate(date)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
                }()),
                trailing: const {'review_new', 'review_second', 'review_restart', 'role_assigned', 'role_revoked', 'submitted', 'approved', 'rejected', 'bank_approved', 'bank_rejected'}.contains(row['message'])
                    ? IconButton(tooltip: l.noticeOpenItem, icon: const Icon(Icons.open_in_new), onPressed: () async {
                        try {
                          await ref.read(noticeRepositoryProvider).read(row['id'] as String);
                          ref.invalidate(noticeInboxProvider);
                          if (!context.mounted) { return; }
                          await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NoticeTargetPage(noticeId: row['id'] as String)));
                          if (context.mounted) { ref.invalidate(noticeInboxProvider); }
                        } catch (_) {
                          if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.kycLoadFailed))); }
                        }
                      }) : null,
                onTap: () async {
                  try {
                    await ref.read(noticeRepositoryProvider).read(row['id'] as String);
                    ref.invalidate(noticeInboxProvider);
                  } catch (_) {
                    if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.kycLoadFailed))); }
                  }
                },
              )),
            ]);
          },
        ))));
  }
}
