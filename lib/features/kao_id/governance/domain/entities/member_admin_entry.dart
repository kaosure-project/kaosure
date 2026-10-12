import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../application/providers/member_access_provider.dart';

class MemberAdminEntry extends ConsumerWidget {
  const MemberAdminEntry({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(memberAccessProvider).asData?.value == true;
    if (!allowed) { return const SizedBox.shrink(); }
    final l = AppLocalizations.of(context);
    return Card(child: ListTile(leading: const Icon(Icons.admin_panel_settings_outlined),
      title: Text(l.adminHubTitle), subtitle: Text(l.adminHubScope),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).pushNamed('/admin')));
  }
}
