import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'quick_action_card.dart';

final class KaoCodeAction extends StatelessWidget {
  const KaoCodeAction({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return QuickActionCard(
      enabled: false,
      subtitle: l10n.serviceUnavailable,
      icon: Icons.qr_code_scanner,
      title: l10n.kaoCode,
      onTap: () {
        // TODO: Navigate to Kao Code Screen
      },
    );
  }
}
