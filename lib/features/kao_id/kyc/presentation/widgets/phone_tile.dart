import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

final class PhoneTile extends StatelessWidget {
  const PhoneTile({
    super.key,
    required this.phoneNumber,
    required this.isVerified,
    required this.onTap,
  });

  final String phoneNumber;
  final bool isVerified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.phone_outlined,
        color: isVerified
            ? Colors.green
            : Colors.orange,
      ),
      title:  Text(
        AppLocalizations.of(context).kycPhoneNumber,
      ),
      subtitle: Text(
        phoneNumber,
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