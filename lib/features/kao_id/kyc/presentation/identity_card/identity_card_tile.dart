import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

final class IdentityCardTile extends StatelessWidget {
  const IdentityCardTile({
    super.key,
    required this.status,
    required this.expiryDate,
    required this.onTap,
  });

  final String status;
  final DateTime? expiryDate;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (status) {
      case 'verified':
        return Colors.green;

      case 'pending':
        return Colors.orange;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  String _statusText(BuildContext context) {
    switch (status) {
      case 'verified':
        return AppLocalizations.of(context).kycVerifiedLabel;

      case 'pending':
        return AppLocalizations.of(context).kycUnderReview;

      case 'rejected':
        return AppLocalizations.of(context).kycRejectedLabel;

      default:
        return AppLocalizations.of(context).kycNotAdded;
    }
  }

  String get _expiryText {
    if (expiryDate == null) {
      return '';
    }

    return '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.badge_outlined,
        color: _statusColor,
      ),
      title:  Text(
        AppLocalizations.of(context).kycNationalIdCard,
      ),
      subtitle: expiryDate == null
          ? Text(_statusText(context))
          : Text(
              AppLocalizations.of(context).kycExpiresOnDate(_expiryText),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _statusText(context),
            style: TextStyle(
              color: _statusColor,
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