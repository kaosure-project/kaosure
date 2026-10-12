import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../kyc/presentation/screens/kyc_page.dart';
import 'quick_action_card.dart';

final class VerifyAction extends StatelessWidget {
  const VerifyAction({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return QuickActionCard(
      icon: Icons.verified_user_outlined,
      title: l10n.verifyIdentity,
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
