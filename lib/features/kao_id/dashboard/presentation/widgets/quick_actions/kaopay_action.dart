import 'package:flutter/material.dart';

import 'quick_action_card.dart';

final class KaoPayAction extends StatelessWidget {
  const KaoPayAction({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return QuickActionCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'KaoPay',
      onTap: () {
        // TODO: Navigate to KaoPay Screen
      },
    );
  }
}