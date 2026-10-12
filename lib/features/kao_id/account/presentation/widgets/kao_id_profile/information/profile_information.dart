import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../domain/entities/profile.dart';

final class ProfileInformation extends StatelessWidget {
  const ProfileInformation({super.key, required this.profile});

  final Profile profile;

  String _accountLevel(BuildContext context) {
    switch (profile.accountLevel) {
      case 'verified':
        return AppLocalizations.of(context).accountVerified;

      case 'business':
        return AppLocalizations.of(context).businessAccount;

      case 'organization':
        return AppLocalizations.of(context).organizationAccount;

      case 'registered':
        return AppLocalizations.of(context).accountRegistered;

      default:
        return AppLocalizations.of(context).accountStandard;
    }
  }

  Color get _badgeColor {
    switch (profile.accountLevel) {
      case 'verified':
        return Colors.green;

      case 'business':
        return Colors.blue;

      case 'organization':
        return Colors.deepPurple;

      case 'registered':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.displayName ?? AppLocalizations.of(context).displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Chip(
          avatar: Icon(Icons.verified, color: _badgeColor, size: 18),
          label: Text(_accountLevel(context)),
        ),
      ],
    );
  }
}
