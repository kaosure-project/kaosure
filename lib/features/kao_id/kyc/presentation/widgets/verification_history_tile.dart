import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

final class VerificationHistoryTile extends StatelessWidget {
  const VerificationHistoryTile({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.history,
      ),
      title:  Text(
        AppLocalizations.of(context).kycVerificationHistory,
      ),
      subtitle:  Text(
        AppLocalizations.of(context).kycReviewVerificationResultsAndChanges,
      ),
      trailing: const Icon(
        Icons.chevron_right,
      ),
      onTap: onTap,
    );
  }
}