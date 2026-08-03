import 'package:flutter/material.dart';

import '../../account/domain/entities/profile.dart';
import '../../account/presentation/screens/account_screen.dart';
import 'quick_action_card.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            QuickActionCard(
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountScreen(),
                  ),
                );
              },
            ),
            QuickActionCard(
              icon: Icons.verified_user_outlined,
              title: 'Verify',
              onTap: () {
                // TODO: Navigate to Verify Screen
              },
            ),
            QuickActionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'KaoPay',
              onTap: () {
                // TODO: Navigate to KaoPay Screen
              },
            ),
            QuickActionCard(
              icon: Icons.qr_code_scanner,
              title: 'Kao Code',
              onTap: () {
                // TODO: Navigate to Kao Code Screen
              },
            ),
          ],
        ),
      ],
    );
  }
}