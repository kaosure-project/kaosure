import 'package:flutter/material.dart';

import '../../../../account/domain/entities/profile.dart';
import 'kao_code_action.dart';
import 'kaopay_action.dart';
import 'profile_action.dart';
import 'verify_action.dart';

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
          'เมนูลัด',
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
          children: const [
            ProfileAction(),
            VerifyAction(),
            KaoPayAction(),
            KaoCodeAction(),
          ],
        ),
      ],
    );
  }
}