import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/dashboard_provider.dart';
import '../../../../account/presentation/pages/account_page.dart';
import 'quick_action_card.dart';

final class ProfileAction extends ConsumerWidget {
  const ProfileAction({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    return QuickActionCard(
      icon: Icons.person_outline,
      title: 'โปรไฟล์',
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AccountPage(),
          ),
        );

        if (!context.mounted) {
          return;
        }

        await ref
            .read(
              dashboardControllerProvider.notifier,
            )
            .loadDashboard();
      },
    );
  }
}