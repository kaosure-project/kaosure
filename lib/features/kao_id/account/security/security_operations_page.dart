import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../auth/application/providers/auth_provider.dart';

final securityOperationsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authProvider).asData?.value?.id;
  if (user == null) { throw StateError('session'); }
  final client = ref.watch(supabaseClientProvider);
  if (client.auth.currentUser?.id != user) { throw StateError('session'); }
  final data = await client.rpc('security_operations_r14a');
  if (client.auth.currentUser?.id != user) { throw StateError('session'); }
  return Map<String, dynamic>.from(data as Map);
});
class SecurityOperationsPage extends ConsumerWidget {
  const SecurityOperationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(securityOperationsProvider);
    return Scaffold(appBar: AppBar(title: Text(l.securityOperations)), body: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: ListView(padding: const EdgeInsets.all(24), children: [
        Text(l.securityOperationsHelp),
        OutlinedButton(onPressed: () => ref.invalidate(securityOperationsProvider), child: Text(l.authCheckAgain)),
        if (state.isLoading) const LinearProgressIndicator()
        else if (state.hasError) Text(l.kycLoadFailed)
        else if (state.asData != null) ...[
          for (final item in <String, String>{
            'pending_reviews': l.securityPendingReviews,
            'expired_reviews': l.securityExpiredReviews,
            'failed_email': l.securityFailedEmail,
            'stalled_email': l.securityStalledEmail,
            'pending_email': l.securityPendingEmail,
          }.entries) Card(child: ListTile(title: Text(item.value), trailing: Text('${state.asData!.value[item.key] ?? '—'}'))),
        ],
      ]))));
  }
}
