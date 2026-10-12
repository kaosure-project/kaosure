import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/features/kao_id/notifications/application/providers/notice_inbox_provider.dart';
import 'package:kaosure/features/kao_id/notifications/data/repositories/supabase_notice_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../auth/application/providers/auth_provider.dart';
import 'notice_target_page.dart';

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
