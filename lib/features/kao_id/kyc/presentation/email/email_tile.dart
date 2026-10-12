import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

final class EmailTile extends StatelessWidget {
  const EmailTile({
    super.key,
    required this.email,
    required this.isVerified,
    required this.onTap,
  });

  final String email;
  final bool isVerified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.email_outlined,
        color: isVerified
            ? Colors.green
            : Colors.orange,
      ),
      title:  Text(
        AppLocalizations.of(context).kycEmail,
      ),
      subtitle: Text(
        email,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isVerified
                ? AppLocalizations.of(context).kycVerified
                : AppLocalizations.of(context).kycNotVerifiedLabelText,
            style: TextStyle(
              color: isVerified
                  ? Colors.green
                  : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}