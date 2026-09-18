import 'package:flutter/material.dart';

import 'quick_action_card.dart';

final class KaoCodeAction extends StatelessWidget {
  const KaoCodeAction({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return QuickActionCard(
      icon: Icons.qr_code_scanner,
      title: 'Kao Code',
      onTap: () {
        // TODO: Navigate to Kao Code Screen
      },
    );
  }
}