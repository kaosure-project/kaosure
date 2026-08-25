import 'package:flutter/material.dart';

import '../../../../kyc/presentation/screens/kyc_page.dart';
import 'quick_action_card.dart';

final class VerifyAction extends StatelessWidget {
  const VerifyAction({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return QuickActionCard(
      icon: Icons.verified_user_outlined,
      title: 'ยืนยันตัวตน',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const KycPage(),
          ),
        );
      },
    );
  }
}